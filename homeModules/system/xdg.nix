{pkgs, ...}: {
  xdg = {
    enable = true;
    portal = {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
      config = {
        common.default = ["gtk"];
        hyprland.default = ["gtk" "hyprland"];
      };
    };
    userDirs = {
      enable = true;
      createDirectories = false;
    };
  };
}
