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
      gnome.enable = false;
    };
  };

  myNixosModules = {
    steam.enable = false;
  };


  # Enable window manager
  services = {
    xserver.enable = false;
    displayManager = {
      sddm.enable = false;
    };
    desktopManager.plasma6.enable = false;
  };

  programs = {
    nix-ld.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  home-manager.backupFileExtension = "backup";
}
