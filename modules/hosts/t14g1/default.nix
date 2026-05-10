# t14g1 — ThinkPad T14 Gen 1 laptop, Hyprland-first.
{
  inputs,
  self,
  ...
}: let
  user = "jmfv";
  base16Scheme = "gruvbox-dark-hard";
in {
  flake-file.inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  flake.modules.nixos.t14g1 = {
    lib,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: {
    imports = [
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1

      ./_hardware-configuration.nix
      ./_disko.nix

      self.modules.nixos.jmfv
      self.modules.nixos.system-desktop
      self.modules.nixos.steam
      self.modules.nixos.laptop-power-management
      self.modules.nixos.doas
      self.modules.nixos.tailscale
      self.modules.nixos.distributed-builds
    ];

    networking.hostName = "t14g1";

    users.users.${user}.initialPassword = "12345";

    # Don't touch me :)
    system.stateVersion = "22.11";

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
      targets = {
        gnome.enable = true;
      };
    };

    myNixosModules = {
      steam.enable = false;
      tailscale.enable = true;
      distributedBuilds.enable = true;
    };

    boot = {
      # Use the systemd-boot EFI boot loader.
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
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
    environment.persistence."/persist/system" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/tailscale"
        "/etc/NetworkManager/system-connections"
        "/root/.ssh"
      ];
      files = [
        "/etc/machine-id"
        # { file = "/var/keys/secret_file"; parentDirectory = { mode = "u=rwx,g=,o="; }; }
      ];
    };

    systemd.tmpfiles.rules = [
      "d /persist/system 0755 root root -"
      "d /persist/system/var 0755 root root -"
      "d /persist/system/var/log 0755 root root -"
      "d /persist/system/var/lib 0755 root root -"
      "d /persist/system/var/lib/nixos 0755 root root -"
      "d /persist/system/var/lib/systemd 0755 root root -"
      "d /persist/system/var/lib/systemd/coredump 0755 root root -"
      "d /persist/system/var/lib/tailscale 0700 root root -"
      "d /persist/system/root 0700 root root -"
      "d /persist/system/root/.ssh 0700 root root -"
      "d /persist/system/etc 0755 root root -"
      "d /persist/system/etc/NetworkManager 0755 root root -"
      "d /persist/system/etc/NetworkManager/system-connections 0755 root root -"
      "d /persist/home 0755 root root -"
      "d /persist/home/${user} 0770 ${user} users -"
    ];

    systemd.services."set-persisted-home-ownership" = {
      description = "Set ownership of /persist/home to user";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/chown -R ${user}:users /persist/home/${user}";
        RemainAfterExit = true;
      };
    };

    # Enable window manager
    services = {
      displayManager = {
        gdm.enable = true;
      };
      xserver = {
        enable = true;
        windowManager = {
          i3.enable = true;
        };
      };
      libinput = {
        enable = true;
        mouse = {
          tapping = true;
        };
        touchpad = {
          naturalScrolling = true;
          tapping = true;
        };
      };
      openssh = {
        enable = true;
        settings = {
          X11Forwarding = true;
        };
      };
      actkbd = {
        enable = true;
        bindings = [
          {
            keys = [224];
            events = ["key"];
            command = "/run/current-system/sw/bin/light -U 10";
          }
          {
            keys = [225];
            events = ["key"];
            command = "/run/current-system/sw/bin/light -A 10";
          }
        ];
      };
    };

    programs = {
      fuse.userAllowOther = true;

      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      };

      # Screen Brightness
      light.enable = true;
    };

    # Polkit (need enabled for sway)
    security.polkit.enable = true;

    virtualisation.docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    users.extraGroups.docker.members = ["username-with-access-to-socket"];

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment = {
      # Disable DPMS and prevent screen from blanking
      extraInit = ''
        xset s off -dpms
      '';
      systemPackages = with pkgs; [
        wget
      ];
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
        inherit user base16Scheme;
        system = "x86_64-linux";
      };
      users.${user}.imports = [
        self.modules.homeManager.jmfv
        ./_home.nix
      ];
    };
  };

  flake.nixosConfigurations.t14g1 = self.lib.mkNixos "t14g1";

  flake.publicKeys.t14g1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFAAQv0TTQr9OUABswhWE6bQf+YcRkvRQHUigK7JsGUS jmfv.dev@gmail.com";
  flake.publicKeys.t14g1-root = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPWKj8zIYP0LgZmik2Fu6JfgIvTmmYCndBseqPUOVgrY t14g1 root build key";

  flake.hostIdentityKeys.t14g1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnmnhUtaRg/b++aKL5pnYhsf4Nehapm/wnOoiIu+JNZ root@t14g1";
}
