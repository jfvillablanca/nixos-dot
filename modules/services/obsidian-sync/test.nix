# NixOS VM test for the obsidian-sync Aspect. Runs on x86_64-linux only, so it
# is invoked on rue rather than sienna -- see `just obsidian-test`.
#
# The funnel is deliberately left disabled: publishing over Funnel needs the
# Tailscale control plane, which a sealed VM does not have. nginx's
# funnel-versus-tailnet behaviour is still covered, by injecting the
# `Tailscale-Funnel-Request` header that tailscaled would set
# (ipn/ipnlocal/serve.go at v1.98.5).
{
  inputs,
  self,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
in {
  flake.checks.x86_64-linux.obsidian-sync = pkgs.testers.runNixOSTest {
    name = "obsidian-sync";

    nodes.server = {
      imports = [
        self.modules.nixos.obsidian-sync
        # Provides `myNixosModules.persistence.directories`, which the Aspect
        # writes to. The option is declared unconditionally
        # (modules/system/persistence/default.nix:148), outside the module's
        # own `config = lib.mkIf cfg.enable` at line 203, so importing without
        # enabling is enough. There is no impermanence in the VM.
        self.modules.nixos.persistence
      ];

      environment.etc."obsidian-sync-test/admin-password".text = "test-admin-password";
      environment.etc."obsidian-sync-test/sync-password".text = "test-sync-password";

      myNixosModules.obsidian-sync = {
        enable = true;
        adminPasswordFile = "/etc/obsidian-sync-test/admin-password";
        syncPasswordFile = "/etc/obsidian-sync-test/sync-password";
        funnel.enable = false;
      };

      virtualisation.memorySize = 2048;
    };

    testScript = ''
      server.wait_for_unit("couchdb.service")
      server.wait_for_open_port(5984)

      # The admin authenticates with the plaintext password from sops, proving
      # the derived -pbkdf2:sha256- value round-trips.
      server.succeed(
          "curl -fsS --user couchadmin:test-admin-password http://127.0.0.1:5984/_up"
      )
      server.fail(
          "curl -fsS --user couchadmin:wrong-password http://127.0.0.1:5984/_up"
      )

      # require_valid_user must be enforced for anonymous callers.
      server.succeed(
          "test 401 = $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:5984/)"
      )

      # Every setting LiveSync requires, read back from the running server.
      # provision.ts:181-206 at tag 1.0.21.
      def config_value(section, key):
          return server.succeed(
              "curl -fsS --user couchadmin:test-admin-password "
              f"http://127.0.0.1:5984/_node/_local/_config/{section}/{key}"
          ).strip()

      assert config_value("chttpd", "require_valid_user") == '"true"'
      assert config_value("chttpd_auth", "require_valid_user") == '"true"'
      assert config_value("httpd", "enable_cors") == '"true"'
      assert config_value("chttpd", "enable_cors") == '"true"'
      assert config_value("cors", "credentials") == '"true"'
      assert config_value("chttpd", "max_http_request_size") == '"4294967296"'
      assert config_value("couchdb", "max_document_size") == '"50000000"'
      assert config_value("chttpd_auth", "iterations") == '"10000"'
      assert config_value("httpd", "WWW-Authenticate") == '"Basic realm=\\"couchdb\\""'
      origins = config_value("cors", "origins")
      assert "app://obsidian.md" in origins
      assert "capacitor://localhost" in origins
      assert "http://localhost" in origins

      # CouchDB must not have rewritten the credential into its own writable
      # config. If an [admins] section appears here, the value was not
      # recognised as pre-hashed and every future rotation would be ignored
      # (couch_passwords.erl:68-88).
      server.succeed("test -e /var/lib/couchdb/local.ini")
      server.fail("grep -q '^\\[admins\\]' /var/lib/couchdb/local.ini")

      # The hashed form must never be written to disk outside tmpfs.
      server.succeed("grep -q '^couchadmin = -pbkdf2:sha256-' /run/couchdb/admin.ini")
    '';
  };
}
