# Aggregates `flake.hostIdentityKeys` into `programs.ssh.knownHosts`
# system-wide, so every host pre-trusts every other host's sshd
# identity. Imported by `system-default`.
{self, ...}: let
  knownHostsModule = {lib, ...}: {
    programs.ssh.knownHosts =
      lib.mapAttrs (name: publicKey: {
        hostNames = [name];
        inherit publicKey;
      })
      self.hostIdentityKeys;
  };
in {
  flake.modules.nixos.known-hosts = knownHostsModule;
  flake.modules.darwin.known-hosts = knownHostsModule;
}
