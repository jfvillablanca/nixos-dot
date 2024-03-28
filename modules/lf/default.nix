{...}: {
  xdg.configFile."lf/icons".source = ./icons;

  programs.lf = {
    enable = false;
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
  };
  # ...
}
