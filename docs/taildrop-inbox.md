# Taildrop inbox (rue)

Drop files onto rue from any device on the tailnet -- `tsend` on cimmerian
and t14g1, "Send with Tailscale" from the Android, Windows or macOS share
sheet -- and they land in `~/Inbox` on rue, owned by `jmfv`, with no manual
`tailscale file get`. rue is an inbox for later pickup, not a relay or a
service feed. Where this lives in the repo:

- `modules/services/taildrop-inbox/default.nix` -- the Aspect: the second
  tailscaled, the getter loop, the `tailscale-inbox` wrapper, and the five
  hard requirements with their source citations.
- `modules/services/taildrop-inbox/test.nix` -- the VM test, run on rue with
  `just taildrop-inbox-test`.
- `modules/hosts/rue/default.nix` and `modules/hosts/rue/_home.nix` -- rue
  turns the Aspect on and persists `~/Inbox`.
- `modules/services/tailscale/default.nix` -- the `operator` option that lets
  `tsend` run without sudo on cimmerian and t14g1.

## Why a second node

rue's own node is tagged `tag:server`, and Taildrop only moves files between
nodes owned by the same user. A tagged node belongs to its tag, not to a
user, so it never shows up as a target (Tailscale KB 1106: no Taildrop to or
from tagged nodes).

The client source does know a way around that -- the peer capabilities
`https://tailscale.com/cap/file-sharing-target` and
`https://tailscale.com/cap/file-send` -- but the admin console's policy
editor refuses both spellings in a grant:

- with the scheme: `capability name must have the form {domain}/{path}`
- without it: `capability name must not be in the tailscale.com domain`

Untagging rue is not an option either: its Funnel `nodeAttrs` grant targets
`tag:server`, and being tagged is what keeps its key from expiring.

So rue runs a second tailscaled next to the main one, in userspace-networking
mode, logged in interactively as you. That makes it an ordinary untagged,
user-owned node, `rue-inbox`, and a Taildrop target for every personal
device. A getter loop (`taildrop-inbox.service`) moves arrivals into
`~/Inbox`. The main node -- exit node, subnet router, Funnel, Tailscale SSH,
AdGuard DNS -- is untouched.

## Bootstrap (once)

1. Deploy rue with the Aspect enabled. `-t` gives sudo a terminal for its
   password prompt:

   ```bash
   ssh -t rue 'cd ~/nixos-dot && git pull && sudo nixos-rebuild switch --flake .#rue'
   ```

2. Log the inbox node in as `jmfv`. No sudo: the daemon runs as `jmfv`, and a
   caller with the daemon's own uid gets write access without `--operator`.

   ```bash
   ssh rue tailscale-inbox up --hostname=rue-inbox --shields-up
   ```

   Open the printed URL and log in with your own account -- not a tag, not an
   auth key. Keep `--shields-up` (see Constraints): this first `up` replaces
   the node's settings wholesale, so leaving it out would open the node until
   the daemon next restarts.

3. In the admin console, Machines -> `rue-inbox` -> Disable key expiry.
   Otherwise the node logs out when its key expires and files stop arriving
   until it is logged back in.

4. Rebuild cimmerian and t14g1 as well, each from its own checkout:

   ```bash
   sudo nixos-rebuild switch --flake .#<host>
   ```

   They get `tsend` and the operator setting only from their own rebuild.

5. Check it:

   ```bash
   ssh rue tailscale-inbox status
   ```

   It should list your devices, and `tsend`'s picker on cimmerian should
   offer `rue-inbox`.

The login lives in `/var/lib/tailscale-inbox`, which survives rue's root
wipe, so this is a one-time step unless the node is removed in the console.

## Sending

- **cimmerian, t14g1:** `tsend -t rue-inbox FILE...`, or plain `tsend` and
  pick `rue-inbox` in fzf. `tsend --tar DIR` sends a directory as one
  archive. No sudo needed: both hosts make you the daemon's operator.
- **Android, Windows, macOS:** share -> Tailscale -> `rue-inbox`.
- **Any other Linux CLI:** `tailscale file cp FILE rue-inbox:` -- needs root
  or operator rights, see Constraints.

## Picking files up

Files land in `/home/jmfv/Inbox` on rue -- a directory only `jmfv` can enter
(mode 0700) -- as files owned by `jmfv` with mode 0644, and survive reboots
until moved out. A name that is already taken gets renamed rather than
overwritten (`--conflict=rename`). Pull them off with anything that speaks
SSH:

```bash
rsync -av --remove-source-files rue:Inbox/ ~/Downloads/
```

A copy into `~/Inbox` that fails partway -- a full disk, or the daemon
restarting mid-copy -- leaves a truncated file under the real name. The
original stays waiting in `/var/lib/tailscale-inbox` and the getter retries,
so the complete copy lands under a numbered name such as `name (1).ext`;
delete the stub. While the disk stays full, each 5-second retry leaves
another stub. Neither directory has a size cap, and both share `/persist`
with other services' data.

## Constraints

- **The inbox daemon never runs as root.** tailscaled tears down the host's
  DNS configuration at startup, even in userspace mode; as root that could
  remove the main instance's resolver config. The Aspect asserts it.
- **rue's main node must not use an exit node or `--accept-routes`** for
  routes overlapping the LAN or peer endpoints. The inbox daemon's sockets
  carry no fwmark, so they follow the main node's routing table. Advertising
  an exit node and subnets, as rue does, is fine.
- **The inbox node stays shields-up.** In userspace mode, a connection to
  `rue-inbox`'s own Tailscale IP that nothing in tailscaled handles is
  forwarded to the same port on rue's 127.0.0.1, so without shields up every
  device that can reach `rue-inbox` reaches rue's loopback-only services,
  such as AdGuard's admin UI and CouchDB. Shields up still lets Taildrop
  through. The daemon re-applies it on every start; never turn it off, and
  pass `--shields-up` to any `tailscale-inbox up`.
- **Sending from Linux needs operator rights.** Without them
  `tailscale file cp` fails with `Access denied: file access denied` and
  prints the `sudo tailscale set --operator=$USER` hint. cimmerian and t14g1
  set `myNixosModules.tailscale.operator`; anywhere else, run that once.
- **A manual `sudo tailscale up ...` on cimmerian or t14g1 must include
  `--operator=jmfv`.** `up` keeps the operator implicitly only when `$USER`
  matches it, and under sudo `$USER` is root; without the flag `up` refuses
  and prints the flags to add.
- **No store-and-forward.** Both ends have to be online during a transfer.
  rue is always on, so in practice only the sender matters.

## Troubleshooting

```bash
ssh rue journalctl -u tailscaled-inbox -u taildrop-inbox -e
ssh rue tailscale-inbox status
```

- `Logged out.` from `tailscale-inbox status`: the node lost its login (key
  expiry, removed in the console, or its state directory is gone). Redo the
  bootstrap login.
- `rue-inbox` missing from `tsend`'s picker: the node is offline or logged
  out (the two commands above), or the sender is logged in as someone else.
- `getting WaitingFiles: 500 ... Taildrop disabled; no storage directory`
  repeating every 5 seconds in the `taildrop-inbox` journal: the getter uses
  `Wants=`, not `BindsTo=`, on `tailscaled-inbox.service`, so it keeps
  running and retrying through the daemon being down, crashed (the daemon
  has `Restart=on-failure`), or logged out. This is expected before the
  bootstrap login, or after a key expiry, and stops once the daemon is back
  up and logged in.
- Same line still repeating after `tailscale-inbox status` shows the node
  running: Taildrop is disabled on the daemon side because it has no state
  directory. Check `journalctl -u tailscaled-inbox` for
  `Taildrop disabled; no state directory` -- that means the unit lost its
  `--statedir` flag (tailscale v1.102.2 feature/taildrop/retrieve.go:66-67,
  feature/taildrop/ext.go:144-148,196-199).
- `"/home/jmfv/Inbox" is not a directory`: the inbox directory is gone and
  the getter restarts every 5 seconds until it is back. On rue `~/Inbox` is a
  bind mount of `/persist/home/jmfv/Inbox`, so look there:
  `systemctl status home-jmfv-Inbox.mount` and
  `ls -ld /persist/home/jmfv/Inbox`. Not `systemd-tmpfiles --create`: with
  the mount down it would make a plain directory on the wiped root, and the
  getter needs the mount anyway (`RequiresMountsFor=`).
