{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.pet;
in {
  options.myHomeModules.pet = {
    enable = lib.mkEnableOption "enables pet";
  };
  config = lib.mkIf cfg.enable {
    programs.pet = {
      enable = true;
      snippets = [
        {
          description = "Nix store garbage collect";
          command = "nix-store --gc";
          tag = ["nix"];
        }
        {
          description = "Fetch nix info";
          command = "nix-info --run 'nix-info -m'";
          tag = ["nix"];
        }
        {
          description = "Nix fmt with alejandra";
          command = "alejandra <files/directories>";
          tag = ["nix"];
        }
        {
          description = "Update package in a flake";
          command = "nix-update --version=<version> <package-name>";
          tag = ["nix"];
        }
        {
          description = "Update a singular flake input";
          command = "nix flake lock --update-input <input-name>";
          tag = ["nix"];
        }
        {
          description = "Get commit count of current branch";
          command = "git rev-list --count HEAD";
          tag = ["git"];
        }
        {
          description = "Fuzzy search git log";
          command = "git log --oneline | fzf --ansi --preview \"git show --color=always {1}\"";
          tag = ["git"];
        }
        {
          description = "Format Purescript in-place with purs-tidy";
          command = "purs-tidy format-in-place <glob>";
          tag = ["purescript"];
        }
        {
          description = "Format Just in-place with just fmt";
          command = "just --fmt --unstable";
          tag = ["just"];
        }
        {
          description = "List all file and directory sizes in long format";
          command = "eza --total-size --long --all";
          tag = ["ls"];
        }
        {
          description = "Get current public IP address";
          command = "host myip.opendns.com resolver1.opendns.com";
          tag = ["network"];
        }
        {
          description = "Live updates on the commit graph";
          command = "find .git/HEAD .git/refs/heads/ -type f | entr sh -c 'clear; git log'";
          tag = ["git" "entr"];
        }
        {
          description = "Find ignored and hidden directories";
          command = "fd --type dir --hidden --no-ignore \"path/to/dir\"";
          tag = ["fd" "find"];
        }
      ];
    };
  };
}
