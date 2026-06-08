# kanata on macOS — bootstrap reference

kanata is wired declaratively: the `flake.modules.darwin.kanata` twin in
`modules/services/kanata/default.nix` installs the package, the keymap
(`kbd/macbook-qwerty.kbd`), and two root LaunchDaemons — one for the pqrs
virtual-HID daemon and one for kanata. But macOS will not let
Nix install a DriverKit system extension or click a security approval, so the
**driver install and the permission grants are a one-time imperative
bootstrap**. Do these once per MacBook; everything after is handled by
`nh darwin switch`.

## Why it cannot be fully declarative

kanata cannot grab the keyboard on macOS by itself — it needs a virtual HID
device provided by pqrs-org's **Karabiner-DriverKit-VirtualHIDDevice** driver.
That driver:

- ships only as a notarized `.pkg` that installs into `/Applications` and
  `/Library/Application Support/org.pqrs/...` — paths Nix does not manage, and
- is a DriverKit **system extension**, which macOS requires a human to approve
  interactively in System Settings.

Neither step is expressible in nix-darwin. This is the same class of
limitation as TCC permission grants and `masApps`.

**kanata must run as root, and Input Monitoring must be granted in the _system_
TCC scope.** kanata cannot run as a normal user — the Karabiner virtual-HID
daemon's IPC lives under `.../org.pqrs/tmp/rootonly/`, which only root can reach
(a non-root run dies with `IOHIDDeviceOpen ... privilege violation`). But a
faceless root daemon can't raise the Input Monitoring prompt, and adding the
binary via System Settings → Input Monitoring `+` writes the _user_ TCC scope,
which the root daemon never consults (so it dies with `IOHIDDeviceOpen ... not
permitted` no matter how often you re-add and reboot). The grant must be
obtained in the _system_ scope by running `sudo kanata` once from a terminal —
root **and** a GUI session, so the prompt it raises lands where the daemon
reads it. See step 5.

Sources:

- kanata macOS setup — <https://github.com/jtroo/kanata/blob/main/docs/setup-macos.md>
- driver README — <https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice>
- LaunchDaemon how-to — <https://github.com/jtroo/kanata/discussions/1537>
- daemon vs agent / TCC scope discussion — <https://github.com/jtroo/kanata/discussions/1019>

## One-time bootstrap

1. **Install the driver.** Download the latest release `.pkg` from
   <https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases>
   and run the installer. (kanata expects a specific driver major version —
   check `setup-macos.md` above for the version your pinned kanata wants; a
   mismatch shows up as a connection failure in the kanata log.)

2. **Activate the driver.** This registers the system extension and triggers
   the approval prompt. The command often does **not** return while approval is
   pending — that is normal (the extension parks at
   `[activated waiting for user]`). Ctrl+C is safe once you have approved,
   because the state lives in the system, not the command.

   ```sh
   sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
   ```

3. **Approve the system extension.** The location moved in recent macOS:
   - **macOS 26 Tahoe and later:** System Settings → General → **Login Items &
     Extensions** → **Driver Extensions** → enable the Karabiner entry.
   - **macOS 15 and earlier:** System Settings → Privacy & Security → scroll to
     the _Security_ section → **Allow** software from "pqrs.org".

   Confirm the state flipped from `waiting for user` to enabled:

   ```sh
   systemextensionsctl list   # expect [activated enabled] on the pqrs entry
   ```

4. **Switch the config so the services land:**

   ```sh
   nh darwin switch
   ```

   This installs `org.nixos.karabiner-vhid-daemon` and `org.nixos.kanata` into
   `/Library/LaunchDaemons/`. kanata will crash-loop with `not permitted` until
   step 5 grants Input Monitoring.

5. **Grant Input Monitoring in the _system_ scope.** Do **not** use the System
   Settings `+` button — it writes the user scope, which the root daemon
   ignores. Instead, run kanata manually as root once to raise the prompt in
   the system scope. Pull the exact binary + config paths from the deployed
   daemon, then run it:

   ```sh
   plutil -p /Library/LaunchDaemons/org.nixos.kanata.plist | grep string
   sudo /nix/store/<hash>-kanata-<ver>/bin/kanata --cfg /nix/store/<hash>-macbook-qwerty.kbd
   ```

   macOS pops "kanata would like to receive keystrokes" → **Open System
   Settings → enable kanata** under Input Monitoring. Keys should start
   remapping in that terminal. Ctrl+C, then (re)start the daemon:

   ```sh
   sudo launchctl kickstart -k system/org.nixos.kanata
   tail -f /var/log/kanata.err.log
   ```

6. **Confirm it is live.** Tap `Caps` → should emit Esc; hold `a` → should act
   as Command. Check the daemons are loaded:

   ```sh
   sudo launchctl list | grep -E 'kanata|karabiner'
   ```

## Gotchas

- **Input Monitoring resets on kanata updates.** TCC keys the grant to the
  exact binary path; a new Nix store path (after a `kanata` bump) drops the
  permission. Re-run the `sudo kanata` grant from step 5 after a bump, or front
  kanata with a stable wrapper path if this becomes annoying.
- **Driver / kanata version skew.** A major-version mismatch between the
  installed driver and what kanata expects surfaces as a connection failure in
  `/var/log/kanata.err.log`. Install the version kanata names.
- **macOS updates** can require re-approving the system extension.
- **Uninstall the driver:**

  ```sh
  sudo /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager deactivate
  ```

  then remove it with the pqrs uninstaller.

## Replicating on another MacBook

1. Import `self.modules.darwin.kanata` in the new host's
   `modules/hosts/<host>/default.nix` (as sienna does).
2. If the built-in keyboard differs, copy
   `modules/services/kanata/kbd/macbook-qwerty.kbd` and adjust the layers.
3. Run the one-time bootstrap above.
