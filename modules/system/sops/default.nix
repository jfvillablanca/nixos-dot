# sops-nix secrets. Decryption identity is a dedicated per-host age key on
# /persist (delivered out-of-band like the tailscale authkey), so it survives
# the ephemeral-root wipe and needs no sshd. Encrypted secrets live in
# secrets/*.yaml; recipients are declared in the repo-root .sops.yaml (read by
# the `sops` CLI, not by Nix). Secrets decrypt at activation into /run/secrets*
# (tmpfs) -- nothing secret touches the Nix store. `inputs` is captured at the
# flake-parts level and closed over, matching modules/system/persistence.
{inputs, ...}: {
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.nixos.sops = {
    config,
    lib,
    ...
  }: let
    cfg = config.myNixosModules.sops;
  in {
    imports = [inputs.sops-nix.nixosModules.sops];

    options.myNixosModules.sops.enable =
      lib.mkEnableOption "sops-nix secrets"
      // {default = false;};

    config = lib.mkIf cfg.enable {
      # Type is `pathNotInStore`: a quoted string, never a Nix path literal
      # (a literal would copy into the store and be rejected). Same convention
      # as tailscale's authKeyFile. mkDefault so a host can relocate it.
      #
      # BOOTSTRAP PRECONDITION: this key must exist on the host BEFORE the first
      # activation that consumes a secret. On a fresh install of a host that also
      # sets `users.mutableUsers = false` with a sops `hashedPasswordFile`, a
      # missing key means the account is created with no valid password (`!`) ->
      # installer/console recovery. Deliver it out-of-band to /persist first
      # (like the tailscale authkey). The two-phase rollout only nets you on a
      # host that already has a working password; a clean reinstall does not.
      sops.age.keyFile = lib.mkDefault "/persist/secrets/age/keys.txt";
    };
  };
}
