{
  inputs,
  pkgs,
  base16Scheme,
  user,
  system,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./hardware-configuration-overrides.nix

    # ../../nixosModules/system/kmonad
    ../../nixosModules/system/internationalization
    ../../nixosModules/system/virtual-fs
    ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/timezone
    ../../nixosModules/system/fonts
    ../../nixosModules/system/sound
  ];

  stylix = {
    enable = true;
    image = ../../homeModules/system/wallpapers/samuraidoge.png;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${base16Scheme}.yaml";
    polarity = "dark";
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
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
    steam.enable = true;
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  users.extraGroups.docker.members = ["username-with-access-to-socket"];

  virtualisation.virtualbox = {
    host = {
      enable = false;
      enableExtensionPack = true;
    };
  };
  users.extraGroups.vboxusers.members = [ "${user}" ];

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/boot/efi";
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
  };

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    nix-ld.enable = true;
  };

  services.gnome.gnome-keyring.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    # Disable DPMS and prevent screen from blanking
    extraInit = ''
      xset s off -dpms
    '';
    systemPackages = with pkgs;
      [
        vim
        git
      ]
      ++ [
        inputs.zen-browser.packages.${system}.default
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
