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
        # Do NOT set authKeyParameters here: it appends a
        # `?ephemeral=...&preauthorized=...` query string to the key, which is
        # the OAuth-client-secret convention. For a plain pre-generated
        # `tskey-auth-...` key (tag/expiry/preauth are fixed at generation)
        # that query string makes the control server take the "validate API
        # key" path and reject it ("invalid key: unable to validate API key").
        # Send the raw key only.
        #
        # --ssh goes on `tailscale up` (extraUpFlags), NOT `tailscale set`
        # (extraSetFlags): nixpkgs' tailscaled-set unit runs even when the
        # bootstrap `up` fails, so a failed first join leaves ssh=true on a
        # logged-out node, and the next `up` (without --ssh) then trips
        # "changing settings via 'tailscale up' requires mentioning all
        # non-default flags". Keeping --ssh on the `up` call avoids that.
        extraUpFlags = lib.optional cfg.enableSSH "--ssh";
      };

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
