# sops-nix secrets, wired for both the nixos and darwin classes. Encrypted
# secrets live in secrets/*.yaml; recipients are declared in the repo-root
# .sops.yaml (read by the `sops` CLI, not by Nix). Secrets decrypt at
# activation into /run/secrets* -- nothing secret touches the Nix store.
#
# The decryption identity differs by class, each for its own reason:
#   nixos  -- a dedicated per-host age key on /persist, delivered out-of-band
#             like the tailscale authkey. rue has no sshd to derive from, and
#             the key has to survive the ephemeral-root wipe.
#   darwin -- the host's own SSH key. sienna runs sshd and its host key is
#             already recorded in flake.hostIdentityKeys, so there is nothing
#             to deliver and no ceremony to perform.
#
# `inputs` is captured at the flake-parts level and closed over, matching
# modules/system/persistence.
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

  # Secrets land on a 64 MB HFS ramdisk at /run/secrets -- a hardcoded constant
  # of the upstream darwin module (manifest-for.nix), not a configurable path.
  # sops-nix already defaults sshKeyPaths to this same key; naming it here
  # keeps a security-critical identity explicit and gives `enable` something
  # real to gate, mirroring the nixos sibling above.
  #
  # Note `neededForUsers` is a documented no-op on darwin -- nix-darwin cannot
  # manage user passwords -- so darwin secrets only ever reach /run/secrets.
  flake.modules.darwin.sops = {
    config,
    lib,
    ...
  }: let
    cfg = config.myDarwinModules.sops;
  in {
    imports = [inputs.sops-nix.darwinModules.sops];

    options.myDarwinModules.sops.enable =
      lib.mkEnableOption "sops-nix secrets"
      // {default = false;};

    config = lib.mkIf cfg.enable {
      sops.age.sshKeyPaths = lib.mkDefault ["/etc/ssh/ssh_host_ed25519_key"];
    };
  };
}
