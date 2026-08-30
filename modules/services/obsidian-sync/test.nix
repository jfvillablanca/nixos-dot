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

      # /run rather than environment.etc: /etc entries are read-only symlinks
      # into the Nix store, so the rotation test below could never rewrite a
      # password and re-verify -- exactly what commit 48d6ae7's restartUnits
      # claims a sops edit plus rebuild now does for real secrets. Content is
      # seeded by tmpfiles rather than by the test script, because
      # couchdb-admin-ini runs at boot, before the test script gets a chance
      # to write anything -- the file has to already hold a valid password by
      # the time multi-user.target starts pulling in units.
      systemd.tmpfiles.rules = [
        "d /run/obsidian-sync-test 0700 root root -"
        "f /run/obsidian-sync-test/admin-password 0600 root root - test-admin-password-000\\n"
        "f /run/obsidian-sync-test/sync-password 0600 root root - test-sync-password-000\\n"
      ];

      myNixosModules.obsidian-sync = {
        enable = true;
        adminPasswordFile = "/run/obsidian-sync-test/admin-password";
        syncPasswordFile = "/run/obsidian-sync-test/sync-password";
        funnel.enable = false;

        # Production values are 30r/s / burst 120. The test asserts the
        # mechanism, not the tuning, so make it trip immediately.
        rateLimit = {
          rate = "1r/s";
          burst = 1;
        };
      };

      virtualisation.memorySize = 2048;
    };

    testScript = ''
      server.wait_for_unit("couchdb.service")
      server.wait_for_open_port(5984)

      admin = "--user couchadmin:test-admin-password-000"
      sync = "--user obsidian:test-sync-password-000"

      # The admin authenticates with the plaintext password from sops, proving
      # the derived -pbkdf2:sha256- value round-trips.
      server.succeed(f"curl -fsS {admin} http://127.0.0.1:5984/_up")
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
              f"curl -fsS {admin} "
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

      server.wait_for_unit("nginx.service")
      server.wait_for_open_port(5985)

      # The proxy reaches CouchDB and auth still applies through it. The root
      # probe -- not /_up -- is what the allowlist further down actually
      # admits; LiveSync's replication uses it to read server info before
      # touching a database.
      server.succeed(f"curl -fsS {admin} http://127.0.0.1:5985/")
      server.succeed(
          "test 401 = $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:5985/)"
      )

      # Tailnet-origin traffic carries no funnel marker and must never be
      # throttled -- the initial vault seed runs over this path. Asserting
      # the exact response set (not just "no 429") matters: if auth broke
      # instead, every request would 401 and "429 not in codes" would still
      # pass despite nothing actually working.
      codes = set(
          server.succeed(
              "for i in $(seq 1 40); do "
              "curl -s -o /dev/null -w '%{http_code}\\n' "
              f"{admin} http://127.0.0.1:5985/; done"
          ).split()
      )
      assert codes == {"200"}, f"tailnet traffic was not uniformly 200: {codes}"

      # Funnel-origin traffic is throttled. tailscaled sets this header on
      # public requests (ipn/ipnlocal/serve.go at v1.98.5).
      codes = server.succeed(
          "for i in $(seq 1 40); do "
          "curl -s -o /dev/null -w '%{http_code}\\n' "
          "-H 'Tailscale-Funnel-Request: ?1' "
          f"{admin} http://127.0.0.1:5985/; done"
      )
      assert "429" in codes, f"funnel traffic was not rate limited: {codes}"

      # Per-IP keying, not one shared bucket for every funnel client. real_ip
      # substitutes $binary_remote_addr with X-Forwarded-For here because
      # curl's real source, 127.0.0.1, is trusted by set_real_ip_from -- so
      # each distinct XFF below lands in its own limiter bucket. If real_ip
      # were broken and every request collapsed into 127.0.0.1's own bucket
      # instead, this would 429 immediately given the test's rate=1r/s
      # burst=1.
      codes = set(
          server.succeed(
              "for i in $(seq 1 40); do "
              "curl -s -o /dev/null -w '%{http_code}\\n' "
              "-H 'Tailscale-Funnel-Request: ?1' "
              "-H \"X-Forwarded-For: 10.0.0.$i\" "
              f"{admin} http://127.0.0.1:5985/; done"
          ).split()
      )
      assert codes == {"200"}, f"distinct-IP funnel traffic was rate limited: {codes}"

      server.wait_for_unit("obsidian-sync-provision.service")

      # System databases exist. CouchDB does not create these on its own when
      # _cluster_setup is skipped, and replication fails without _users.
      for db in ("_users", "_replicator", "obsidiannotes"):
          server.succeed(f"curl -fsS {admin} http://127.0.0.1:5984/{db}")

      # The sync account can use its own database...
      server.succeed(f"curl -fsS {sync} http://127.0.0.1:5984/obsidiannotes")
      server.succeed(
          f"curl -fsS {sync} -X PUT -H 'Content-Type: application/json' "
          "-d '{\"hello\":\"world\"}' http://127.0.0.1:5984/obsidiannotes/testdoc"
      )

      # ...and nothing else. This is the whole point of not handing clients the
      # admin credential. Asserting the exact status code rather than just
      # `server.fail` matters: curl -f exits non-zero identically for 401,
      # 404, a refused connection, or a typo'd URL, so a bare `fail` would
      # pass even if the account were broken outright. CouchDB returns 401
      # (not 403) for authenticated-but-unauthorized on admin-gated
      # endpoints.
      server.succeed(
          "test 401 = $(curl -s -o /dev/null -w '%{http_code}' "
          + sync
          + " http://127.0.0.1:5984/_node/_local/_config)"
      )
      server.succeed(
          "test 401 = $(curl -s -o /dev/null -w '%{http_code}' "
          + sync
          + " http://127.0.0.1:5984/_users/_all_docs)"
      )

      # Idempotent: a second run must not fail or clobber existing data.
      server.succeed("systemctl restart obsidian-sync-provision.service")
      server.succeed(f"curl -fsS {sync} http://127.0.0.1:5984/obsidiannotes/testdoc")

      # The nginx allowlist: only the root probe and the vault database are
      # reachable through the public-facing port. Everything else -- admin
      # config, _users, _all_dbs, the Fauxton UI, an unrelated database name
      # -- must 404 at nginx before Funnel could ever forward it to CouchDB,
      # even with a valid admin credential in hand. CouchDB always answers
      # with a JSON body carrying an "error" key on failure; nginx's bare
      # `return 404` has no such body, which is what tells "nginx blocked
      # this" apart from "CouchDB rejected this".
      for path in (
          "/_all_dbs",
          "/_utils",
          "/_utils/",
          "/_node/_local/_config",
          "/_cluster_setup",
          "/_users",
          "/otherdb",
      ):
          code = server.succeed(
              "curl -s -o /dev/null -w '%{http_code}' "
              f"{admin} http://127.0.0.1:5985{path}"
          )
          body = server.succeed(f"curl -s {admin} http://127.0.0.1:5985{path}")
          assert code == "404", f"{path} should be blocked by the nginx allowlist, got {code}"
          assert '"error"' not in body, f"{path} reached CouchDB instead of being blocked by nginx: {body}"

      # The vault database itself is still reachable through the same port.
      server.succeed(f"curl -fsS {admin} http://127.0.0.1:5985/obsidiannotes")

      # Rotation: commit 48d6ae7's restartUnits claims a sops edit plus
      # rebuild is a real credential rotation. Prove it -- rewrite the
      # password file the way a rebuild would replace a sops secret file,
      # restart what production restarts, and check both that the new
      # password works and that the old one is actually gone, not just
      # additionally accepted.
      server.succeed(
          "printf 'test-admin-password-999\\n' > /run/obsidian-sync-test/admin-password"
      )
      server.succeed(
          "systemctl restart couchdb-admin-ini.service couchdb.service obsidian-sync-provision.service"
      )
      server.wait_for_unit("couchdb.service")
      server.wait_for_open_port(5984)
      server.wait_for_unit("obsidian-sync-provision.service")

      admin = "--user couchadmin:test-admin-password-999"
      server.succeed(f"curl -fsS {admin} http://127.0.0.1:5984/_up")
      server.succeed(
          "test 401 = $(curl -s -o /dev/null -w '%{http_code}' "
          "--user couchadmin:test-admin-password-000 http://127.0.0.1:5984/_up)"
      )

      server.succeed(
          "printf 'test-sync-password-999\\n' > /run/obsidian-sync-test/sync-password"
      )
      server.succeed("systemctl restart obsidian-sync-provision.service")
      server.wait_for_unit("obsidian-sync-provision.service")

      sync = "--user obsidian:test-sync-password-999"
      server.succeed(f"curl -fsS {sync} http://127.0.0.1:5984/obsidiannotes")
      server.succeed(
          "test 401 = $(curl -s -o /dev/null -w '%{http_code}' "
          "--user obsidian:test-sync-password-000 http://127.0.0.1:5984/obsidiannotes)"
      )

      # funnel.enable is false for this node, so nothing may be published.
      server.fail("systemctl cat obsidian-sync-funnel.service")
    '';
  };
}
