# defenestration — NixOS-WSL test host bootstrapped via tarballBuilder.
{self, ...}: {
  flake.modules.nixos.defenestration = {config, ...}: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      self.modules.nixos.user
      self.modules.nixos.system-default
    ];

    networking.hostName = "defenestration";

    system.stateVersion = "25.05";

    wsl = {
      enable = true;
      defaultUser = user;
    };

    nixpkgs.config.allowUnfree = true;
  };

  flake.nixosConfigurations.defenestration = self.lib.mkNixos "defenestration";
}
