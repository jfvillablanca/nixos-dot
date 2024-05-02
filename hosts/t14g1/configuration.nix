{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix

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

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
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

  # Touchpad
  services.xserver = {
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
