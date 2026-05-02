# sartre — NixOS-WSL host (no display server, no hardware-configuration).
{
  inputs,
  self,
  ...
}: let
  user = "jmfv";
  base16Scheme = "rose-pine-moon";
in {
  flake.modules.nixos.sartre = {
    config,
    lib,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: {
    imports = [
      # ./_hardware-configuration.nix
      # ./_disko.nix

      self.modules.nixos.jmfv
      self.modules.nixos.system-default
      self.modules.nixos.steam
    ];

    networking.hostName = "sartre";

    # HACK:
    # first user of NixOS-WSL is "nixos" which currently uses UID 1000
    users.users.${user}.uid = lib.mkForce 1001;

    # Don't touch me :)
    system.stateVersion = "22.11";

    stylix = {
      enable = true;
      # NOTE: unfortunately, stylix.image is non-optional
      # https://github.com/danth/stylix/issues/200
      image = ../../desktop/wallpapers/samuraidoge.png;
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

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs pkgs pkgs-master pkgs-stable-24-05 pkgs-stable-25-05;
        inherit user base16Scheme;
        system = "x86_64-linux";
      };
      users.${user}.imports = [
        self.modules.homeManager.jmfv
        ./_home.nix
      ];
    };
  };

  flake.nixosConfigurations.sartre = self.lib.mkNixos "sartre";
}
