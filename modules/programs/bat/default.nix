{
  flake.modules.homeManager.bat = _: {
    config = {
      programs.bat = {
        enable = true;
        # extraPackages = with pkgs.bat-extras; [];
      };
    };
  };
}
