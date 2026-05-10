# jmfv — the only user. Calls the user factory to register both the
# system account and home-manager defaults, then trusts every host
# in the fleet by aggregating `flake.publicKeys`.
{self, ...}: let
  jmfv = self.factory.user "jmfv";
in {
  flake.modules.nixos.jmfv = {
    imports = [jmfv.nixos];
    users.users.jmfv.openssh.authorizedKeys.keys =
      builtins.attrValues self.publicKeys;
  };
  flake.modules.homeManager.jmfv = jmfv.homeManager;
}
