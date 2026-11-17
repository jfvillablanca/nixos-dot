# Taildrop inbox: a second tailscaled on this host, in userspace-networking
# mode and logged in as the human user, so personal devices can Taildrop files
# here even though the host's own node is tagged. Taildrop only targets nodes
# owned by the same user (feature/taildrop/ext.go:349-361), and the policy
# editor refuses the peer caps that would lift that for a tag -- see
# docs/taildrop-inbox.md. A getter loop files arrivals into `dir`. The main
# tailscaled is untouched.
#
# Citations are to the tailscale source at v1.102.2, the version installed
# fleet-wide. Five requirements shape this Aspect:
#
# 1. Non-root. tailscaled runs dns.CleanUp at startup even in userspace mode
#    (cmd/tailscaled/tailscaled.go:517, net/dns/manager.go:677-692). As root
#    that teardown could remove the main instance's resolver config; as the
#    user it fails harmlessly. Running as the user also gives the CLI write
#    access without --operator, because the caller's uid matches the
#    daemon's (ipn/ipnauth/ipnauth.go:191-193).
# 2. --statedir, never --state. A --state path whose directory is not named
#    `tailscale` leaves VarRoot unset, which silently disables Taildrop
#    (cmd/tailscaled/tailscaled.go:374-407, feature/taildrop/ext.go:196-199).
#    Logs follow $STATE_DIRECTORY into the same place
#    (logpolicy/logpolicy.go:210-285).
# 3. The main instance must not use an exit node or accept routes that
#    overlap the LAN or peer endpoints. This daemon's sockets carry no fwmark
#    (net/netns/netns.go:94,121), so they are routed by the main instance's
#    table 52 (wgengine/router/osrouter/router_linux.go:1623-1625).
#    Advertising an exit node or subnets is fine, and nixpkgs'
#    `useRoutingFeatures` only sets sysctls and rp_filter
#    (nixos/modules/services/networking/tailscale.nix:252-261 at nixpkgs
#    a831408) -- it adds no --accept-routes.
# 4. Control side, not verifiable from client source: an interactive,
#    untagged login yields a user-owned node carrying the file-sharing node
#    cap, like any personal device. Confirmed once, at bootstrap.
# 5. Shields up. In userspace-networking mode netstack owns the node's own
#    Tailscale IP (cmd/tailscaled/netstack.go:41) and forwards any inbound
#    connection it has no handler for to the same port on 127.0.0.1
#    (wgengine/netstack/netstack.go:1697-1698,1747-1752; UDP likewise,
#    2038-2040) -- handing every peer that can reach this node the host's
#    loopback-only services. The kernel-mode main daemon never does that.
#    Shields up installs a packet filter with no accept rules
#    (ipn/ipnlocal/local.go:3469-3471, wgengine/filter/filter.go:204-216)
#    that drops new inbound flows before netstack sees them
#    (net/tstun/wrap.go:1163,1176-1204; netstack.go:443), except SYNs to
#    the peerapi port, whose ACLs -- Taildrop's included -- are enforced at
#    L7 (net/tstun/wrap.go:1165-1174, feature/taildrop/peerapi.go:30-37).
#    No Taildrop path consults it (feature/taildrop/ext.go:334-375). The
#    daemon re-applies it after every start, and the interactive login must
#    pass `--shields-up` as well: the first `up` replaces prefs wholesale
#    without the usual "mention all non-default flags" check
#    (cmd/tailscale/cli/up.go:684-686,1011-1014).
{
  flake.modules.nixos.taildrop-inbox = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.myNixosModules.taildropInbox;
    pkg = config.services.tailscale.package;
    inherit (config.users.users.${cfg.user}) group;
    name = "tailscale-inbox";
    stateDir = "/var/lib/${name}";
    socket = "/run/${name}/tailscaled.sock";

    # The stock CLI pointed at this daemon instead of the main one:
    # `tailscale-inbox up --hostname=rue-inbox --shields-up` once to log in
    # (requirement 5), `tailscale-inbox status` after that.
    inboxCli = pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [pkg];
      text = ''
        exec tailscale --socket=${socket} "$@"
      '';
    };
  in {
    options.myNixosModules.taildropInbox = {
      enable =
        lib.mkEnableOption "a second, userspace Tailscale node that receives Taildrop files into a directory"
        // {default = false;};

      user = lib.mkOption {
        type = lib.types.str;
        default = config.systemConstants.user;
        defaultText = lib.literalExpression "config.systemConstants.user";
        description = ''
          Account both units run as. The inbox node logs in with this user's
          tailnet identity, so it must be the person whose devices send to it
          -- and never root (see the Aspect's header).
        '';
      };

      dir = lib.mkOption {
        type = lib.types.str;
        default = "/home/${cfg.user}/Inbox";
        defaultText = lib.literalExpression ''"/home/''${config.myNixosModules.taildropInbox.user}/Inbox"'';
        description = ''
          Where received files land, owned by `user`. Created at boot but not
          persisted by this Aspect: on an ephemeral-root host, persist it
          through the user's home-manager persistence list, not the system
          one (see the Aspect's tmpfiles comment for why).
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.user != "root";
          message = ''
            myNixosModules.taildropInbox.user must not be root: tailscaled's
            startup DNS cleanup would run with root's access and could tear
            down the main instance's resolver config.
          '';
        }
      ];

      environment.systemPackages = [inboxCli];

      systemd.services.tailscaled-inbox = {
        description = "Userspace Tailscale node that receives Taildrop files";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          User = cfg.user;
          Group = group;
          # Its own socket and --port=0 keep it clear of the main daemon's
          # /run/tailscale and 41641; tailscaled holds no other global lock
          # (safesocket/unixsocket.go:35-41).
          ExecStart = "${pkg}/bin/tailscaled --tun=userspace-networking --statedir=${stateDir} --socket=${socket} --port=0";
          # Requirement 5, on every start, so a stray `set` or `up` cannot
          # leave the node open past a restart. tailscaled signals READY
          # once its LocalAPI listens (ipn/ipnserver/server.go:529-531), and
          # requests made before the backend is up wait for it
          # (ipn/ipnserver/server.go:99-118). If this fails, systemd stops
          # the daemon: the node goes offline rather than open.
          Type = "notify";
          ExecStartPost = "${pkg}/bin/tailscale --socket=${socket} set --shields-up";
          # Also implies RequiresMountsFor= on the persisted bind mount, and
          # re-chowns it to User= if the backing copy was created as root.
          StateDirectory = name;
          StateDirectoryMode = "0700";
          # The socket itself is world-writable (safesocket/unixsocket.go:45,
          # 69,85-88), and any local user would get read access through it;
          # the directory keeps them out.
          RuntimeDirectory = name;
          RuntimeDirectoryMode = "0700";
          NoNewPrivileges = true;
          PrivateTmp = true;
          Restart = "on-failure";
          # systemd's 100ms default would burn through the start limit (5
          # starts in 10s) on a persistent fault and leave the daemon dead
          # while the getter keeps polling it.
          RestartSec = "5s";
        };
      };

      systemd.services.taildrop-inbox = {
        description = "Move received Taildrop files into ${cfg.dir}";
        # Wants=, not BindsTo=: the loop already rides out the daemon being
        # down, while BindsTo= would stop the getter whenever the daemon
        # crashes and leave it stopped after Restart= brings the daemon back.
        wants = ["tailscaled-inbox.service"];
        after = ["tailscaled-inbox.service"];
        wantedBy = ["multi-user.target"];
        # Where `dir` is a bind mount, a file written before the mount is up
        # would land on the ephemeral root and vanish behind it.
        unitConfig.RequiresMountsFor = cfg.dir;
        serviceConfig = {
          User = cfg.user;
          Group = group;
          # Retries every 5s while the daemon is down or logged out; exits only
          # when `dir` is missing or not a directory
          # (cmd/tailscale/cli/file.go:774-795).
          ExecStart = "${pkg}/bin/tailscale --socket=${socket} file get --loop --conflict=rename ${cfg.dir}";
          Restart = "always";
          RestartSec = "5s";
        };
      };

      # Holds the node's login and any files not yet picked up; without it the
      # ephemeral-root wipe logs the node out on every boot.
      myNixosModules.persistence.directories = [
        {
          directory = stateDir;
          inherit (cfg) user;
          inherit group;
          mode = "0700";
        }
      ];

      # `dir` must exist before the getter starts. It is deliberately not in
      # the system persistence list above: for an entry under /home/<user>,
      # impermanence also creates the live /home/<user> as a parent and
      # copies owner and mode onto it from the persisted copy
      # (create-directories.bash:55-60 at impermanence 7b1d382), which is
      # root:root 0755 under /persist/system -- that would hand the user's
      # home to root. Home-manager persistence treats the home directory as
      # the permission boundary instead.
      systemd.tmpfiles.rules = ["d ${cfg.dir} 0700 ${cfg.user} ${group} -"];
    };
  };
}
