{
  flake.modules.homeManager.alacritty = _: {
    config = {
      programs = {
        alacritty = {
          enable = true;
          settings = {
            window = {
              padding.x = 5;
              padding.y = 5;
              opacity = 1.0;
            };
            # Default is "OnlyCopy" — let remote programs read+write
            # the clipboard via OSC 52, so nvim over ssh can both yank
            # to and paste from the host clipboard.
            terminal.osc52 = "CopyPaste";
          };
        };
      };
    };
  };
}
