{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.gh;
in {
  options.myHomeModules.gh = {
    enable =
      lib.mkEnableOption "enables gh"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
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
}
