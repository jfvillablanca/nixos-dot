{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

    ../../nixosModules/system/kmonad
    ../../nixosModules/system/doas
    ../../nixosModules/system/internationalization
    ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/spice-vda
    ../../nixosModules/system/timezone
    ../../nixosModules/system/fonts
  ];

  # Bootloader.
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    useOSProber = true;
  };

  # Enable window manager
  services = {
    xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
      };
      windowManager = {
        i3 = {
          enable = true;
        };
      };
    };
  };

  # Polkit (need enabled for sway)
  security.polkit.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      wget
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
