# Aggregates `flake.hostIdentityKeys` into `programs.ssh.knownHosts`
# system-wide, so every host pre-trusts every other host's sshd
# identity. Imported by `system-default`.
{self, ...}: {
  flake.modules.nixos.known-hosts = {lib, ...}: {
    programs.ssh.knownHosts =
      lib.mapAttrs (name: publicKey: {
        hostNames = [name];
        inherit publicKey;
      })
      self.hostIdentityKeys;
  };
}
