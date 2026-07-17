# netdata — real-time host metrics dashboard. Bound to all interfaces so it's
# reachable at http://<host>:19999 from the tailnet (tailscale0 is a trusted
# firewall interface); the LAN stays blocked since 19999 isn't opened there.
{
  flake.modules.nixos.netdata = {
    lib,
    config,
    pkgs,
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
        # Default pkgs.netdata ships WITHOUT the web dashboard (API works but
        # `/` 404s). withCloudUi bundles the v3 dashboard; it carries the
        # ncul1 (Netdata Cloud UI) licence, so the host needs allowUnfree.
        package = pkgs.netdata.override {withCloudUi = true;};
        config.web."bind to" = "0.0.0.0";
      };
    };
  };
}
