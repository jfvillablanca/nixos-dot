# AdGuard Home DNS sinkhole on rue, backed by a local recursive Unbound
# resolver. AdGuard (:53) filters and forwards to Unbound (127.0.0.1:5335),
# which resolves recursively from the root with DNSSEC -- no third-party
# resolver in the path. The `adguard-mode` CLI (added in a later task) flips
# filtering scope at runtime via AdGuard's loopback control API + the Tailscale
# DNS API. The current mode is runtime state, never declared here.
{
  flake.modules.nixos.adguard = {
    config,
    lib,
    ...
  }: let
    cfg = config.myNixosModules.adguard;
  in {
    options.myNixosModules.adguard = {
      enable = lib.mkEnableOption "AdGuard Home DNS sinkhole" // {default = false;};
      lanInterface = lib.mkOption {
        type = lib.types.str;
        description = "Wired LAN interface AdGuard's DNS (:53) is reachable on.";
        example = "enp1s0";
      };
      lanCidr = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.0/24";
        description = "LAN subnet; the `lan-passthrough` client matches it in tailnet mode.";
      };
      routerIp = lib.mkOption {
        type = lib.types.str;
        default = "192.168.1.1";
        description = "ISP router IP (documentation / the DHCP secondary DNS target).";
      };
      tailnetIp = lib.mkOption {
        type = lib.types.str;
        description = "rue's own tailnet IP; the CLI points the tailnet nameserver here.";
        example = "100.70.231.87";
      };
      blocklistUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
        description = "HaGeZi Pro (low-false-positive) blocklist, AdGuard/adblock format.";
      };
    };

    config = lib.mkIf cfg.enable {
      # Recursive resolver. NOT the system resolver (AdGuard owns :53) ->
      # resolveLocalQueries = false. Validates DNSSEC from the root anchor.
      services.unbound = {
        enable = true;
        resolveLocalQueries = false;
        enableRootTrustAnchor = true;
        settings.server = {
          interface = ["127.0.0.1@5335"];
          access-control = ["127.0.0.0/8 allow" "::1 allow"];
          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = true;
          prefetch = true;
          edns-buffer-size = 1232;
          hide-identity = true;
          hide-version = true;
        };
      };

      # AdGuard Home. Web UI + control API on loopback ONLY (no `users:` -> no
      # auth needed; the local `adguard-mode` CLI reaches it on 127.0.0.1;
      # dashboard via `ssh -L 3000:localhost:3000 rue`). DNS (:53) listens on all
      # interfaces, gated by the firewall to the LAN iface + tailscale0.
      # Declare ONLY stable keys -- protection_enabled / clients / users are
      # runtime state the CLI owns (persisted under /var/lib/AdGuardHome), so a
      # rebuild must not reset the mode.
      services.adguardhome = {
        enable = true;
        mutableSettings = true;
        host = "127.0.0.1";
        port = 3000;
        openFirewall = false;
        settings = {
          dns = {
            bind_hosts = ["0.0.0.0"];
            port = 53;
            upstream_dns = ["127.0.0.1:5335"];
            # bootstrap only resolves upstream hostnames / filter-list URLs before
            # the resolver is warm; our upstream is a bare IP, so this is just for
            # the initial blocklist fetch.
            bootstrap_dns = ["9.9.9.9" "1.1.1.1"];
            enable_dnssec = true;
            ratelimit = 0; # LAN-only; not internet-exposed
          };
          filtering.filtering_enabled = true;
          filters = [
            {
              enabled = true;
              url = cfg.blocklistUrl;
              name = "HaGeZi Pro";
              id = 1;
            }
          ];
        };
      };

      # 53 reachable on the wired LAN (tailscale0 is already a trusted interface
      # via the tailscale module, so tailnet peers reach :53 without this).
      networking.firewall.interfaces.${cfg.lanInterface} = {
        allowedTCPPorts = [53];
        allowedUDPPorts = [53];
      };

      # The nixpkgs AdGuard module runs under DynamicUser=true, which makes
      # systemd manage /var/lib/private/AdGuardHome and symlink
      # /var/lib/AdGuardHome -> it. That symlink cannot be created over the
      # impermanence bind-mount at /var/lib/AdGuardHome (systemd exit
      # 238/STATE_DIRECTORY). Use a static user so StateDirectory is
      # /var/lib/AdGuardHome directly; CAP_NET_BIND_SERVICE (ambient) still lets
      # it bind :53 as non-root.
      users.users.adguardhome = {
        isSystemUser = true;
        group = "adguardhome";
      };
      users.groups.adguardhome = {};
      systemd.services.adguardhome.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "adguardhome";
        Group = "adguardhome";
      };

      # Persist AdGuard's state (query log, stats, runtime mode/clients) and
      # Unbound's DNSSEC root anchor across the ephemeral-root wipe.
      myNixosModules.persistence.directories = [
        {
          directory = "/var/lib/AdGuardHome";
          user = "adguardhome";
          group = "adguardhome";
          mode = "0700";
        }
        "/var/lib/unbound"
      ];
    };
  };
}
