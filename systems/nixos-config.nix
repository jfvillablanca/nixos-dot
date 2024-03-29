{
  config,
  pkgs,
  ...
}: {
  # NixOs Configuration
  nix = {
    settings = {
      auto-optimise-store = true;
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
