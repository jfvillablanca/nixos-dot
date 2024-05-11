{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./hardware-configuration-overrides.nix

    ../../nixosModules/system/kmonad
    ../../nixosModules/system/internationalization
    ../../nixosModules/system/virtual-fs
    ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/timezone
    ../../nixosModules/system/fonts
    ../../nixosModules/system/sound
  ];

  myNixosModules = {
    steam.enable = true;
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

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
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
      vim
      git
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
