# netdata — real-time host metrics dashboard. Bound to all interfaces so it's
# reachable at http://<host>:19999 from the tailnet (tailscale0 is a trusted
# firewall interface); the LAN stays blocked since 19999 isn't opened there.
{
  flake.modules.nixos.netdata = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.netdata;
  in {
    options.myNixosModules.netdata.enable =
      lib.mkEnableOption "netdata host metrics dashboard"
      // {default = false;};

    config = lib.mkIf cfg.enable {
      services.netdata = {
        enable = true;
        config.web."bind to" = "0.0.0.0";
      };
    };
  };
}
