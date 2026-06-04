{
  flake.modules.nixos.openssh = {
    lib,
    config,
    ...
  }: let
    cfg = config.myNixosModules.openssh;
  in {
    options.myNixosModules.openssh = {
      enable =
        lib.mkEnableOption "OpenSSH server"
        // {default = false;};

      x11Forwarding = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Permit X11 forwarding (`ssh -X`/`-Y`). Needed when running
          remote GUI tools tunnelled through this host's sshd.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.openssh = {
        enable = true;
        settings.X11Forwarding = cfg.x11Forwarding;
      };

      # Without persistence the keys regenerate every boot on an
      # ephemeral root, which invalidates the entry the rest of the
      # fleet pinned via `flake.hostIdentityKeys.<host>`.
      myNixosModules.persistence.files = [
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };
  };
}
