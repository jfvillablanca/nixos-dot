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

  # macOS has no services.kanata. kanata MUST run as root — the Karabiner
  # virtual-HID daemon's IPC lives under .../org.pqrs/tmp/rootonly/ (root-only),
  # so both it and kanata are root LaunchDaemons. The catch: a faceless daemon
  # can't raise the Input Monitoring (TCC) prompt, and the System Settings "+"
  # add lands in the *user* TCC scope, which a root daemon never consults. The
  # grant is obtained once by running `sudo kanata` from a terminal (root + a
  # GUI session → system TCC scope). One-time imperative bootstrap; see
  # docs/kanata-macos.md.
  flake.modules.darwin.kanata = {pkgs, ...}: let
    kanataPkg = inputs.kanata.legacyPackages.${pkgs.stdenv.hostPlatform.system}.kanata;
    vhidDaemon = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
  in {
    launchd.daemons.karabiner-vhid-daemon.serviceConfig = {
      ProgramArguments = [vhidDaemon];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
    };

    launchd.daemons.kanata.serviceConfig = {
      ProgramArguments = [
        "${kanataPkg}/bin/kanata"
        "--nodelay"
        "--cfg"
        "${./kbd/macbook-qwerty.kbd}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/kanata.out.log";
      StandardErrorPath = "/var/log/kanata.err.log";
    };
  };
}
