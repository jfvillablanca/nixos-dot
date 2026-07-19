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
      sops.age.keyFile = lib.mkDefault "/persist/secrets/age/keys.txt";
    };
  };
}
