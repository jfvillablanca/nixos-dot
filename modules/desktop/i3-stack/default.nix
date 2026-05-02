# Meta-feature: the i3 desktop stack. Hosts import this instead of
# autorandr/i3/picom/polybar/rofi/window-manager individually.
{inputs, ...}: {
  flake.modules.homeManager.i3-stack = {pkgs, ...}: {
    imports = with inputs.self.modules.homeManager; [
      autorandr
      i3
      picom
      polybar
      rofi
      window-manager
    ];

    home.packages = with pkgs; [
      simplescreenrecorder
    ];
  };
}
