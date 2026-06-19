# kanata — keyboard remapper.
{inputs, ...}: {
  flake-file.inputs.kanata.follows = "nixpkgs";

  flake.modules.nixos.kanata = {pkgs, ...}: {
    services.kanata = {
      enable = true;
      package = inputs.kanata.legacyPackages.${pkgs.stdenv.hostPlatform.system}.kanata;
      keyboards = {
        thinkpad-t14 = {
          devices = ["/dev/input/by-path/platform-i8042-serio-0-event-kbd"];
          extraDefCfg = "process-unmapped-keys yes";
          config = builtins.readFile ./kbd/thinkpad-t14.kbd;
        };
      };
    };
  };

  # macOS has no services.kanata. On recent macOS (Tahoe) a faceless root
  # LaunchDaemon is denied input-device access at boot ("Couldn't register any
  # device"), yet kanata needs root (device seize + the Karabiner root-only IPC
  # under .../org.pqrs/tmp/rootonly/). The working shape: kanata as a *login*
  # LaunchAgent (Input Monitoring is honored in the GUI session) that calls
  # `sudo` for root via a NOPASSWD rule so it never blocks on a prompt. The pqrs
  # virtual-HID daemon stays a faceless root daemon (needs no TCC). The NOPASSWD
  # command and the agent args share `kanataArgs`, so they stay in lockstep on a
  # kanata bump. See docs/kanata-macos.md.
  flake.modules.darwin.kanata = {pkgs, ...}: let
    kanataPkg = inputs.kanata.legacyPackages.${pkgs.stdenv.hostPlatform.system}.kanata;
    vhidDaemon = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
    kanataArgs = ["${kanataPkg}/bin/kanata" "--nodelay" "--cfg" "${./kbd/macbook-qwerty.kbd}"];
  in {
    # Top-row handling lives entirely in the kbd: kanata receives F1-F12 (and
    # the Fn key) regardless of this flag, emits media on plain press, and
    # reaches F1-F12 via an Fn-held layer. Keep fnState at the default (false)
    # so the row falls back to native media if kanata isn't running; set it
    # explicitly so a switch clears any stale `true`.
    system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = false;

    launchd.daemons.karabiner-vhid-daemon.serviceConfig = {
      ProgramArguments = [vhidDaemon];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
    };

    launchd.user.agents.kanata.serviceConfig = {
      ProgramArguments = ["/usr/bin/sudo"] ++ kanataArgs;
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ProcessType = "Interactive";
      StandardOutPath = "/tmp/kanata.out.log";
      StandardErrorPath = "/tmp/kanata.err.log";
    };

    security.sudo.extraConfig = ''
      %admin ALL=(root) NOPASSWD: ${builtins.concatStringsSep " " kanataArgs}
    '';
  };
}
