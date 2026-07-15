# rue -- Dell OptiPlex 3050, headless always-on homelab host. Netboot-
# installed from cimmerian, reached over Tailscale SSH. XFCE + Sunshine so
# Moonlight clients can land in a desktop on demand. Btrfs ephemeral root +
# impermanence like the rest of the fleet; durable state (incl. the
# Tailscale auth key at /persist/secrets) lives on the /persist subvol.
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
  base16Scheme = "gruvbox-dark-hard";
in {
  flake.modules.nixos.${hostName} = {
    config,
    lib,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      ./_hardware-configuration.nix
      ./_disko.nix

      self.modules.nixos.user
      self.modules.nixos.system-desktop
      self.modules.nixos.doas
      self.modules.nixos.tailscale
      self.modules.nixos.sunshine
      self.modules.nixos.xfce
    ];

    networking.hostName = hostName;

    users.users.${user}.initialPassword = "12345";

    # Fresh 2026 install -- set to the release you install from; verify with
    # `nixos-version` on the RAM installer (Task 9). Do NOT copy t14g1's 22.11.
    system.stateVersion = "26.05";

    stylix = {
      enable = true;
      image = null;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";
      polarity = "dark";
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Original-Ice";
        size = 24;
      };
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
      };
    };

    myNixosModules = {
      tailscale = {
        enable = true;
        enableSSH = true;
        # Delivered out-of-band by nixos-anywhere --extra-files (Task 9) onto
        # the /persist subvol so it survives the first-boot root wipe. Quoted
        # string, NOT a path literal.
        authKeyFile = "/persist/secrets/tailscale-authkey";
      };
      sunshine.enable = true;
      xfce = {
        enable = true;
        autoLoginUser = user;
      };
      persistence = {
        enable = true;
        userHomes = [{inherit user;}];
      };
    };

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;

      consoleLogLevel = 3;
      kernelParams = ["quiet" "udev.log_level=3"];
      initrd.verbose = false;

      # Scripted stage-1 so boot.initrd.postDeviceCommands (the btrfs
      # ephemeral-root wipe) works; systemd stage-1 does not support it.
      initrd.systemd.enable = lib.mkForce false;
      initrd.postDeviceCommands = lib.mkAfter ''
        mkdir /btrfs_tmp
        mount /dev/root_vg/root /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
            delete_subvolume_recursively "$i"
        done

        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
      '';
    };

    fileSystems."/persist".neededForBoot = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [wget];

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
        inherit user base16Scheme;
        system = "x86_64-linux";
      };
      users.${user}.imports = [
        self.modules.homeManager.user
        ./_home.nix
      ];
    };
  };

  flake.nixosConfigurations.${hostName} = self.lib.mkNixos hostName;
}
