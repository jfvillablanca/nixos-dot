# Self-hosted Obsidian sync: CouchDB behind an nginx rate limiter, published to
# the public internet by Tailscale Funnel so a phone that is not on the tailnet
# can still sync. Clients run the Self-hosted LiveSync plugin.
#
# The CouchDB settings below are LiveSync's own requirements, taken from
# utils/couchdb/provision.ts:181-206 at tag 1.0.21, and declared here so Nix is
# the source of truth and upstream's Deno provisioner never runs on this host.
{
  flake.modules.nixos.obsidian-sync = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myNixosModules.obsidian-sync;
    couchdbPort = 5984;
    adminIni = "/run/couchdb/admin.ini";

    # Derives the hashed [admins] stanza at activation. A fresh salt each boot
    # is fine -- the hash still verifies the same password.
    hashAdmin = pkgs.writeShellApplication {
      name = "obsidian-sync-hash-admin";
      runtimeInputs = [pkgs.python3 pkgs.coreutils];
      text = ''
        install -d -m 0750 -o couchdb -g couchdb /run/couchdb
        umask 077
        python3 ${./_hash-admin.py} \
          ${lib.escapeShellArg cfg.adminUser} \
          ${lib.escapeShellArg cfg.adminPasswordFile} \
          ${toString cfg.pbkdf2Iterations} \
          > ${adminIni}.new
        chown couchdb:couchdb ${adminIni}.new
        chmod 0400 ${adminIni}.new
        mv ${adminIni}.new ${adminIni}
      '';
    };

    # Creates the system databases, the vault database, and a members-only
    # sync account -- see _provision.sh for why this exists instead of
    # upstream's admin-credential-handing Deno provisioner.
    provision = pkgs.writeShellApplication {
      name = "obsidian-sync-provision";
      runtimeInputs = [pkgs.curl pkgs.jq pkgs.coreutils];
      text = builtins.readFile ./_provision.sh;
    };

    # `tailscale funnel --bg` exits 0 even when nothing got published -- see
    # the funnel unit's ExecStartPost comment. Confirm the mapping is really
    # there by reading it back rather than trusting the exit code.
    funnelCheck = pkgs.writeShellApplication {
      name = "obsidian-sync-funnel-check";
      runtimeInputs = [config.services.tailscale.package pkgs.jq];
      text = ''
        status=$(tailscale serve status --json)
        echo "$status" | jq -e '.TCP."443".HTTPS == true' >/dev/null
        echo "$status" | jq -e '(.AllowFunnel // {}) | any' >/dev/null
      '';
    };
  in {
    options.myNixosModules.obsidian-sync = {
      enable =
        lib.mkEnableOption "Self-hosted Obsidian LiveSync (CouchDB behind Tailscale Funnel)"
        // {default = false;};

      database = lib.mkOption {
        type = lib.types.str;
        default = "obsidiannotes";
        description = "CouchDB database holding the vault. Clients must be configured with the same name.";
      };

      adminUser = lib.mkOption {
        type = lib.types.str;
        default = "couchadmin";
        description = "CouchDB server administrator. Used only over loopback by the provisioning unit; never given to a client.";
      };

      adminPasswordFile = lib.mkOption {
        # `path` with a quoted string, matching the tailscale Aspect's
        # authKeyFile (modules/services/tailscale/default.nix:87). A Nix path
        # literal would copy the secret into the store; a string does not.
        type = lib.types.path;
        description = ''
          Plaintext administrator password. A quoted string, never a Nix path
          literal -- a literal would copy the secret into the store. The
          `-pbkdf2:sha256-` form CouchDB stores is derived from this at
          activation; only the plaintext is kept in sops, so there is no second
          copy to drift out of sync.
        '';
        example = "/run/secrets/couchdb-admin-password";
      };

      syncUser = lib.mkOption {
        type = lib.types.str;
        default = "obsidian";
        description = ''
          Non-admin account the clients authenticate as. Granted `members` on
          `database` and nothing else, so a leaked client credential cannot
          reach server config or any other database.
        '';
      };

      syncPasswordFile = lib.mkOption {
        type = lib.types.path;
        description = "Plaintext password for `syncUser`. Quoted string, not a path literal.";
        example = "/run/secrets/couchdb-sync-password";
      };

      pbkdf2Iterations = lib.mkOption {
        type = lib.types.ints.positive;
        default = 10000;
        description = ''
          PBKDF2 iterations for both credentials. Deliberately far below
          CouchDB's 600000 default: the auth cache caches user documents rather
          than verified passwords, so this cost is paid on every Basic-auth
          request, and PouchDB sends Basic auth per request. Measured on rue's
          i5-7500: 277.6 ms at 600000 versus 4.6 ms at 10000. High iteration
          counts protect low-entropy passwords; both credentials here are long
          random strings, and a slow hash on a public endpoint is a CPU
          exhaustion amplifier for unauthenticated callers.
        '';
      };

      corsOrigins = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["app://obsidian.md" "capacitor://localhost" "http://localhost"];
        description = "Origins allowed by CouchDB's CORS. Defaults are LiveSync's own (provision.ts:24); Obsidian desktop is app://obsidian.md and mobile is capacitor://localhost.";
      };

      maxHttpRequestSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4294967296;
        description = "chttpd/max_http_request_size, per provision.ts:197. A CouchDB-side setting only -- see nginxMaxBodySize for why nginx does not mirror this number.";
      };

      maxDocumentSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 50000000;
        description = "couchdb/max_document_size, per provision.ts:202.";
      };

      nginxMaxBodySize = lib.mkOption {
        type = lib.types.str;
        default = "64m";
        description = ''
          nginx's client_max_body_size, deliberately decoupled from
          maxHttpRequestSize (4 GiB). That number is LiveSync's own
          chttpd/max_http_request_size requirement and must not change, but
          proxy_request_buffering is off below, so nginx streams the request
          body straight to CouchDB rather than staging the whole thing on
          disk first. Without a much smaller cap here, an unauthenticated
          caller could still make nginx buffer up to 4 GiB into a tempfile
          under PrivateTmp before CouchDB's own auth ever runs -- and that
          tempfile lands on rue's root btrfs subvolume, which
          modules/hosts/rue/_disko.nix shares with /persist and /nix.
          LiveSync chunks documents under maxDocumentSize (50 MB) by design,
          so 64m leaves headroom without reopening that hole. The two
          numbers do not need to, and must not, be re-coupled.
        '';
      };

      nginxPort = lib.mkOption {
        type = lib.types.port;
        default = 5985;
        description = "Loopback port nginx listens on and the funnel forwards to.";
      };

      rateLimit = {
        rate = lib.mkOption {
          type = lib.types.str;
          default = "30r/s";
          description = "nginx limit_req rate, applied to funnel-origin requests only.";
        };
        burst = lib.mkOption {
          type = lib.types.ints.positive;
          default = 120;
          description = "nginx limit_req burst, applied to funnel-origin requests only.";
        };
      };

      funnel.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Publish the endpoint over Tailscale Funnel. Off by default so the loopback path can be proven before anything is exposed.";
      };
    };

    config = lib.mkIf cfg.enable {
      services.couchdb = {
        enable = true;
        bindAddress = "127.0.0.1";
        port = couchdbPort;

        # `adminPass` is deliberately left null: the module would render it into
        # a world-readable store path. The admin arrives via extraConfigFiles.
        extraConfig = {
          # Single node. CouchDB's default n=3 describes a cluster this host
          # will never be part of.
          cluster.n = 1;

          chttpd = {
            require_valid_user = "true";
            enable_cors = "true";
            max_http_request_size = toString cfg.maxHttpRequestSize;
          };

          chttpd_auth = {
            require_valid_user = "true";
            iterations = toString cfg.pbkdf2Iterations;
          };

          httpd = {
            enable_cors = "true";
            WWW-Authenticate = "Basic realm=\"couchdb\"";
          };

          couchdb.max_document_size = toString cfg.maxDocumentSize;

          cors = {
            credentials = "true";
            origins = lib.concatStringsSep "," cfg.corsOrigins;
          };
        };

        # A /run path, so the secret never reaches the store. Ordered after the
        # module's own generated ini and before local.ini.
        extraConfigFiles = [adminIni];
      };

      services.nginx = {
        enable = true;

        appendHttpConfig = ''
          # Funnel forwards through tailscaled on loopback, so without this
          # every request would look like it came from 127.0.0.1 and the
          # limiter below would key every client to the same bucket.
          # tailscaled sets X-Forwarded-For to the real source
          # (ipn/ipnlocal/serve.go at v1.98.5).
          set_real_ip_from 127.0.0.1;
          real_ip_header X-Forwarded-For;
          real_ip_recursive off;

          # An empty key disables limit_req for that request. Only funnel
          # traffic carries the marker header, so public callers are throttled
          # per source IP while tailnet-origin replication runs unmetered --
          # which is what lets the phone seed the vault at full speed over the
          # tailnet before switching to funnel-only operation.
          map $http_tailscale_funnel_request $obsidian_limit_key {
            default "";
            "~." $binary_remote_addr;
          }

          limit_req_zone $obsidian_limit_key zone=obsidian_funnel:10m rate=${cfg.rateLimit.rate};
          limit_req_status 429;
        '';

        virtualHosts."obsidian-sync" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = cfg.nginxPort;
            }
          ];
          locations = let
            # Shared by both paths the client actually needs -- not by the
            # 404 catch-all below, since there is nothing to buffer, time
            # out, or size-limit on a response that never reaches CouchDB.
            proxiedConfig = ''
              limit_req zone=obsidian_funnel burst=${toString cfg.rateLimit.burst} nodelay;

              # LiveSync's live mode holds a continuous _changes feed open;
              # nginx's default response buffering would stall it.
              proxy_buffering off;
              proxy_read_timeout 600s;
              proxy_http_version 1.1;

              # Off so nginx streams the request body straight to CouchDB
              # instead of staging the whole thing on disk under PrivateTmp
              # first, before CouchDB's own auth ever runs. See
              # nginxMaxBodySize for why the cap below is far below
              # maxHttpRequestSize.
              proxy_request_buffering off;
              client_max_body_size ${cfg.nginxMaxBodySize};

              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              # No CORS headers here on purpose. CouchDB emits its own from the
              # [cors] settings above, and a duplicated
              # Access-Control-Allow-Origin makes browsers reject the response.
            '';
            proxyPass = "http://127.0.0.1:${toString couchdbPort}";
          in {
            # Exact match: PouchDB's replication probes server info at the
            # root before it ever touches a database.
            "= /" = {
              inherit proxyPass;
              extraConfig = proxiedConfig;
            };

            # `^~` wins over the catch-all below on prefix length alone, no
            # regex needed, and covers /${database}, its trailing-slash form,
            # and every sub-path LiveSync calls against it (_changes,
            # _bulk_docs, _revs_diff, per-document reads/writes,
            # attachments). Derived from cfg.database rather than hardcoded
            # so a renamed vault stays in sync automatically.
            "^~ /${cfg.database}" = {
              inherit proxyPass;
              extraConfig = proxiedConfig;
            };

            # Everything else -- _node/_local/_config, _users, _all_dbs,
            # _utils, _cluster_setup, any other database -- accepts the
            # server admin credential (see the Aspect's top comment), and
            # the members-only sync account protects none of it: the same
            # endpoint takes the admin login too. The LiveSync client
            # source (src/common/utils.ts requestToCouchDBWithCredentials)
            # only reaches _node/_local/_config from the setup wizard's
            # admin-only "check database configuration" helper, which
            # already 401s for the sync account (see test.nix). Returning
            # 404 here means Funnel never gets a chance to forward any of
            # it to CouchDB in the first place.
            "/" = {
              extraConfig = ''
                limit_req zone=obsidian_funnel burst=${toString cfg.rateLimit.burst} nodelay;
              '';
              return = 404;
            };
          };
        };
      };

      systemd.services.couchdb-admin-ini = {
        description = "Render CouchDB's [admins] stanza with a pre-hashed password";
        before = ["couchdb.service"];
        requiredBy = ["couchdb.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe hashAdmin;
        };
      };

      systemd.services.obsidian-sync-provision = {
        description = "Provision the Obsidian vault database and its sync account";
        after = ["couchdb.service"];
        requires = ["couchdb.service"];
        wantedBy = ["multi-user.target"];
        environment = {
          COUCH_URL = "http://127.0.0.1:${toString couchdbPort}";
          DATABASE = cfg.database;
          ADMIN_USER = cfg.adminUser;
          ADMIN_PASSWORD_FILE = cfg.adminPasswordFile;
          SYNC_USER = cfg.syncUser;
          SYNC_PASSWORD_FILE = cfg.syncPasswordFile;
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe provision;
        };
      };

      systemd.services.obsidian-sync-funnel = lib.mkIf cfg.funnel.enable {
        description = "Publish the Obsidian sync endpoint over Tailscale Funnel";
        after = ["tailscaled.service" "nginx.service"];
        wants = ["tailscaled.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;

          # Type=oneshot disables the start timeout by default (see the NOTE
          # under TimeoutStartSec in systemd.service(5); confirmed on rue:
          # `systemctl show -p TimeoutStartUSec` reports "infinity" for an
          # otherwise-identical oneshot unit here). Without a bound, the
          # interactive-enrollment wait below could hang `nixos-rebuild
          # switch` and boot itself forever, since this unit is wantedBy
          # multi-user.target.
          TimeoutStartSec = "60s";

          # Re-asserted every boot rather than trusted as one-time state, the
          # same reasoning as the tailscale module's extraSetFlags.
          ExecStart = "${config.services.tailscale.package}/bin/tailscale funnel --bg --https=443 http://127.0.0.1:${toString cfg.nginxPort}";

          # `tailscale funnel ... on` routes through verifyFunnelEnabled ->
          # enableFeatureInteractive (cmd/tailscale/cli/serve_legacy.go,
          # confirmed against the tailscale source at v1.102.2, the version
          # installed on rue) before it ever touches the serve config. If the
          # node lacks the `funnel` node attribute -- e.g. this got flipped
          # on before the tag:server policy grant lands -- and control
          # reports ShouldWait == false, the CLI prints an enrollment URL and
          # calls os.Exit(0): the oneshot goes "active (exited)" with nothing
          # published, and the process exit code alone cannot tell that
          # apart from success. Read the mapping back instead:
          # applyWebServe/applyFunnel (ipn/serve.go) populate
          # .TCP["443"].HTTPS and an .AllowFunnel entry once Funnel is really
          # up; both are absent from the empty `{}` this command returns in
          # the exit-0-and-silent case.
          ExecStartPost = lib.getExe funnelCheck;

          # Once the policy grant lands, a unit that failed silent-and-open
          # should recover on its own rather than wait for a human to notice
          # and restart it by hand.
          Restart = "on-failure";
          RestartSec = "10s";

          # `tailscale funnel ... off` goes through the same
          # verifyFunnelEnabled gate (serve_v2.go), so a grant that gets
          # revoked later can make ExecStop hang on the same interactive
          # watcher as ExecStart. That only happens in the same
          # not-yet-or-no-longer-enabled state ExecStartPost guards above --
          # once Funnel is actually enabled, verifyFunnelEnabled's hasCaps()
          # check short-circuits and ExecStop returns immediately. Tightened
          # from systemd's 90s default so a stuck stop cannot stall
          # `nixos-rebuild switch` or a reboot waiting on a click that, on an
          # unattended server, is never coming.
          TimeoutStopSec = "20s";
          ExecStop = "${config.services.tailscale.package}/bin/tailscale funnel --https=443 off";
        };
      };

      # CouchDB keeps both its databases and its view index under this path,
      # plus the local.ini it writes runtime config into. Without persistence
      # the ephemeral-root wipe destroys the vault on every boot.
      myNixosModules.persistence.directories = [
        {
          directory = "/var/lib/couchdb";
          user = "couchdb";
          group = "couchdb";
          mode = "0700";
        }
      ];
    };
  };
}
