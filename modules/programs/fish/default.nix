{
  flake.modules.darwin.fish = {pkgs, ...}: {
    config = {
      programs.fish.enable = true;
      environment.shells = [pkgs.fish];
    };
  };

  flake.modules.homeManager.fish = _: {
    config = {
      programs = {
        fish = {
          enable = true;
          shellInit = ''
            fish_vi_key_bindings
          '';
          shellAliases = {
            ".." = "cd ..";

            # Trashy
            "restore" = "trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash restore --match=exact --force";
            "empty" = "trash list | fzf --multi | awk '{$1=$1;print}' | rev | cut -d ' ' -f1 | rev | xargs trash empty --match=exact --force";

            # Nix-specific
            "review" = " nix-shell -p nixpkgs-review --run 'nixpkgs-review rev HEAD'";
            "nixmeta" = "nix-shell -p nix-info --run 'nix-info -m'";
          };
        };
      };
    };
  };
}
