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

    backup = pkgs.writeShellApplication {
      name = "obsidian-backup";
      # openssh is not optional. writeShellApplication pins PATH to exactly
      # these inputs, and `git push` over an ssh remote forks `ssh` by name --
      # without it the push dies with "cannot run ssh: No such file or
      # directory" while every local step still succeeds, so the job would
      # commit forever and never publish anything.
      runtimeInputs = [pkgs.git pkgs.openssh pkgs.coreutils];
      text = builtins.readFile ./_backup.sh;
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
          ProgramArguments = ["${backup}/bin/obsidian-backup"];
          EnvironmentVariables = {
            OBSIDIAN_BACKUP_VAULT = cfg.vaultPath;
            OBSIDIAN_BACKUP_REMOTE = cfg.remote;
            OBSIDIAN_BACKUP_MAX_MB = toString cfg.maxFileSizeMB;
          };
          StartInterval = cfg.intervalSeconds;
          # Catch anything pending at login or right after a rebuild, rather
          # than waiting out a full interval.
          RunAtLoad = true;
          StandardOutPath = "/tmp/obsidian-backup.out.log";
          StandardErrorPath = "/tmp/obsidian-backup.err.log";
        };
      };
    };
  };
}
