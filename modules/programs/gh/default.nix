{
  flake.modules.homeManager.gh = _: {
    config = {
      programs = {
        gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
          };
        };
        gh-dash = {
          enable = true;
        };
      };
    };
  };
}
