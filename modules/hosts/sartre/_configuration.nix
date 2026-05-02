{
  inputs,
  pkgs,
  lib,
  user,
  base16Scheme,
  ...
}: {
  imports = [
    # ./_hardware-configuration.nix
    # ./_disko.nix

    inputs.self.modules.nixos.internationalization
    # inputs.self.modules.nixos.virtual-fs
    # inputs.self.modules.nixos.network-manager
    inputs.self.modules.nixos.nix
    inputs.self.modules.nixos.timezone
    inputs.self.modules.nixos.fonts
    # inputs.self.modules.nixos.sound
    # inputs.self.modules.nixos.bluetooth
    inputs.self.modules.nixos.steam
  ];

  stylix = {
    enable = true;
    # NOTE: unfortunately, stylix.image is non-optional
    # https://github.com/danth/stylix/issues/200
    image = ../../home/wallpapers/samuraidoge.png;
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

  virtualisation = {
    docker = {
      enable = true;
    };
  };

  wsl = {
    enable = true;
    defaultUser = user;
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

  users.users.${user} = {
    # HACK:
    # first user of NixOS-WSL is "nixos" which currently uses UID 1000
    uid = lib.mkForce 1001;
  };
}
