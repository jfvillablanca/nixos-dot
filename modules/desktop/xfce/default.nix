# Minimal XFCE desktop on X11 with LightDM. Purpose-built for a headless
# host whose only reason for a GUI is Sunshine capture: set autoLoginUser
# so a graphical-session is always up (Sunshine's user service needs it),
# and drop the greeter (no monitor to see it). LightDM's greeterless mode
# only needs autoLogin.enable + autoLogin.timeout == 0
# (nixos/modules/services/x11/display-managers/lightdm.nix, the assertion
# on `!greeter.enable`); the latter already defaults to 0 upstream, so no
# override is needed here.
#
# stylix's XFCE target ships only as modules/xfce/hm.nix upstream -- there
# is no modules/xfce/nixos.nix, so `stylix.targets.xfce` is never declared
# in the plain NixOS option tree and setting it there would error at eval.
# It only exists inside the home-manager module tree, which stylix's own
# home-manager-integration.nix auto-injects into `home-manager.sharedModules`
# per host. So we reach it the same way, appending our own entry to
# `home-manager.sharedModules` (mirrors how impermanence's `home.persistence`
# is only reachable via that same mechanism -- see
# modules/system/persistence/default.nix).
{
  flake.modules.nixos.xfce = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.xfce;
    autologin = cfg.autoLoginUser != null;
  in {
    options.myNixosModules.xfce = {
      enable =
        lib.mkEnableOption "minimal XFCE desktop (X11) with optional autologin"
        // {default = false;};

      autoLoginUser = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          User to auto-login into the XFCE session. Set on headless hosts
          that only run a GUI for Sunshine capture. null keeps the greeter.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.xserver = {
        enable = true;
        desktopManager.xfce.enable = true;
        displayManager.lightdm = {
          enable = true;
          greeter.enable = !autologin;
        };
      };

      services.displayManager = {
        defaultSession = "xfce";
        autoLogin = lib.mkIf autologin {
          enable = true;
          user = cfg.autoLoginUser;
        };
      };

      home-manager.sharedModules = [
        {stylix.targets.xfce.enable = true;}
      ];
    };
  };
}
