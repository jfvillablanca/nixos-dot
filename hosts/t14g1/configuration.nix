{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../../systems/kmonad
    ../../systems/doas.nix
    ../../systems/internationalization.nix
    ../../systems/virtual-fs.nix
    ../../systems/networkmanager.nix
    ../../systems/nixos-config.nix
    ../../systems/timezone.nix
    ../../systems/laptop-power-management.nix
    ../../systems/fonts.nix
    ../../systems/pipewire.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
      # options = "compose:ralt";
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

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
