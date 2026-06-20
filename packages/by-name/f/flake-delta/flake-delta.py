"""flake-delta -- package-version delta between two flake.lock revisions.

Diffs every flake output (nixos + darwin configs, packages, devShells) from
EVALUATION only -- no build (it does NOT run dix/nvd; those need realized
builds). Because a .drv evaluates without being built, this also covers darwin
(sienna) on a Linux runner. Markdown to stdout; plain text when stdout is a TTY.

Positional args are flake.lock revisions to compare:
    (none)      BASE = git HEAD:flake.lock   PR = ./flake.lock
    BASE        BASE = arg                    PR = ./flake.lock
    BASE PR     both explicit

With --output, the structured delta is also written as JSON (a path, or an
auto name `flake-delta-<baserev>-<prrev>.json` derived from each lock's
nixpkgs rev). The human report still prints to stdout.

Local loop:
    cp flake.lock /tmp/base.lock
    nix flake update nixpkgs        # any inputs except hyprland
    flake-delta /tmp/base.lock
    git checkout flake.lock

Env: FLAKE_DELTA_FLAKE (default "."), FLAKE_DELTA_FORMAT (md | plain).
"""

import argparse
import hashlib
import json
import os
import re
import signal
import subprocess
import sys
import tempfile

FLAKE = os.environ.get("FLAKE_DELTA_FLAKE", ".")
ENV = {**os.environ, "NIX_CONFIG": "extra-experimental-features = nix-command flakes"}

# Sentinel: --output given with no path -> auto-name the JSON file.
AUTO = object()

# A store-path basename is build-time noise (not a runtime package) if it ends
# in one of these extensions or matches one of these name patterns.
NOISE_SUFFIX = re.compile(
    r"\.(patch|sh|diff|tar|tgz|zip|gz|xz|bz2|zst|json|toml|cfg|conf|nix|lock|service|mount)$"
)
NOISE_NAME = re.compile(
    r"^(bootstrap|stdenv|source|unpack|mirrors-list|builder|setup-hook|default-builder|env-vars)\b"
    r"|-(hook|wrapper-hook|stdenv|stdenv-linux|stdenv-darwin|bootstrap|env)(-[0-9.]+)?$"
)
# Split "<name>-<version>", version starting at the first digit-led component.
NAME_VERSION = re.compile(r"^(.*[A-Za-z])-([0-9].*)$")


def nix(*args):
    """Run a nix command with flakes enabled; return (rc, stdout)."""
    p = subprocess.run(args, env=ENV, text=True, capture_output=True, check=False)
    return p.returncode, p.stdout


def attrnames(attr):
    """Attr names under a flake output class; [] when the class is absent."""
    rc, out = nix("nix", "eval", "--json", f"{FLAKE}#{attr}", "--apply", "builtins.attrNames")
    return json.loads(out) if rc == 0 and out.strip() else []


def outputs():
    """Yield (label, attr) for every diffable output (attr without .drvPath)."""
    for host in attrnames("nixosConfigurations"):
        yield f"nixos:{host}", f"nixosConfigurations.{host}.config.system.build.toplevel"
    for host in attrnames("darwinConfigurations"):
        yield f"darwin:{host}", f"darwinConfigurations.{host}.system"
    for system in attrnames("packages"):
        for pkg in attrnames(f"packages.{system}"):
            yield f"pkg.{system}:{pkg}", f"packages.{system}.{pkg}"
    for system in attrnames("devShells"):
        for shell in attrnames(f"devShells.{system}"):
            yield f"shell.{system}:{shell}", f"devShells.{system}.{shell}"


def drvpath(attr, lock):
    """drvPath of `attr` evaluated against `lock` (no working-tree mutation)."""
    rc, out = nix(
        "nix", "eval", "--reference-lock-file", lock, "--no-write-lock-file",
        "--raw", f"{FLAKE}#{attr}.drvPath",
    )
    return out.strip() if rc == 0 else ""


def versions(drv):
    """Map name -> {versions} for runtime-ish entries in a .drv closure."""
    rc, out = nix("nix-store", "--query", "--requisites", drv)
    if rc != 0:
        return {}
    found = {}
    for path in out.splitlines():
        name = re.sub(r"^/nix/store/[a-z0-9]{32}-", "", path)
        name = re.sub(r"\.drv$", "", name)
        if NOISE_SUFFIX.search(name) or NOISE_NAME.search(name):
            continue
        match = NAME_VERSION.match(name)
        if match:
            found.setdefault(match.group(1), set()).add(match.group(2))
    return found


def changed_packages(base_drv, pr_drv):
    """List of {name, old, new} for packages whose version set changed.

    `old`/`new` are sorted version lists ([] means the package is absent on
    that side); renderers turn [] into "(absent)".
    """
    base, pr = versions(base_drv), versions(pr_drv)
    changes = []
    for name in sorted(base.keys() | pr.keys()):
        old = sorted(base.get(name, set()))
        new = sorted(pr.get(name, set()))
        if old != new:
            changes.append({"name": name, "old": old, "new": new})
    return changes


def compute(base_lock, pr_lock):
    """Build the structured delta report comparing two locks (eval only)."""
    outs = list(outputs())
    base = {label: drvpath(attr, base_lock) for label, attr in outs}
    pr = {label: drvpath(attr, pr_lock) for label, attr in outs}

    blocks = []
    for label, _ in outs:
        b, p = base[label], pr[label]
        if not b or not p or b == p:
            continue  # eval failed a side, or identical drv -> no change
        changes = changed_packages(b, p)
        if changes:
            blocks.append({"label": label, "changed": len(changes), "packages": changes})

    return {
        "base": {"lock": base_lock, "id": short_id(base_lock)},
        "pr": {"lock": pr_lock, "id": short_id(pr_lock)},
        "changed_outputs": len(blocks),
        "outputs": blocks,
    }


def short_id(lock_path):
    """A short identifier for a lock: its nixpkgs rev, else a content hash."""
    try:
        with open(lock_path) as fh:
            data = json.load(fh)
        nodes = data.get("nodes", {})
        ref = nodes.get("root", {}).get("inputs", {}).get("nixpkgs")
        if isinstance(ref, list):
            ref = ref[0] if ref else None
        rev = nodes.get(ref, {}).get("locked", {}).get("rev", "") if ref else ""
        if rev:
            return rev[:7]
        with open(lock_path, "rb") as fh:
            return hashlib.sha1(fh.read()).hexdigest()[:7]
    except (OSError, ValueError):
        return "unknown"


def _ver(values):
    """Render a sorted version list for humans: comma-joined, or (absent)."""
    return ",".join(values) or "(absent)"


def render_plain(report):
    lines = [f"flake-delta: {report['changed_outputs']} output(s) changed (eval-only)"]
    for block in report["outputs"]:
        lines.append(f"\n== {block['label']} ({block['changed']} changed) ==")
        for pkg in block["packages"]:
            lines.append(f"{pkg['name']}: {_ver(pkg['old'])} -> {_ver(pkg['new'])}")
    return "\n".join(lines)


def render_md(report):
    head = (
        "### Package version delta (eval-only, all outputs incl. darwin)\n\n"
        f"{report['changed_outputs']} output(s) changed. "
        "Build-time-closure approximation; no build."
    )
    parts = [head]
    for block in report["outputs"]:
        body = "\n".join(
            f"{pkg['name']}: {_ver(pkg['old'])} -> {_ver(pkg['new'])}"
            for pkg in block["packages"]
        )
        parts.append(
            f"<details><summary><code>{block['label']}</code> -- "
            f"{block['changed']} changed</summary>\n\n```\n{body}\n```\n\n</details>"
        )
    return "\n\n".join(parts)


def resolve_locks(locks, tmp):
    """Resolve (base_lock, pr_lock) from the positional lock args."""
    pr_lock = os.path.join(FLAKE, "flake.lock")
    if len(locks) >= 2:
        return locks[0], locks[1]
    if len(locks) == 1:
        return locks[0], pr_lock
    base_lock = os.path.join(tmp, "base.lock")
    with open(base_lock, "w") as fh:
        subprocess.run(
            ["git", "-C", FLAKE, "show", "HEAD:flake.lock"],
            stdout=fh, env=ENV, text=True, check=True,
        )
    return base_lock, pr_lock


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="flake-delta",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "locks", nargs="*", metavar="LOCK",
        help="0-2 flake.lock paths to compare (see description).",
    )
    parser.add_argument(
        "-o", "--output", nargs="?", const=AUTO, metavar="FILE",
        help="Also write the delta as JSON to FILE, or to an auto-named "
             "flake-delta-<baserev>-<prrev>.json when no path is given.",
    )
    args = parser.parse_args(argv)
    if len(args.locks) > 2:
        parser.error("expected at most 2 lock paths")
    return args


def main():
    # Don't traceback when stdout is closed early (e.g. piped to `head`).
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    args = parse_args(sys.argv[1:])
    tmp = tempfile.mkdtemp()
    base_lock, pr_lock = resolve_locks(args.locks, tmp)

    report = compute(base_lock, pr_lock)

    if args.output is not None:
        path = args.output
        if path is AUTO:
            path = f"flake-delta-{report['base']['id']}-{report['pr']['id']}.json"
        with open(path, "w") as fh:
            json.dump(report, fh, indent=2)
            fh.write("\n")
        print(f"flake-delta: wrote {path}", file=sys.stderr)

    fmt = os.environ.get("FLAKE_DELTA_FORMAT") or ("plain" if sys.stdout.isatty() else "md")
    print(render_plain(report) if fmt == "plain" else render_md(report))


if __name__ == "__main__":
    main()
