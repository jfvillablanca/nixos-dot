# Periodic git snapshot of the Obsidian vault into a private remote.
#
# This is the backup half of the vault story; `modules/services/obsidian-sync`
# is the replication half. They solve different problems: LiveSync keeps the
# phone, sienna and rue's CouchDB in step within seconds, which means it also
# replicates a deletion within seconds. This Aspect is what makes that
# recoverable, by keeping history the replicas do not.
#
# Polling, not a watcher. `git status` over the vault costs 0.02s, so there is
# nothing to optimise, and `launchd`'s own WatchPaths is documented as
# "highly discouraged ... entirely possible for modifications to be missed".
{
  flake.modules.homeManager.obsidian-backup = {
    lib,
    pkgs,
    config,
    ...
  }: let
    cfg = config.myHomeModules.obsidian-backup;

    # home-manager labels its agents org.nix-community.home.<name>. Mirrored
    # here so `obsidian-backup status` can say whether the agent is actually
    # loaded. Display only: if this ever drifts, status reports "NOT loaded"
    # and backups carry on regardless.
    agentLabel = "org.nix-community.home.obsidian-backup";

    backup = pkgs.writeShellApplication {
      name = "obsidian-backup";
      # Deliberately NO openssh. writeShellApplication prepends these to PATH
      # rather than replacing it (`inheritPath` defaults to true), and the
      # agent's PATH already carries /usr/bin, so `git push` finds Apple's ssh
      # -- the same one every other git operation on this machine uses.
      #
      # Pinning nixpkgs' openssh ahead of it made every push print
      #   ~/.colima/ssh_config line 13: Unsupported option "gssapiauthentication"
      # because colima writes GSSAPIAuthentication into the config that
      # ~/.ssh/config includes, Apple's ssh is built with GSSAPI and accepts
      # it, and nixpkgs' is not. Harmless, but it landed in the error log on
      # every push, and that log is the only signal that this unattended job
      # has started failing. A channel that cries wolf 48 times a day is not a
      # signal.
      runtimeInputs = [pkgs.git pkgs.coreutils];
      # Defaults from this module, so the command is usable when typed in a
      # shell -- launchd supplies an environment, an interactive shell does
      # not. The environment still wins, which is what keeps _backup.sh
      # testable standalone against a throwaway repo.
      text = ''
        : "''${OBSIDIAN_BACKUP_VAULT:=${cfg.vaultPath}}"
        : "''${OBSIDIAN_BACKUP_REMOTE:=${cfg.remote}}"
        : "''${OBSIDIAN_BACKUP_MAX_MB:=${toString cfg.maxFileSizeMB}}"
        : "''${OBSIDIAN_BACKUP_LABEL:=${agentLabel}}"
        export OBSIDIAN_BACKUP_VAULT OBSIDIAN_BACKUP_REMOTE OBSIDIAN_BACKUP_MAX_MB OBSIDIAN_BACKUP_LABEL

        ${builtins.readFile ./_backup.sh}
      '';
    };
  in {
    options.myHomeModules.obsidian-backup = {
      enable =
        lib.mkEnableOption "periodic git backup of the Obsidian vault"
        // {default = false;};

      vaultPath = lib.mkOption {
        type = lib.types.str;
        example = "/Users/you/Documents/Obsidian Vault";
        description = ''
          Path to the vault's git work tree.

          A quoted string, never a Nix path literal: a literal would copy the
          entire vault -- 249 MB, mostly untracked sourcebook corpus -- into
          the world-readable Nix store on every evaluation. Same convention as
          sops.age.keyFile and the tailscale Aspect's authKeyFile.

          Deliberately has no default. A default would bake in an absolute path
          containing a username; the host that owns a vault names its own.
        '';
      };

      intervalSeconds = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1800;
        description = ''
          Seconds between snapshots. Thirty minutes bounds how much *new* work
          is unarchived; it does not bound what is recoverable, since history
          keeps everything already committed.
        '';
      };

      maxFileSizeMB = lib.mkOption {
        type = lib.types.ints.positive;
        default = 50;
        description = ''
          Per-file ceiling. Matches GitHub's 50 MiB warning threshold (it hard
          blocks at 100 MiB). This is the guard that stands in for Git LFS:
          LFS would not stop a large file poisoning history, and git history is
          permanent, so the file has to be refused before it is committed.
        '';
      };

      remote = lib.mkOption {
        type = lib.types.str;
        default = "origin";
        description = "Git remote to push snapshots to.";
      };
    };

    config = lib.mkIf cfg.enable {
      home.packages = [backup];

      launchd.agents.obsidian-backup = {
        enable = true;
        config = {
          # Explicitly "run": a bare invocation prints status, which is the
          # friendlier default for a human but would do nothing on a timer.
          ProgramArguments = ["${backup}/bin/obsidian-backup" "run"];
          EnvironmentVariables = {
            # launchd agents start with a bare environment, and the wrapper
            # expands "$PATH" under `set -o nounset` before a line of the
            # script runs -- an unset PATH would abort it with no output at
            # all. Same reason the colima agent pins one.
            PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
            OBSIDIAN_BACKUP_VAULT = cfg.vaultPath;
            OBSIDIAN_BACKUP_REMOTE = cfg.remote;
            OBSIDIAN_BACKUP_MAX_MB = toString cfg.maxFileSizeMB;
            OBSIDIAN_BACKUP_LABEL = agentLabel;
          };
          StartInterval = cfg.intervalSeconds;
          # Catch anything pending at login or right after a rebuild, rather
          # than waiting out a full interval.
          RunAtLoad = true;
          # ~/Library/Logs, not /tmp: this is the only signal that an
          # unattended job has been failing, and /tmp is world-readable and
          # cleared on reboot. Follows the colima agent, the repo's other
          # long-lived launchd service; the /tmp convention belongs to the
          # desktop aspects, which log throwaway state.
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/obsidian-backup.out.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/obsidian-backup.err.log";
        };
      };
    };
  };
}
