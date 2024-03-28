{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.direnv;
in {
  options.myHomeModules.direnv = {
    enable =
      lib.mkEnableOption "enables direnv"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
