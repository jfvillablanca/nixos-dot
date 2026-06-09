# The single user feature. Reads its identity from
# `self.constants.user` (default `jmfv`), calls the user factory to
# register both the system account and home-manager defaults, and
# trusts every host in the fleet by aggregating `flake.publicKeys`.
# The flake-module keys (`.user` under both classes) are generic so
# consumers don't have to know the user's name.
{self, ...}: let
  inherit (self.constants) user;
  userBundle = self.factory.user user;
in {
  flake.modules.nixos.user = {
    imports = [userBundle.nixos];
    users.users.${user}.openssh.authorizedKeys.keys =
      builtins.attrValues self.publicKeys;
  };
  flake.modules.darwin.user = {
    config,
    pkgs,
    ...
  }: {
    imports = [self.modules.generic.systemConstants];
    system.primaryUser = config.systemConstants.user;

    users.knownUsers = [user];
    users.users.${user} = {
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = builtins.attrValues self.publicKeys;
    };
  };
  flake.modules.homeManager.user = {
    imports = [
      userBundle.homeManager
      self.modules.generic.systemConstants
      # Expose the persistence option set in every HM scope so feature
      # modules can contribute `myHomeModules.persistence.directories`
      # unconditionally. Inert (enable = false) on hosts that don't
      # use it; t14g1 flips enable in its own _home.nix.
      self.modules.homeManager.persistence
    ];
  };
}
