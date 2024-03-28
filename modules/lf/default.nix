{
  pkgs,
  config,
  ...
}: {
  xdg.configFile."lf/icons".source = ./icons;

  programs.lf = {
    enable = true;
    commands = {
      editor-open = ''$$EDITOR $f'';
      mkdir = ''
        ''${{
          printf "Directory Name: "
          read DIR
          mkdir $DIR
        }}
      '';
    };

    keybindings = {

      c = "mkdir";
      "." = "set hidden!";
      ee = "editor-open";
  };

  # ...
}
