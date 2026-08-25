"""tsend -- send files to a tailnet peer over Taildrop.

`tailscale file cp` takes files only. It rejects directories outright, has no
store-and-forward for offline peers, and cannot target tagged nodes (Taildrop
is same-user only). This wraps it with directory expansion, an fzf device
picker, and the guards those three limits imply.

    tsend FILE...            send files; pick the device with fzf
    tsend DIR                send the files directly inside DIR
    tsend --tar DIR          send DIR as one .tar.gz, structure preserved
    tsend                    pick files from the current directory, then a peer
    tsend -t NAME FILE...    skip the picker

A directory contributes only the files directly inside it, dotfiles included.
Nested subdirectories are reported and skipped: flattening them would let two
same-named files from different subdirectories collide silently, so --tar is
the answer when structure matters.

`tailscale` is resolved from PATH rather than a pinned closure on purpose. The
CLI has to match the tailscaled the system planted, and that version is chosen
by system config this package cannot read; a second pinned copy would invite a
skew that stays invisible until it breaks.

The daemon's cached reachability lags -- a phone that just woke can still be
reported offline for minutes -- so a peer reported offline gets a live probe
before the guard fires, rather than being taken at its word.

Receiving depends on the peer. GUI clients (Android, Windows, the macOS app)
auto-accept into Downloads; a peer running the open-source tailscaled leaves
files in a daemon inbox until someone runs `tailscale file get DIR`.
"""

import argparse
import shutil
import signal
import subprocess
import sys
import tarfile
import tempfile
from pathlib import Path

# `tailscale file cp --targets` prints one peer per line as "IP\tNAME\tSTATUS".
# STATUS is absent or empty while a peer is online and begins with "offline"
# otherwise. Tagged nodes never appear in this list at all.
NAME_FIELD = 1
STATUS_FIELD = 2

# Seconds to wait for a liveness probe before believing "offline". One DERP
# round trip is well under this; a dead peer costs the full timeout, and only
# on a path that used to be a hard stop.
PROBE_TIMEOUT = 3


def die(*lines):
    for line in lines:
        print(f"tsend: {line}", file=sys.stderr)
    sys.exit(1)


def tailscale(*args):
    """Run a tailscale subcommand, returning its stdout."""
    proc = subprocess.run(
        ["tailscale", *args], text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    if proc.returncode != 0:
        die(f"`tailscale {' '.join(args)}` failed", proc.stderr.strip())
    return proc.stdout


def targets():
    """Eligible Taildrop peers as (name, status) pairs, in daemon order."""
    peers = []
    for line in tailscale("file", "cp", "--targets").splitlines():
        fields = line.split("\t")
        if len(fields) <= NAME_FIELD:
            continue
        status = fields[STATUS_FIELD] if len(fields) > STATUS_FIELD else ""
        peers.append((fields[NAME_FIELD], status))
    return peers


def fzf(lines, prompt, multi=False):
    """Prompt with fzf and return the selected lines."""
    argv = ["fzf", "--prompt", prompt, "--reverse", "--height", "40%"]
    if multi:
        argv += [
            "--multi",
            "--bind",
            "ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all",
            "--header",
            "TAB mark   ctrl-a all   ctrl-d none",
        ]
    # fzf draws its UI on /dev/tty, so capturing stdout does not disturb it.
    proc = subprocess.run(
        argv, input="\n".join(lines), text=True, stdout=subprocess.PIPE
    )
    if proc.returncode != 0:
        # 130 is a deliberate ctrl-c or esc; anything else is fzf failing.
        sys.exit(proc.returncode)
    return [line for line in proc.stdout.splitlines() if line]


def pick_files():
    """fzf multi-select over the files in the current directory."""
    if not sys.stdin.isatty():
        die("no terminal for the file picker; pass paths as arguments instead")
    names = sorted(entry.name for entry in Path.cwd().iterdir() if entry.is_file())
    if not names:
        die("no files in the current directory")
    return [Path(name) for name in fzf(names, "files > ", multi=True)]


def pick_target(peers):
    """fzf over eligible peers, annotated with their reachability."""
    if not sys.stdin.isatty():
        die("no terminal for the device picker; pass --target NAME instead")
    width = max(len(name) for name, _ in peers)
    labels = [f"{name.ljust(width)}   {status or 'online'}" for name, status in peers]
    return peers[labels.index(fzf(labels, "target > ")[0])]


def archive(directory, tmpdir):
    """Tar a directory into tmpdir, returning the archive path."""
    # "." and ".." have no useful basename, so resolve before naming.
    resolved = directory.resolve()
    dest = Path(tmpdir) / f"{resolved.name}.tar.gz"
    with tarfile.open(dest, "w:gz") as tar:
        tar.add(resolved, arcname=resolved.name)
    return dest


def collect(paths, use_tar, tmpdir):
    """Resolve arguments to a file list, plus the subdirectories skipped."""
    files, skipped = [], []
    for raw in paths:
        path = Path(raw)
        if not path.exists():
            die(f"no such path: {path}")
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            if use_tar:
                files.append(archive(path, tmpdir))
            else:
                # iterdir() includes dotfiles, unlike a shell glob.
                for entry in sorted(path.iterdir()):
                    if entry.is_file():
                        files.append(entry)
                    elif entry.is_dir():
                        skipped.append(entry)
        else:
            die(f"neither a file nor a directory: {path}")
    return files, skipped


def human(size):
    """A byte count as a short human-readable string."""
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if size < 1024 or unit == "TiB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024


def report_skipped(skipped):
    if not skipped:
        return
    noun = "subdirectory" if len(skipped) == 1 else "subdirectories"
    print(
        f"tsend: skipped {len(skipped)} {noun} (use --tar to include them):",
        file=sys.stderr,
    )
    for entry in skipped:
        print(f"    {entry.name}/", file=sys.stderr)


def reachable(target):
    """Probe a peer directly, because the daemon's cached status lags.

    `tailscale ping` exits 1 whether or not the peer answers -- with
    --until-direct defaulting true, a DERP-only pong is a failure by its own
    measure -- so the reply text is the only usable signal.
    """
    proc = subprocess.run(
        ["tailscale", "ping", "--c", "1", "--timeout", f"{PROBE_TIMEOUT}s", target],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    return "pong from" in proc.stdout


def confirm_offline(target, status, force):
    """Taildrop cannot queue, so an unreachable peer is a wasted transfer."""
    if force or not status.startswith("offline"):
        return
    if reachable(target):
        print(
            f"tsend: {target} answered a probe; the daemon reported it {status}",
            file=sys.stderr,
        )
        return
    warning = f"could not reach {target} ({status}); Taildrop has no store-and-forward"
    if not sys.stdin.isatty():
        die(warning, "pass --force to send anyway")
    print(f"tsend: warning: {warning}", file=sys.stderr)
    if input("send anyway? [y/N] ").strip().lower() not in ("y", "yes"):
        die("aborted")


def show_plan(files, target, dry_run):
    total = sum(path.stat().st_size for path in files)
    noun = "file" if len(files) == 1 else "files"
    verb = "would send" if dry_run else "sending"
    print(f"{verb} {len(files)} {noun} ({human(total)}) -> {target}")
    for path in files:
        print(f"    {path.name}")


def resolve_target(peers, requested):
    """Validate --target against the daemon rather than trusting it."""
    known = dict(peers)
    if requested not in known:
        die(
            f"{requested!r} is not an eligible Taildrop target",
            f"eligible: {', '.join(name for name, _ in peers)}",
            "tagged nodes never appear: Taildrop is same-user only",
        )
    return requested, known[requested]


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="tsend",
        description="Send files to a tailnet peer over Taildrop.",
    )
    parser.add_argument(
        "paths",
        nargs="*",
        metavar="PATH",
        help="files, or directories whose top-level files are sent; "
        "omit to pick interactively",
    )
    parser.add_argument(
        "-t", "--target", metavar="NAME", help="peer to send to; skips the fzf picker"
    )
    parser.add_argument(
        "--tar",
        action="store_true",
        help="send each directory as one .tar.gz instead of its files",
    )
    parser.add_argument(
        "-n",
        "--dry-run",
        action="store_true",
        help="print what would be sent, transfer nothing",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="send even when the peer is reported offline",
    )
    return parser.parse_args(argv)


def main():
    # Don't traceback when stdout is closed early (e.g. piped to `head`).
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    args = parse_args(sys.argv[1:])
    if shutil.which("tailscale") is None:
        die("`tailscale` is not on PATH")

    with tempfile.TemporaryDirectory(prefix="tsend-") as tmpdir:
        if args.paths:
            files, skipped = collect(args.paths, args.tar, tmpdir)
        else:
            files, skipped = pick_files(), []
        report_skipped(skipped)
        if not files:
            die("nothing to send")

        peers = targets()
        if not peers:
            die(
                "no eligible Taildrop peers",
                "tagged nodes cannot receive: Taildrop is same-user only",
            )
        target, status = (
            resolve_target(peers, args.target) if args.target else pick_target(peers)
        )

        confirm_offline(target, status, args.force)
        show_plan(files, target, args.dry_run)
        if args.dry_run:
            return 0

        argv = ["tailscale", "file", "cp", "--", *map(str, files), f"{target}:"]
        return subprocess.run(argv).returncode


if __name__ == "__main__":
    sys.exit(main())
