# virt — QEMU virtual machine for testing.
{
  inputs,
  self,
  ...
}: let
  user = "jmfv";
  base16Scheme = "gruvbox-material-dark-medium";
in {
  flake.modules.nixos.virt = {
    config,
    pkgs,
    pkgs-master,
    pkgs-stable-24-05,
    pkgs-stable-25-05,
    ...
  }: {
    imports = [
      ./_hardware-configuration.nix

      self.modules.nixos.jmfv
      self.modules.nixos.system-cli
      self.modules.nixos.kmonad
      self.modules.nixos.doas
      self.modules.nixos.spice-vda
    ];

    networking.hostName = "virt";

    # Don't touch me :)
    system.stateVersion = "22.11";

    # Bootloader.
    boot.loader.grub = {
      enable = true;
      device = "/dev/vda";
      useOSProber = true;
    };

    # Enable window manager
    services = {
      xserver = {
        enable = true;
        displayManager = {
          lightdm.enable = true;
        };
        windowManager = {
          i3.enable = true;
        };
      };
    };

    # Polkit (need enabled for sway)
    security.polkit.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment = {
      pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];
      systemPackages = with pkgs; [
        wget
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

  flake.nixosConfigurations.virt = self.lib.mkNixos "virt";
}
