# Home-manager module for moonlight-qt, the Sunshine streaming client.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.moonlight-qt;
  iniFormat = pkgs.formats.ini {};
  declared = iniFormat.generate "moonlight-managed.conf" cfg.extraSettings;
  mergeConfig = pkgs.writeShellApplication {
    name = "moonlight-qt-merge-config";
    runtimeInputs = with pkgs; [coreutils gawk];
    text = builtins.readFile ./merge-config.sh;
  };
in {
  options.programs.moonlight-qt = {
    enable = lib.mkEnableOption "moonlight-qt game streaming client";

    package = lib.mkPackageOption pkgs "moonlight-qt" {};

    extraSettings = lib.mkOption {
      inherit (iniFormat) type;
      default = {};
      example = lib.literalExpression ''
        {
          General = {
            width = 1920;
            height = 1080;
            fps = 60;
            bitrate = 50000;
            videocfg = 2; # 0=auto, 1=H.264, 2=HEVC, 4=AV1
          };
        }
      '';
      description = ''
        Sections and keys merged into
        ~/.config/Moonlight Game Streaming Project/Moonlight.conf
        on home-manager activation. Declared keys overwrite existing
        values; sections and keys not declared (e.g. [hosts] pairing
        state, [General] keys outside `extraSettings`) are preserved.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    home.activation.moonlightMergeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${lib.getExe mergeConfig} \
        "$HOME/.config/Moonlight Game Streaming Project/Moonlight.conf" \
        ${declared}
    '';
  };
}
