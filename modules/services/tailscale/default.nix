{
  flake.modules.nixos.tailscale = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.tailscale;
    # Flags applied both at join (`tailscale up`, extraUpFlags) and on every
    # activation (`tailscale set`, extraSetFlags). On `up` keeps the bootstrap
    # self-consistent (no "mention all non-default flags" trip); on `set` makes
    # an already-running host re-apply them on rebuild, since autoconnect's `up`
    # no-ops once the node is Running -- `set` is what applies later changes
    # like toggling the exit node.
    persistentFlags =
      (lib.optional cfg.enableSSH "--ssh")
      ++ (lib.optional cfg.advertiseExitNode "--advertise-exit-node")
      ++ (lib.optional (cfg.advertiseRoutes != [])
        "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}");
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

      enableSSH = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Pass `--ssh` to `tailscale up`. Lets tailnet peers
          authorized by ACL `tailscale ssh` in with identity carried
          by Tailscale, no separate keys. Off by default; flip on
          hosts you intend to expose as a relay or admin target.
        '';
      };

      advertiseExitNode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Advertise this host as a Tailscale exit node
          (`--advertise-exit-node`). Requires `useRoutingFeatures =
          "server"` or `"both"` (IP forwarding) and a one-time approval in
          the admin console (Machines -> host -> approve exit node). Off by
          default; only for an always-on host you route traffic through.
        '';
      };

      advertiseRoutes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["192.168.1.0/24"];
        description = ''
          Subnet CIDRs to advertise as a Tailscale subnet router
          (`--advertise-routes`), letting tailnet peers reach these LAN
          hosts through this node. Requires `useRoutingFeatures = "server"`
          or `"both"` (IP forwarding) and a one-time approval in the admin
          console (Machines -> host -> approve subnet routes). Consuming
          peers also need `--accept-routes` (default on macOS/iOS/Windows/
          Android; off on Linux). Empty (default) = not a subnet router.
        '';
      };

      authKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to a file (outside the Nix store, delivered out-of-band,
          never committed) holding a Tailscale auth key. When set,
          tailscaled auto-authenticates on first boot -- no interactive
          login. Use a tagged, pre-authorized, non-ephemeral key so the
          node has key-expiry disabled and never needs re-auth. Pass a
          quoted string path, never a Nix path literal.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        inherit (cfg) useRoutingFeatures authKeyFile;
        # Do NOT set authKeyParameters: it appends a
        # `?ephemeral=...&preauthorized=...` query string (the OAuth-client
        # convention). On a plain pre-generated `tskey-auth-...` key that makes
        # the control server reject it ("invalid key: unable to validate API
        # key"). Send the raw key only.
        extraUpFlags = persistentFlags;
        extraSetFlags = persistentFlags;
      };

      assertions = [
        {
          assertion =
            !cfg.advertiseExitNode
            || lib.elem cfg.useRoutingFeatures ["server" "both"];
          message = ''
            myNixosModules.tailscale.advertiseExitNode requires
            useRoutingFeatures = "server" or "both" (exit nodes need IP
            forwarding).
          '';
        }
        {
          assertion =
            cfg.advertiseRoutes
            == []
            || lib.elem cfg.useRoutingFeatures ["server" "both"];
          message = ''
            myNixosModules.tailscale.advertiseRoutes requires
            useRoutingFeatures = "server" or "both" (subnet routers need IP
            forwarding).
          '';
        }
      ];

      networking.firewall.trustedInterfaces =
        lib.optional cfg.trustInterface "tailscale0";

      myNixosModules.persistence.directories = [
        {
          directory = "/var/lib/tailscale";
          mode = "0700";
        }
      ];
    };
  };

  # Darwin twin. nix-darwin's `services.tailscale` is daemon + MagicDNS
  # only — none of the NixOS routing/firewall/SSH knobs — so this exposes
  # just `enable`; subnet/exit-node/--ssh flags go on `tailscale up` by hand.
  flake.modules.darwin.tailscale = {
    lib,
    config,
    ...
  }: let
    cfg = config.myDarwinModules.tailscale;
  in {
    options.myDarwinModules.tailscale.enable =
      lib.mkEnableOption "tailscale mesh VPN"
      // {
        default = false;
      };

    config = lib.mkIf cfg.enable {
      services.tailscale.enable = true;
    };
  };
}
