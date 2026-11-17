# NixOS VM test for the taildrop-inbox Aspect. Runs on x86_64-linux only, so
# it is invoked on rue rather than sienna -- see `just taildrop-inbox-test`.
#
# A sealed VM has no Tailscale control plane, so this proves the plumbing
# only: the inbox daemon and getter run as the user next to a kernel-mode
# main daemon, and the inbox daemon's startup leaves the host's resolver
# alone. Login, delivery and the file-sharing node cap are checked by hand at
# bootstrap (docs/taildrop-inbox.md).
{
  inputs,
  self,
  ...
}: let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  inherit (self.constants) user;
in {
  flake.checks.x86_64-linux.taildrop-inbox = pkgs.testers.runNixOSTest {
    name = "taildrop-inbox";

    nodes.machine = {
      imports = [
        # The Aspect's `user` defaults to systemConstants.user, which hosts
        # get through system-default.
        self.modules.generic.systemConstants
        # Both Aspects below write `myNixosModules.persistence.directories`,
        # which is declared even with persistence disabled, as it is here.
        self.modules.nixos.persistence
        # The main, kernel-mode daemon, so coexistence is under test too.
        self.modules.nixos.tailscale
        self.modules.nixos.taildrop-inbox
      ];

      users.users.${user}.isNormalUser = true;

      # A known, non-empty resolv.conf to compare before and after, pointing
      # at loopback like rue's.
      networking.nameservers = ["127.0.0.1"];

      environment.systemPackages = [pkgs.jq];

      myNixosModules = {
        tailscale.enable = true;
        taildropInbox.enable = true;
      };
    };

    testScript = ''
      machine.wait_for_unit("multi-user.target")
      machine.wait_for_unit("tailscaled.service")
      machine.wait_for_unit("tailscaled-inbox.service")
      machine.wait_for_unit("taildrop-inbox.service")

      uid = machine.succeed("id -u ${user}").strip()
      inbox = "runuser -u ${user} -- /run/current-system/sw/bin/tailscale-inbox"
      logged_out = "status --json | jq -r .BackendState | grep -qx NeedsLogin"


      def uids(unit):
          pid = machine.succeed(f"systemctl show -p MainPID --value {unit}").strip()
          assert pid != "0", f"{unit} has no main process"
          status = machine.succeed(f"cat /proc/{pid}/status").splitlines()
          return [line for line in status if line.startswith("Uid:")][0].split()[1:]


      # Requirement 1: real, effective, saved and filesystem uids are all the
      # user's, for the daemon and the getter alike.
      for unit in ("tailscaled-inbox.service", "taildrop-inbox.service"):
          assert uids(unit) == [uid] * 4, f"{unit} is not running as ${user}"

      # The wrapper reaches this daemon's socket, and same-uid access needs no
      # --operator. With no control plane a fresh node settles in NeedsLogin
      # (ipn/ipnlocal/profiles.go:860-866, ipn/ipnlocal/local.go:6857-6861);
      # the plain-text form prints "Logged out." and exits 1
      # (cmd/tailscale/cli/status.go:154,268-269).
      machine.wait_until_succeeds(f"{inbox} {logged_out}")
      machine.succeed("test -S /run/tailscale-inbox/tailscaled.sock")
      owner = machine.succeed("stat -c %U /run/tailscale-inbox/tailscaled.sock").strip()
      assert owner == "${user}", f"socket owned by {owner}"
      code, out = machine.execute(f"{inbox} status")
      assert code == 1 and "Logged out." in out, f"unexpected status: {code} {out!r}"

      # Requirement 2: --statedir, never --state; logs follow $STATE_DIRECTORY
      # into the same directory.
      unit_file = machine.succeed("systemctl cat tailscaled-inbox.service")
      assert "--statedir=/var/lib/tailscale-inbox" in unit_file
      assert "--state=" not in unit_file
      assert "--port=0" in unit_file
      state = machine.succeed("stat -c '%U %G %a' /var/lib/tailscale-inbox").strip()
      assert state == "${user} users 700", f"state dir is {state}"
      machine.succeed("test -f /var/lib/tailscale-inbox/tailscaled.log.conf")

      # The getter's target exists before it starts, private to the user.
      target = machine.succeed("stat -c '%U %G %a' /home/${user}/Inbox").strip()
      assert target == "${user} users 700", f"inbox dir is {target}"

      # Logged out is the normal state until bootstrap, so `file get --loop`
      # must ride it out instead of exiting (cmd/tailscale/cli/file.go:774-795):
      # still up after two of its 5s retries, never restarted by systemd.
      machine.sleep(12)
      machine.succeed("systemctl is-active taildrop-inbox.service")
      restarts = machine.succeed(
          "systemctl show -p NRestarts --value taildrop-inbox.service"
      ).strip()
      assert restarts == "0", f"getter restarted {restarts} times"

      # Coexistence: the kernel-mode main daemon keeps its own socket and TUN
      # and still answers on the default socket.
      machine.succeed("test -S /run/tailscale/tailscaled.sock")
      machine.succeed("ip link show tailscale0")
      machine.wait_until_succeeds(f"tailscale {logged_out}")

      # Requirement 1, end to end. tailscaled runs dns.CleanUp before it serves
      # anything, even in userspace mode (cmd/tailscaled/tailscaled.go:517).
      # With no resolvconf on this unit's PATH it picks the direct manager,
      # whose teardown deletes /etc/resolv.tailscale.conf
      # (net/dns/direct.go:568-578) -- given root's write access to /etc. The
      # decoy is the control that fails under root; the hash shows
      # resolv.conf itself is untouched.
      machine.succeed("systemctl stop tailscaled-inbox.service")
      machine.succeed("echo decoy > /etc/resolv.tailscale.conf")
      machine.succeed("grep -qx 'nameserver 127.0.0.1' /etc/resolv.conf")
      before = machine.succeed("sha256sum /etc/resolv.conf")
      # The getter only Wants= the daemon, so it keeps looping while the
      # daemon is down instead of being stopped with it.
      machine.succeed("systemctl is-active taildrop-inbox.service")
      machine.succeed("systemctl start tailscaled-inbox.service")
      machine.wait_for_unit("tailscaled-inbox.service")
      machine.wait_until_succeeds(f"{inbox} {logged_out}")
      after = machine.succeed("sha256sum /etc/resolv.conf")
      assert after == before, "the inbox daemon changed /etc/resolv.conf"
      machine.succeed("test -f /etc/resolv.tailscale.conf")

      # A daemon crash: Restart=on-failure brings it back, and the getter,
      # never stopped, is still there to serve it.
      machine.succeed("systemctl kill -s KILL tailscaled-inbox.service")
      machine.wait_until_succeeds(
          "systemctl show -p NRestarts --value tailscaled-inbox.service"
          " | grep -qx 1"
      )
      machine.wait_for_unit("tailscaled-inbox.service")
      machine.wait_until_succeeds(f"{inbox} {logged_out}")
      machine.succeed("systemctl is-active taildrop-inbox.service")

      # Starting the getter alone pulls the daemon in (fresh boot ordering).
      machine.succeed("systemctl stop taildrop-inbox.service tailscaled-inbox.service")
      machine.succeed("systemctl start taildrop-inbox.service")
      machine.wait_for_unit("tailscaled-inbox.service")
    '';
  };
}
