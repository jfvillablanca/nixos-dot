# xrdp — remote desktop server.
{
  flake.modules.nixos.xrdp = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.xrdp;
  in {
    options.myNixosModules.xrdp = {
      enable =
        lib.mkEnableOption "xrdp remote desktop server"
        // {default = false;};

      windowManager = lib.mkOption {
        type = lib.types.str;
        description = ''
          Command to launch when an RDP client connects. Prefer an
          absolute store path; the xrdp session's PATH is minimal,
          so bare names may fail. Wayland compositors generally do
          not work under xrdp, pick an X11 session.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3389;
        description = "TCP port xrdp listens on.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Open the xrdp port on the system firewall. Leave false
          if reaching xrdp only via an already-trusted interface
          (e.g. `tailscale0` in `networking.firewall.trustedInterfaces`),
          which keeps the port closed to LAN and WAN.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.xrdp = {
        enable = true;
        defaultWindowManager = cfg.windowManager;
        inherit (cfg) port openFirewall;
      };
    };
  };
}
