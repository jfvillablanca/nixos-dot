# cimmerian — desktop machine, i3 + Hyprland (i3 active by default).
{
  inputs,
  self,
  ...
}: let
  user = "jmfv";
  base16Scheme = "spaceduck";
in {
  flake.modules.nixos.cimmerian = {
    config,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: {
    imports = [
      ./_hardware-configuration.nix
      ./_hardware-configuration-overrides.nix

      # inputs.self.modules.nixos.kmonad
      self.modules.nixos.jmfv
      self.modules.nixos.system-desktop
      self.modules.nixos.steam
    ];

    networking.hostName = "cimmerian";

    # Don't touch me :)
    system.stateVersion = "22.11";

    stylix = {
      enable = true;
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
    users.extraGroups.vboxusers.members = ["${user}"];

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
      openssh.enable = true;
      gnome.gnome-keyring.enable = true;
    };

    programs = {
      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      };
      nix-ld.enable = true;
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
      systemPackages = with pkgs;
        [
          vim
          git
        ]
        ++ [
          inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        ];
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
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

  flake.nixosConfigurations.cimmerian = self.lib.mkNixos "cimmerian";
}
