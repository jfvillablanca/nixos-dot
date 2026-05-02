{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./_hardware-configuration.nix

    inputs.self.modules.nixos.kmonad
    inputs.self.modules.nixos.doas
    inputs.self.modules.nixos.internationalization
    inputs.self.modules.nixos.network-manager
    inputs.self.modules.nixos.nix
    inputs.self.modules.nixos.spice-vda
    inputs.self.modules.nixos.timezone
    inputs.self.modules.nixos.fonts
  ];

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
}
