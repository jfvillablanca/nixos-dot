# cimmerian — desktop machine, Xorg + i3.
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
  base16Scheme = "spaceduck";
in {
  flake.modules.nixos.${hostName} = {
    config,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      ./_hardware-configuration.nix
      ./_hardware-configuration-overrides.nix

      # inputs.self.modules.nixos.kmonad
      self.modules.nixos.user
      self.modules.nixos.system-desktop
      self.modules.nixos.steam
      self.modules.nixos.tailscale
      self.modules.nixos.docker
    ];

    networking.hostName = hostName;

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
      tailscale.enable = true;
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

    # Pin the 6.12 LTS kernel. amdgpu in 6.18.x regressed rotated scanout
    # on this Cezanne/Renoir-class APU (DCN 2.1): the left HDMI-1 output
    # set to `rotate left` bleeds across into DP-1 instead of scanning out
    # rotated. 6.12 (the 25.11 kernel) drove this layout correctly. Drop
    # the pin once a 6.18.x point release / the 6.19 amdgpu reverts land.
    # https://community.frame.work/t/attn-critical-bugs-in-amdgpu-driver-included-with-kernel-6-18-x-6-19-x/79221
    boot.kernelPackages = pkgs.linuxPackages_6_12;

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
        # GDM 50's Wayland greeter launches X11 sessions but leaves
        # XDG_SESSION_TYPE=wayland, so chromium/electron ozone auto-detect
        # picks the absent Wayland backend and fails to start. Correct the
        # type for the i3 session and everything it spawns.
        displayManager.sessionCommands = ''
          export XDG_SESSION_TYPE=x11
        '';
      };
      openssh = {
        enable = true;
        settings.X11Forwarding = true;
      };
      gnome.gnome-keyring.enable = true;
    };

    programs = {
      nix-ld.enable = true;
    };

    # Link portal dirs for HM's xdg.portal (was implicit via programs.hyprland).
    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment = {
      # Disable DPMS and prevent screen from blanking. Guarded
      # because environment.extraInit fires in every shell — over
      # plain ssh DISPLAY is unset, and over ssh -X it points at a
      # forwarded X server that may not implement DPMS.
      extraInit = ''
        if [ -n "$DISPLAY" ]; then
          xset s off -dpms 2>/dev/null || true
        fi
      '';
      systemPackages = with pkgs; [
        vim
        git
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
        self.modules.homeManager.user
        ./_home.nix
      ];
    };
  };

  flake.nixosConfigurations.${hostName} = self.lib.mkNixos hostName;

  flake.publicKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBSS3Q5D0saZcnpIbtEdLpdb0OWZdOEIXgxeDppVM2M jmfv.dev@gmail.com";

  flake.hostIdentityKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVQsv1En2SX2P0Tp+hQ+Cl9m1R50PTvCn145k6iRV0b root@cimmerian";
}
