{
  flake.modules.nixos.nix = {
    config,
    pkgs,
    inputs,
    ...
  }: {
    nix = {
      settings = {
        trusted-users = ["root" config.systemConstants.user];
        auto-optimise-store = true;
        substituters = [
          "https://hyprland.cachix.org"
          "https://nixos-dot.cachix.org"
          # "https://walker.cachix.org"
        ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "nixos-dot.cachix.org-1:EsmqDf88MC7iaxlCoKTmzVIu/Zm9gLtt+VXlbxaRtNI="
          # "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        ];
        experimental-features = ["nix-command" "flakes"];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 5d";
      };
      nixPath = ["nixpkgs=${inputs.nixpkgs}"];
      package = pkgs.nixVersions.stable;
    };
  };
}
