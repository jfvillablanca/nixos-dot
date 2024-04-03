{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$fileManager" = "thunar";
    "$terminal" = "alacritty";
    "$menu" = "wofi --show drun";

    "exec-once" = "alacritty & firefox";

    monitor = [
      "HDMI-A-1, 1920x1080, 0x0, 1"
      "DP-1, 1920x1080, 1920x0, 1"
    ];

    decoration = {
      shadow_offset = "0 5";
      "col.shadow" = "rgba(00000099)";
    };
    animations = {
      enabled = true;
      animation = [
        "border, 1, 2, default"
        "fade, 1, 4, default"
        "windows, 1, 3, default, popin 80%"
        "workspaces, 1, 2, default, slide"
      ];
    };

    master = {
      new_is_master = false;
    };
  };
}
