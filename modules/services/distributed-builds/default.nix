# Delegate Nix builds to a remote builder over SSH.
#
# The builder side has no module of its own: any host in this fleet
# already accepts incoming submissions because `modules/system/nix`
# adds the user to `nix.settings.trusted-users` and openssh is on
# everywhere. Hosts that want to *delegate outgoing* builds opt in
# here.
#
# Prerequisite: nix-daemon runs as root, so the user's personal SSH
# key cannot be reused. Generate a dedicated root key once with
#   sudo ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N "" \
#                   -C "<host> root build key"
# and advertise the public half via `flake.publicKeys.<host>-root`
# so the existing aggregator authorizes it on every builder.
{
  flake.modules.nixos.distributed-builds = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.distributedBuilds;
  in {
    options.myNixosModules.distributedBuilds = {
      enable =
        lib.mkEnableOption "delegating nix builds to a remote builder"
        // {default = false;};

      builderHostName = lib.mkOption {
        type = lib.types.str;
        default = "cimmerian";
        description = "MagicDNS-resolvable hostname of the remote builder.";
      };

      sshUser = lib.mkOption {
        type = lib.types.str;
        default = config.systemConstants.user;
        defaultText = lib.literalExpression "config.systemConstants.user";
        description = ''
          User on the remote that owns nix-daemon trust. Must be in
          the builder's `nix.settings.trusted-users`.
        '';
      };

      sshKey = lib.mkOption {
        type = lib.types.str;
        default = "/root/.ssh/id_ed25519";
        description = ''
          Path to the root-readable SSH private key used to reach
          the builder. nix-daemon runs as root and cannot read the
          user's `~/.ssh/id_ed25519`; generate a dedicated key —
          see the module header.
        '';
      };

      protocol = lib.mkOption {
        type = lib.types.enum ["ssh" "ssh-ng"];
        default = "ssh-ng";
        description = ''
          ssh-ng is the modern protocol with content-addressed
          transfers and structured logs. Falls back to plain ssh
          only when one side runs an old Nix.
        '';
      };

      maxJobs = lib.mkOption {
        type = lib.types.int;
        default = 8;
        description = "Concurrent builds the remote may run on our behalf.";
      };

      speedFactor = lib.mkOption {
        type = lib.types.int;
        default = 2;
        description = ''
          Relative speed vs the local builder. >1 prefers the
          remote; <1 prefers local. Defaults to 2 since the
          workstation's thermal envelope dominates the laptop's.
        '';
      };

      supportedFeatures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = ["kvm" "big-parallel" "nixos-test" "benchmark"];
        description = ''
          Build features the remote can satisfy. Match what the
          builder actually supports — derivations whose
          `requiredSystemFeatures` aren't covered fall back to
          local.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;
      nix.buildMachines = [
        {
          inherit (cfg) sshUser sshKey protocol maxJobs speedFactor supportedFeatures;
          hostName = cfg.builderHostName;
          systems = ["x86_64-linux"];
        }
      ];

      myNixosModules.persistence = {
        directories = [
          {
            directory = "/root/.ssh";
            mode = "0700";
          }
        ];
        # /root needs 0700 even though we only bind-mount /root/.ssh;
        # default 0755 on the persisted parent would leak the dir's
        # name even if its contents are unreadable.
        parentTmpfiles = [
          {
            directory = "/root";
            mode = "0700";
          }
        ];
      };
    };
  };
}
