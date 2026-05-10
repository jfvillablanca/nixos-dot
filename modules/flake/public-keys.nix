# Per-host public SSH keys. Each host advertises its own at
# `flake.publicKeys.<host>`; user modules aggregate via
# `builtins.attrValues self.publicKeys`. Plaintext is correct here —
# public keys aren't secrets. See D.1b in docs/BACKLOG.md for the
# pipeline that does handle real secrets.
{lib, ...}: {
  options.flake.publicKeys = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = "Public SSH keys advertised by each host, keyed by hostname.";
  };
}
