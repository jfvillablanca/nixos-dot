# sienna -- M5 Pro MacBook Pro, nix-darwin host.
{
  inputs,
  self,
  ...
}: let
  hostName = baseNameOf (toString ./.);
in {
  flake.modules.darwin.${hostName} = {
    config,
    pkgs,
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
    ];

    networking.hostName = hostName;
    networking.computerName = hostName;
    networking.localHostName = hostName;

    # Darwin's stateVersion is an integer, not "22.11"-style. Pin once,
    # never bump. See the nix-darwin manual under `system.stateVersion`.
    system.stateVersion = 6;

    security.pam.services.sudo_local.touchIdAuth = true;

    # 501 is macOS's first-GUI-user UID. `uid` is required on darwin.
    users.users.${user} = {
      uid = 501;
      isHidden = false;
      home = "/Users/${user}";
    };

    myDarwinModules.tailscale.enable = true;

    services.openssh.enable = true;

    # Use Lix as the Nix implementation. Must match what the host-side
    # installer put down (https://install.lix.systems/lix); first
    # darwin-rebuild switch will replace the installer-laid binary with
    # this nixpkgs-provided one.
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
      };
      mutableTaps = false;
    };

    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      casks = [
        "1password"
        "discord"
        "docker"
        "firefox"
        "google-chrome"
        "raycast"
        "slack"
        "spotify"
      ];
    };

    home-manager = {
      useGlobalPkgs = false;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs user;
        system = "aarch64-darwin";
      };
      users.${user}.imports = [
        self.modules.homeManager.user
        ./_home.nix
      ];
    };
  };

  flake.darwinConfigurations.${hostName} = self.lib.mkDarwin hostName;

  flake.publicKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGEIUW//BFc0vmos7O0s/YGou+PH0hlZjwcnFsEamdYk sienna";

  flake.hostIdentityKeys.${hostName} = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXm3GJmV7Jec7zCkUy4BROGBjaYyO2i4w5T4Jd00SwX root@sienna";
}
