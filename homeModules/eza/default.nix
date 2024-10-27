{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.eza;
in {
  options.myHomeModules.eza = {
    enable =
      lib.mkEnableOption "enables eza"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      eza = {
        enable = true;
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
        ];
      };
    };
  };
}
