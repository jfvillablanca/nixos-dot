# TODO: 
# - Organize placement of kmonad module

{ config, pkgs, isWayland, user, projectRoot, hostName, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./extras.nix
      "${projectRoot}/modules/kmonad/nixos-modules.nix"
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.hostName = hostName; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Manila";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Doas
  security.doas.enable = true;

  # Enable window manager
  services = {
    xserver = {
      enable = true;
      displayManager = {
        gdm = {
          enable = isWayland;
          wayland = isWayland;
        };
        lightdm.enable = !isWayland;
      };
      windowManager = {
        xmonad = {
          enable = false;
          enableContribAndExtras = false;
        };
        i3 = {
          enable = !isWayland;
        };
      };
    };
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
    # xkbOptions = "compose:ralt";
  };

  # Touchpad
  services.xserver = {
    libinput = {
      enable = true;
      mouse = {
        naturalScrolling = true;
        tapping = true;
      };
      touchpad = {
        naturalScrolling = true;
        tapping = true;
      };
    };
  };

  services.kmonad = {
    enable = true;
    package = import "${projectRoot}/modules/kmonad/kmonad-pkg.nix" { inherit pkgs; };
    extraArgs = [ "--log-level" "debug" ];
    keyboards = {
      "laptop" = {
        defcfg = {
          enable = true;
          compose.key = null;
          fallthrough = false;
          allowCommands = false;
        };

        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";
        config = builtins.readFile "${projectRoot}/modules/kmonad/kbd/thinkpad-t14.kbd";
      };
      "keychron-k2" = {
        defcfg = {
          enable = true;
          compose.key = null;
          fallthrough = false;
          allowCommands = false;
        };

        device = "/dev/input/by-id/usb-Keychron_Keychron_K2-event-kbd";
        config = builtins.readFile "${projectRoot}/modules/kmonad/kbd/keychron-k2.kbd";
      };
    };
  };

  # Polkit (need enabled for sway)
  security.polkit.enable = true;

  # Power Management Daemon 
  services.tlp = {
    enable = true;
    settings = {
      # Values for "always plugged"
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 50;
      # Values for "unplugged all the time"
      # START_CHARGE_THRESH_BAT0 = 85;
      # STOP_CHARGE_THRESH_BAT0 = 90;
    };
  };

  # Fonts
  fonts.fonts = with pkgs; [
    source-code-pro
    font-awesome
    corefonts
    jetbrains-mono
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "IBMPlexMono"
        "JetBrainsMono"
      ];
    })
  ];

  users.users.${user} = {
    isNormalUser = true;
    description = "jmfv";
    extraGroups = [
      "networkmanager"
      "wheel"
      "uinput"
      "input"
      "sound"
      "audio"
      "video"
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      wget
    ];
  };
  # NixOs Configuration
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
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
