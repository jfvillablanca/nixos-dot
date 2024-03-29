{ pkgs, ... }:
{
  imports = [ ./module.nix ];

  services.kmonad = {
    enable = true;
    package = import ./kmonad-pkg.nix { inherit pkgs; };
    extraArgs = [ "--log-level" "debug" ];
    keyboards = {
      "laptop" = {
        defcfg = {
          enable = true;
          compose.key = null;
          fallthrough = false;
          allowCommands = false;
        };

        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        config = builtins.readFile ./kbd/thinkpad-t14.kbd;
      };
      "keychron-k2" = {
        defcfg = {
          enable = true;
          compose.key = null;
          fallthrough = false;
          allowCommands = false;
        };

        device = "/dev/input/by-id/usb-Keychron_Keychron_K2-event-kbd";
        config = builtins.readFile ./kbd/keychron-k2.kbd;
      };
    };
  };
}
