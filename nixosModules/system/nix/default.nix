{
  pkgs,
  user,
  ...
}: {
  nix = {
    settings = {
      trusted-users = ["root" "${user}"];
      auto-optimise-store = true;
      substituters = [
        "https://hyprland.cachix.org"
        "https://walker.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
      ];
      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 5d";
    };
    package = pkgs.nixFlakes;
  };
}
