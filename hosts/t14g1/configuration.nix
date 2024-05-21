{
  inputs,
  pkgs,
  lib,
  user,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14-amd-gen1

    ./hardware-configuration.nix
    ./disko.nix

    ../../nixosModules/system/kmonad
    ../../nixosModules/system/doas
    ../../nixosModules/system/internationalization
    ../../nixosModules/system/virtual-fs
    ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/timezone
    ../../nixosModules/system/laptop-power-management
    ../../nixosModules/system/fonts
    ../../nixosModules/system/sound
  ];

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
    isNormalUser = true;
    initialPassword = "12345";
    extraGroups = ["wheel"];
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

  # Touchpad
  services.libinput = {
    enable = true;
    mouse = {
      tapping = true;
    };
    touchpad = {
      naturalScrolling = true;
      tapping = true;
    };
  };

  # Polkit (need enabled for sway)
  security.polkit.enable = true;

  # services.nextdns = {
  #   enable = true;
  # };

  # services.resolved = {
  #   enable = true;
  #   extraConfig = ''
  #     DNS=45.90.28.0#1273dc.dns.nextdns.io
  #     DNS=2a07:a8c0::#1273dc.dns.nextdns.io
  #     DNS=45.90.30.0#1273dc.dns.nextdns.io
  #     DNS=2a07:a8c1::#1273dc.dns.nextdns.io
  #     DNSOverTLS=yes
  #   '';
  # };

  virtualisation.docker.enable = true;

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

  # Screen Brightness
  programs.light.enable = true;
  services.actkbd = {
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
}
