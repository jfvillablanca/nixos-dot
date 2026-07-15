# Sunshine: self-hosted game/desktop stream host for Moonlight clients.
# X11 capture (capture = "x11") needs no KMS setcap wrapper, so capSysAdmin
# stays false -- simpler and no DRM-master fight with Xorg. The module
# auto-wires /dev/uinput, udev rules, avahi/mDNS, and (with openFirewall)
# the Moonlight ports. Sunshine runs as a *user* service bound to
# graphical-session.target, so the host must have an autologin GUI session
# up (see modules/desktop/xfce).
{
  flake.modules.nixos.sunshine = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.sunshine;
  in {
    options.myNixosModules.sunshine.enable =
      lib.mkEnableOption "Sunshine remote-desktop streaming host"
      // {default = false;};

    config = lib.mkIf cfg.enable {
      services.sunshine = {
        enable = true;
        openFirewall = true;
        capSysAdmin = false;
        settings.capture = "x11";
      };
    };
  };
}
