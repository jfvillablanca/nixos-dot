{
  inputs,
  pkgs,
  lib,
  user,
  base16Scheme,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix

    ../../nixosModules/system/internationalization
    ../../nixosModules/system/virtual-fs
    ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/timezone
    ../../nixosModules/system/fonts
    ../../nixosModules/system/sound
    ../../nixosModules/system/bluetooth
  ];

  stylix = {
    enable = true;
    # NOTE: unfortunately, stylix.image is non-optional
    # https://github.com/danth/stylix/issues/200
    image = ../../homeModules/system/wallpapers/samuraidoge.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";
    polarity = "dark";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
    };
    fonts = {
      monospace = {
        package = pkgs.nerdfonts.override {fonts = ["JetBrainsMono"];};
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
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.postDeviceCommands = lib.mkAfter ''
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

  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
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

  users.users.${user} = {
    initialPassword = "12345";
  };

  # Enable window manager
  services = {
    xserver = {
      enable = true;
      displayManager = {
        gdm.enable = true;
      };
      windowManager = {
        i3.enable = true;
      };
    };
  };

  programs = {
    fuse.userAllowOther = true;

    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
  };

  # Polkit (need enabled for sway)
  security.polkit.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment = {
  #   # Disable DPMS and prevent screen from blanking
  #   extraInit = ''
  #     xset s off -dpms
  #   '';
  #   systemPackages = with pkgs; [
  #     wget
  #   ];
  # };
}
