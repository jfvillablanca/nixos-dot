# Per-host SSH server identity keys (the public half of
# /etc/ssh/ssh_host_ed25519_key). Each host advertises its own at
# `flake.hostIdentityKeys.<host>`; the system-default tier aggregates
# the registry into `programs.ssh.knownHosts` so every host
# pre-trusts every other host's identity. Eliminates the
# "authenticity of host can't be established" first-connect prompt.
{lib, ...}: {
  options.flake.hostIdentityKeys = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = "SSH server identity public keys, keyed by hostname.";
  };
}
