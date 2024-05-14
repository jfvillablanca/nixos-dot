{
  pkgs,
  lib,
  inputs,
  user,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix

    ../../nixosModules/system/doas
    ../../nixosModules/system/internationalization
    ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/spice-vda
    ../../nixosModules/system/timezone
    ../../nixosModules/system/fonts
  ];

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
    after = ["network.target"]; # Adjust dependencies as needed
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chown -R ${user}:users /persist/home/${user}";
      RemainAfterExit = true;
    };
  };

  programs.fuse.userAllowOther = true;

  users.users.${user} = {
    isNormalUser = true;
    initialPassword = "12345";
    extraGroups = ["wheel"];
  };

  # Enable window manager
  # services = {
  #   xserver = {
  #     enable = true;
  #     displayManager = {
  #       gdm.enable = true;
  #     };
  #     windowManager = {
  #       i3.enable = true;
  #     };
  #   };
  # };

  services = {
    xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
      displayManager = {
        gdm.enable = true;
      };
    };
    displayManager.defaultSession = "xfce";
  };

  programs.hyprland = {
    enable = false;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  nixpkgs.config.allowUnfree = true;
}
