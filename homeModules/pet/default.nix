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
      snippets = [];
    };
  };
}
