# jmfv — the only user. Calls the user factory to register both the
# system account and home-manager defaults.
{self, ...}: let
  jmfv = self.factory.user "jmfv";
in {
  flake.modules.nixos.jmfv = jmfv.nixos;
  flake.modules.homeManager.jmfv = jmfv.homeManager;
}
