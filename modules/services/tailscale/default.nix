{
  flake.modules.nixos.tailscale = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.tailscale;
  in {
    options.myNixosModules.tailscale = {
      enable =
        lib.mkEnableOption "tailscale mesh VPN"
        // {
          default = false;
        };

      useRoutingFeatures = lib.mkOption {
        type = lib.types.enum ["none" "client" "server" "both"];
        default = "client";
        description = ''
          "client" lets this host consume subnet routes / exit nodes
          others advertise. "server"/"both" enables IP forwarding so
          this host can act as a subnet router or exit node — only
          choose those for an always-on host you intend to expose.
        '';
      };

      trustInterface = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Add `tailscale0` to `networking.firewall.trustedInterfaces`
          so tailnet peers reach local services (ssh, nix-daemon,
          etc.) without those ports being open to the LAN.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        inherit (cfg) useRoutingFeatures;
      };

      networking.firewall.trustedInterfaces =
        lib.optional cfg.trustInterface "tailscale0";
    };
  };
}
