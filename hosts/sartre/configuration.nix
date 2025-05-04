{
  inputs,
  pkgs,
  lib,
  user,
  base16Scheme,
  ...
}: {
  imports = [
    # ./hardware-configuration.nix
    # ./disko.nix

    ../../nixosModules/system/internationalization
    # ../../nixosModules/system/virtual-fs
    # ../../nixosModules/system/network-manager
    ../../nixosModules/system/nix
    ../../nixosModules/system/timezone
    ../../nixosModules/system/fonts
    # ../../nixosModules/system/sound
    # ../../nixosModules/system/bluetooth
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
    steam.enable = false;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable window manager
  services = {
    xserver.enable = true;
    displayManager = {
      sddm.enable = true;
    };
    desktopManager.plasma6.enable = true;
  };

  programs = {
    nix-ld.enable = true;
  };

  # environment.gnome.excludePackages = with pkgs; [
  #   atomix # puzzle game
  #   cheese # webcam tool
  #   epiphany # web browser
  #   evince # document viewer
  #   geary # email reader
  #   gedit # text editor
  #   gnome-characters
  #   gnome-music
  #   gnome-photos
  #   gnome-terminal
  #   gnome-tour
  #   hitori # sudoku game
  #   iagno # go game
  #   tali # poker game
  #   totem # video player
  # ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    oxygen
  ];

  virtualisation.virtualbox = {
    guest = {
      enable = true;
      dragAndDrop = true;
      clipboard = true;
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

  home-manager.backupFileExtension = "backup";
}
