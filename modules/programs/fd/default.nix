{
  flake.modules.homeManager.fd = _: {
    config = {
      programs.fd = {
        enable = true;
      };
    };
  };
}
