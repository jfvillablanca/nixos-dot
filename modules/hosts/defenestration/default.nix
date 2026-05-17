# defenestration — NixOS-WSL test host bootstrapped via tarballBuilder.
{self, ...}: let
  hostName = baseNameOf (toString ./.);
in {
  flake.modules.nixos.${hostName} = {config, ...}: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      self.modules.nixos.user
      self.modules.nixos.system-default
    ];

    networking.hostName = hostName;

    system.stateVersion = "25.05";

    wsl = {
      enable = true;
      defaultUser = user;
    };

    nixpkgs.config.allowUnfree = true;
  };

  flake.nixosConfigurations.${hostName} = self.lib.mkNixos hostName;
}
