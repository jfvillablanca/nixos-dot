# work-ct -- work-issued M5 Pro MacBook, nix-darwin host.
#
# Pinned to the stable nixpkgs channel (nixos-26.05) via its own colocated
# inputs, independent of the fleet's unstable `nixpkgs`. The nix-darwin
# framework, home-manager, and every app build from stable; only the shared
# leaf inputs (nix-homebrew, kanata, stylix) are reused. Trimmed to a work
# machine: 1Password + Chrome, the CLI dev baseline, kitty/tmux/kanata, and a
# Sunshine stream host reachable from sienna's Moonlight over a tagged
# Tailscale node. Kept out of the personal SSH trust web (no publicKeys entry,
# forced authorized_keys). Deleting this directory + `nix run .#write-flake` +
# relock removes the host and its stable inputs cleanly.
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
  base16Scheme = "kanagawa-dragon";
in {
  # Stable channel + the LizardByte Homebrew tap (sunshine formula), colocated
  # so the whole host rips off with this directory. nix-darwin and
  # home-manager follow the stable nixpkgs so the framework matches the pkgs.
  # `nix run .#write-flake` + `nix flake lock` after editing these.
  flake-file.inputs = {
    nixpkgs-2605.url = "github:nixos/nixpkgs/nixos-26.05";
    nix-darwin-2605 = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-2605";
    };
    home-manager-2605 = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-2605";
    };
    lizardbyte-homebrew = {
      url = "github:LizardByte/homebrew-homebrew";
      flake = false;
    };
  };

  flake.modules.darwin.${hostName} = {
    config,
    pkgs,
    lib,
    ...
  }: let
    inherit (config.systemConstants) user;
  in {
    imports = [
      self.modules.darwin.user
      self.modules.darwin.fish
      self.modules.darwin.tailscale
      self.modules.darwin.known-hosts
      self.modules.darwin.timezone
      self.modules.darwin.nix-index
      self.modules.darwin.kanata
      self.modules.darwin.docker
      self.modules.darwin.sol
    ];

    networking.hostName = hostName;
    networking.computerName = hostName;
    networking.localHostName = hostName;

    # Darwin's stateVersion is an integer, not "22.11"-style. Pin once,
    # never bump. See the nix-darwin manual under `system.stateVersion`.
    system.stateVersion = 6;

    security.pam.services.sudo_local.touchIdAuth = true;

    # `uid` is required on darwin and must match the real account. On this work
    # laptop the IT admin account (ct-admin) is the first GUI user (501), so
    # jmfv is 502 -- unlike sienna where jmfv is 501.
    users.users.${user} = {
      uid = 502;
      isHidden = false;
      home = "/Users/${user}";
      # A work box stays out of the personal SSH trust web: the shared `user`
      # module sets authorized_keys to every fleet host's key; force it back to
      # an explicit set. Add a client key here to allow SSH-in.
      openssh.authorizedKeys.keys = lib.mkForce [
        # "ssh-ed25519 AAAA... jmfv@personal-laptop"
      ];
    };

    # Tailscale reachability for streaming off-LAN. Tagging + auth key are
    # applied by hand on first join (`tailscale up --advertise-tags=tag:work
    # --auth-key=...`); nix-darwin's tailscale twin only exposes `enable`.
    myDarwinModules.tailscale.enable = true;

    # Docker Desktop instead of colima on this host (bundles its own daemon +
    # CLI; standard socket -> testcontainers work without a DOCKER_HOST
    # override). Needs a one-time manual first launch (privileged helper +
    # accept terms). Match myHomeModules.docker.backend in ./_home.nix.
    myDarwinModules.docker.backend = "docker-desktop";

    services.openssh.enable = true;

    # Use Lix as the Nix implementation. Must match what the host-side
    # installer put down; the first darwin-rebuild switch replaces the
    # installer-laid binary with this one.
    nix.package = pkgs.lixPackageSets.stable.lix;

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" user];
    };

    system.defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      dock.autohide = true;
      finder.AppleShowAllExtensions = true;
      screencapture.location = "~/Pictures/Screenshots";
    };

    nix-homebrew = {
      enable = true;
      inherit user;
      taps = {
        "homebrew/homebrew-core" = inputs.homebrew-core;
        "homebrew/homebrew-cask" = inputs.homebrew-cask;
        # Key is the tap's repo dir (owner/homebrew-<repo>), not the
        # `lizardbyte/homebrew` shortname -- matches the homebrew-core/cask
        # keys above and where brew looks the tap up.
        "lizardbyte/homebrew-homebrew" = inputs.lizardbyte-homebrew;
      };
      mutableTaps = false;
    };

    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      casks = [
        "1password"
        "firefox"
        "google-chrome"
        "mongodb-compass"
      ];
      # Sunshine stream host (arm64_tahoe bottle -- no source build). The
      # .app wrapper + launchd agent that make it usable live in ./_home.nix.
      brews = ["lizardbyte/homebrew/sunshine"];
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs user base16Scheme;
        system = "aarch64-darwin";
      };
      users.${user}.imports = [
        self.modules.homeManager.user
        ./_home.nix
      ];
    };
  };

  # Stable sibling of `self.lib.mkDarwin`: builds with the colocated stable
  # nix-darwin + home-manager against nixos-26.05, so both the framework and
  # every package are on the stable channel. `flake.darwinConfigurations` is
  # already registered as a flake output by `inputs.nix-darwin.flakeModules.default`
  # (modules/flake/inputs.nix), so this assignment needs no shared edit.
  flake.darwinConfigurations.${hostName} = inputs.nix-darwin-2605.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = {inherit inputs;};
    modules = [
      inputs.home-manager-2605.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew

      {
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;
      }

      self.modules.darwin.${hostName}
    ];
  };

  # Intentionally absent: flake.publicKeys.${hostName} and
  # flake.hostIdentityKeys.${hostName}. The work box is neither trusted by nor
  # trusting of the personal fleet's SSH keys.
}
