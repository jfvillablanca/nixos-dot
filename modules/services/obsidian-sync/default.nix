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
        description = "chttpd/max_http_request_size, per provision.ts:197. Also becomes nginx's client_max_body_size.";
      };

      maxDocumentSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 50000000;
        description = "couchdb/max_document_size, per provision.ts:202.";
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
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString couchdbPort}";
            extraConfig = ''
              limit_req zone=obsidian_funnel burst=${toString cfg.rateLimit.burst} nodelay;

              # LiveSync's live mode holds a continuous _changes feed open;
              # nginx's default response buffering would stall it.
              proxy_buffering off;
              proxy_read_timeout 600s;
              proxy_http_version 1.1;

              client_max_body_size ${toString cfg.maxHttpRequestSize};

              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;

              # No CORS headers here on purpose. CouchDB emits its own from the
              # [cors] settings above, and a duplicated
              # Access-Control-Allow-Origin makes browsers reject the response.
            '';
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
