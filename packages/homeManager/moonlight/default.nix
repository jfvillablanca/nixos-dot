# Home-manager module for moonlight, the Sunshine streaming client
# (packaged upstream as moonlight-qt). `extraSettings` applies on both
# platforms, preserving pairing state, certificate, and key: on Linux it
# merges into the Qt INI config; on macOS its [General] keys merge into the
# `com.moonlight-stream.Moonlight` plist via `defaults import`.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.moonlight;
  iniFormat = pkgs.formats.ini {};
  declared = iniFormat.generate "moonlight-managed.conf" cfg.extraSettings;
  mergeConfig = pkgs.writeShellApplication {
    name = "moonlight-qt-merge-config";
    runtimeInputs = with pkgs; [coreutils gawk];
    text = builtins.readFile ./merge-config.sh;
  };
in {
  options.programs.moonlight = {
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
        Streaming preferences merged into Moonlight's config on
        home-manager activation, preserving pairing state (`[hosts]`),
        the certificate, and the private key. On Linux the whole
        attrset merges into
        `~/.config/Moonlight Game Streaming Project/Moonlight.conf`; on
        macOS the `[General]` keys merge into the
        `com.moonlight-stream.Moonlight` plist via `defaults import`
        (Qt stores ungrouped keys flat there, so only `General` maps).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.package];

    home.activation.moonlightMergeConfig =
      lib.mkIf pkgs.stdenv.hostPlatform.isLinux
      (lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe mergeConfig} \
          "$HOME/.config/Moonlight Game Streaming Project/Moonlight.conf" \
          ${declared}
      '');

    targets.darwin.defaults = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      "com.moonlight-stream.Moonlight" = cfg.extraSettings.General or {};
    };
  };
}
