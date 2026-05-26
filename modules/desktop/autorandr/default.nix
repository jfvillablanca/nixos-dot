# autorandr listens on udev `drm` events and re-applies an xrandr
# layout whenever the connected outputs match a declared profile's
# EDID fingerprints. Beats the one-shot xrandr-on-session-start
# pattern because it absorbs late-arriving EDID handshakes (AMD
# Cezanne HDMI is a notorious offender on cold boot).
#
# Synthesises `programs.autorandr.profiles.default` from
# `myHomeModules.window-manager.monitors` when every entry in the
# list has a `fingerprint` populated. If any monitor is missing a
# fingerprint, the profile is not emitted and the host falls back
# to whatever xrandr layer is in scope.
{
  flake.modules.homeManager.autorandr = {
    config,
    lib,
    ...
  }: let
    inherit (config.myHomeModules.window-manager) monitors;
    haveFingerprints =
      monitors
      != []
      && lib.all (m: m.fingerprint != null) monitors;
    monitorToConfig = m: {
      enable = m.enabled;
      primary = m.isPrimary;
      mode = "${toString m.width}x${toString m.height}";
      rate = "${toString m.refreshRate}.00";
      position = "${toString m.x}x${toString m.y}";
      inherit (m) rotate;
    };
  in {
    config = lib.mkMerge [
      {
        programs.autorandr.enable = true;
        services.autorandr.enable = true;
      }
      (lib.mkIf haveFingerprints {
        programs.autorandr.profiles.default = {
          fingerprint = lib.listToAttrs (map (m: {
              inherit (m) name;
              value = m.fingerprint;
            })
            monitors);
          config = lib.listToAttrs (map (m: {
              inherit (m) name;
              value = monitorToConfig m;
            })
            monitors);
        };
      })
    ];
  };
}
