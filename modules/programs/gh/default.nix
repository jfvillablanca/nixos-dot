{
  flake.modules.homeManager.gh = {pkgs, ...}: {
    config = {
      programs = {
        gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
          };
          extensions = [pkgs.gh-stack];
        };
        gh-dash = {
          enable = true;
        };
      };
    };
  };
}
