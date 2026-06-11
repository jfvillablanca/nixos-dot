# Meta-feature: the Hyprland desktop stack. Hosts import this instead of
# eww/hyprland/swaync/waybar/wofi/window-manager individually.
{inputs, ...}: {
  flake.modules.homeManager.hyprland-stack = {pkgs, ...}: {
    imports = with inputs.self.modules.homeManager; [
      hyprland
      swaync
      waybar
      window-manager
      wofi
    ];

    home.packages = with pkgs; [
      kooha
      wl-clipboard
      waypaper
      swww
    ];
  };
}
