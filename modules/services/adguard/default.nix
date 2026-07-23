# AdGuard Home DNS sinkhole on rue, backed by a local recursive Unbound
# resolver. AdGuard (:53) filters and forwards to Unbound (127.0.0.1:5335),
# which resolves recursively from the root with DNSSEC -- no third-party
# resolver in the path. The `adguard-mode` CLI flips filtering scope at
# runtime via AdGuard's loopback control API only (no Tailscale API; the
# tailnet nameserver is set by hand in the Tailscale console). The current
# mode is runtime state, never declared here.
{
  flake.modules.nixos.adguard = {
    config,
    lib,
    pkgs,
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
      tailnetIp = lib.mkOption {
        type = lib.types.str;
        description = "rue's own tailnet IP. The tailnet's global nameserver is pointed here by hand in the Tailscale admin console (Override local DNS) for away-coverage -- this option is documentation only; no code here consumes it.";
        example = "100.70.231.87";
      };
      blocklistUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
        description = "HaGeZi Pro (low-false-positive) blocklist, AdGuard/adblock format.";
      };

      rewrites = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            domain = lib.mkOption {
              type = lib.types.str;
              description = "Name to rewrite (a leading `*.` wildcards subdomains).";
            };
            answer = lib.mkOption {
              type = lib.types.str;
              description = ''IPv4/IPv6 literal, a hostname (CNAME), or "A"/"AAAA" to suppress that family.'';
            };
            enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Must stay true; a disabled/omitted entry is silently skipped by AdGuard.";
            };
          };
        });
        default = [];
        example = [
          {
            domain = "rue.internal";
            answer = "192.168.1.2";
          }
        ];
        description = ''
          Static DNS rewrites (name -> answer), declared here so Nix is the source
          of truth. Wired into `filtering.rewrites`; the nixpkgs module's yaml-merge
          replaces the whole list, so any runtime `/control/rewrite/add` entry is
          scratch-only (wiped on the next rebuild). A rewrite short-circuits before
          the blocklist and before upstream, but is gated by the querying client's
          effective filtering being on -- so under `adguard-mode tailnet` a name
          resolves for filtered sources (tailnet-source queries), not for the
          passed-through LAN. Use the `.internal` suffix: ICANN-reserved (never
          publicly delegated) AND resolvable via the OS resolver. Do NOT use
          `.home.arpa` -- macOS/iOS special-case the `.arpa` tree and refuse it via
          getaddrinfo (browsers/apps), so only `dig` would ever see those names.
        '';
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
          access-control = ["127.0.0.0/8 allow" "::1/128 allow"];
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
            # Listen on both families; the `::` socket serves IPv6 LAN clients
            # (link-local, ULA, GUA). The interface-scoped firewall rule below
            # already covers v6 (ip6tables), so no extra opening is needed.
            bind_hosts = ["0.0.0.0" "::"];
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
          filtering.rewrites = cfg.rewrites;
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

      # 53 reachable on the wired LAN. tailscale0 needs no rule here -- the
      # tailscale module already adds it to
      # networking.firewall.trustedInterfaces, so tailnet peers reach :53
      # without this. Defense-in-depth: cfg.lanInterface must stay LAN-side --
      # never point this at a WAN-facing interface, or the recursive Unbound
      # behind it (ratelimit=0) becomes an open resolver.
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

      # `adguard-mode` flips AdGuard's filtering scope at runtime via its
      # loopback-only control API (no `users:` -> no auth needed). See
      # module comment above for the mode semantics.
      environment.systemPackages = [
        pkgs.dnsutils # native dig/nslookup on the DNS host
        (pkgs.writeShellApplication {
          name = "adguard-mode";
          runtimeInputs = [pkgs.curl pkgs.jq];
          text = ''
            AGH="http://127.0.0.1:3000/control"
            LAN_CIDR="${cfg.lanCidr}"

            protection() { # $1 = true|false, $2 = duration_ms
              curl -sf --max-time 5 --connect-timeout 2 -X POST "$AGH/protection" -H "Content-Type: application/json" \
                -d "{\"enabled\": $1, \"duration\": $2}" >/dev/null
            }
            lan_client() { # $1 = filtering_enabled (true|false)
              local body count
              body=$(jq -n --argjson fe "$1" --arg lan "$LAN_CIDR" \
                '{name: "lan-passthrough", ids: [$lan], use_global_settings: false, filtering_enabled: $fe}')
              count=$(curl -sf --max-time 5 --connect-timeout 2 "$AGH/clients" | jq -r '[.clients[]? | select(.name == "lan-passthrough")] | length')
              if [ "$count" = "0" ]; then
                curl -sf --max-time 5 --connect-timeout 2 -X POST "$AGH/clients/add" -H "Content-Type: application/json" -d "$body" >/dev/null
              else
                curl -sf --max-time 5 --connect-timeout 2 -X POST "$AGH/clients/update" -H "Content-Type: application/json" \
                  -d "{\"name\": \"lan-passthrough\", \"data\": $body}" >/dev/null
              fi
            }
            parse_dur_ms() {
              case "''${1:-}" in
                "") echo 0 ;;
                *m) n=''${1%m}; case "$n" in '''|*[!0-9]*) echo "bad duration: $1 (use e.g. 15m, 30s)" >&2; exit 1 ;; esac; echo $(( n * 60000 )) ;;
                *s) n=''${1%s}; case "$n" in '''|*[!0-9]*) echo "bad duration: $1 (use e.g. 15m, 30s)" >&2; exit 1 ;; esac; echo $(( n * 1000 )) ;;
                *) echo "bad duration: $1 (use e.g. 15m, 30s)" >&2; exit 1 ;;
              esac
            }

            case "''${1:-status}" in
              off)
                dur=$(parse_dur_ms "''${2:-}")
                protection false "$dur"
                echo "mode: off (filtering disabled for everyone)" ;;
              tailnet)
                lan_client false
                protection true 0
                echo "mode: tailnet (LAN passthrough; tailnet-source filtered)" ;;
              broad)
                lan_client true
                protection true 0
                echo "mode: broad (everyone filtered)" ;;
              status)
                prot=$(curl -sf --max-time 5 --connect-timeout 2 "$AGH/status" | jq -r .protection_enabled 2>/dev/null || echo "UNREACHABLE")
                lanfe=$(curl -sf --max-time 5 --connect-timeout 2 "$AGH/clients" | jq -r '(.clients[]? | select(.name == "lan-passthrough") | .filtering_enabled) // "none"' 2>/dev/null || echo "?")
                echo "protection=$prot  lan_passthrough_filtering=$lanfe"
                if [ "$prot" = "false" ]; then echo "=> off"
                elif [ "$lanfe" = "false" ]; then echo "=> tailnet"
                elif [ "$prot" = "true" ]; then echo "=> broad"
                else echo "=> unknown"; fi ;;
              *) echo "usage: adguard-mode off [15m] | tailnet | broad | status" >&2; exit 1 ;;
            esac
          '';
        })
      ];
    };
  };
}
