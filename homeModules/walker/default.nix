{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.walker;
  inherit (config.colorScheme) palette;
in {
  options.myHomeModules.walker = {
    enable =
      lib.mkEnableOption "enables walker"
      // {
        default = false;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      walker = {
        enable = true;
        runAsService = true;

        config = {
          placeholder = "Search...";
          keep_open = false;
          ignore_mouse = false;
          ssh_host_file = "";
          enable_typeahead = false;
          show_initial_entries = true;
          fullscreen = false;
          scrollbar_policy = "automatic";
          hyprland = {
            context_aware_history = true;
          };
          activation_mode = {
            disabled = false;
            use_f_keys = false;
            use_alt = false;
          };
          search = {
            delay = 0;
            hide_icons = false;
            margin_spinner = 10;
            hide_spinner = false;
          };
          runner = {
            excludes = ["rm"];
          };
          clipboard = {
            max_entries = 10;
            image_height = 300;
          };
          align = {
            ignore_exlusive = true;
            width = 400;
            horizontal = "center";
            vertical = "start";
            anchors = {
              top = false;
              left = false;
              bottom = false;
              right = false;
            };
            margins = {
              top = 20;
              bottom = 0;
              end = 0;
              start = 0;
            };
          };
          list = {
            height = 300;
            margin_top = 10;
            always_show = true;
            hide_sub = false;
          };
          orientation = "vertical";
          icons = {
            theme = "";
            hide = false;
            size = 28;
            image_height = 200;
          };
          modules = [
            {
              name = "runner";
              prefix = "";
            }
            {
              name = "applications";
              prefix = "";
            }
            {
              name = "ssh";
              prefix = "";
              switcher_exclusive = true;
            }
            {
              name = "finder";
              prefix = "";
              switcher_exclusive = true;
            }
            {
              name = "commands";
              prefix = "";
              switcher_exclusive = true;
            }
            {
              name = "websearch";
              prefix = "?";
            }
            {
              name = "switcher";
              prefix = "/";
            }
          ];
        };

        style = ''
          * {
            color: #${palette.base06};
          }

          #window {
            background: #${palette.base00};
          }

          #box {
            background: #${palette.base00};
            padding: 10px;
            border-radius: 2px;
          }

          #searchwrapper {
          }

          #search,
          #typeahead {
            border-radius: 0;
            outline: none;
            outline-width: 0px;
            box-shadow: none;
            border-bottom: none;
            border: none;
            background: #${palette.base01};
            padding-left: 10px;
            padding-right: 10px;
            padding-top: 0px;
            padding-bottom: 0px;
            border-radius: 2px;
          }

          #spinner {
            opacity: 0;
          }

          #spinner.visible {
            opacity: 1;
          }

          #typeahead {
            background: none;
            opacity: 0.5;
          }

          #search placeholder {
            opacity: 0.5;
          }

          #list {
          }

          row:selected {
            background: #${palette.base01};
          }

          .item {
            padding: 5px;
            border-radius: 2px;
          }

          .icon {
            padding-right: 5px;
          }

          .textwrapper {
          }

          .label {
          }

          .sub {
            opacity: 0.5;
          }

          .activationlabel {
            opacity: 0.25;
          }
          .activation .activationlabel {
            opacity: 1;
            color: #${palette.base0B}; /* green */
          }

          .activation .textwrapper,
          .activation .icon,
          .activation .search {
            opacity: 0.5;
          }
        '';
      };
    };
  };
}
