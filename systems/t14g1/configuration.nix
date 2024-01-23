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
      ../../modules/steam
      ../system-modules/doas.nix
      ../system-modules/internationalization.nix
      ../system-modules/virtual-fs.nix
      ../system-modules/networkmanager.nix
      ../system-modules/nixos-config.nix
      ../system-modules/timezone.nix
      ../system-modules/laptop-power-management.nix
      ../system-modules/fonts.nix
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



  virtualisation.docker.enable = true;

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
      "docker"
    ];
  };

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
