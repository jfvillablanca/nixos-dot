{
  lib,
  config,
  ...
}: let
  cfg = config.myHomeModules.starship;
in {
  options.myHomeModules.starship = {
    enable =
      lib.mkEnableOption "enables starship"
      // {
        default = true;
      };
  };
  config = lib.mkIf cfg.enable {
    programs = {
      starship = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        settings = {
          format = lib.concatStrings [
            # "$username"
            # "$hostname"
            "$localip"
            # "$shlvl"
            "$singularity"
            "$kubernetes"
            "$directory"
            "$vcsh"
            "$fossil_branch"
            "$git_branch"
            "$git_commit"
            "$git_state"
            "$git_metrics"
            "$git_status"
            "$hg_branch"
            "$pijul_channel"
            "$docker_context"
            "$package"
            "$c"
            "$cmake"
            "$cobol"
            "$daml"
            "$dart"
            "$deno"
            "$dotnet"
            "$elixir"
            "$elm"
            "$erlang"
            "$fennel"
            "$golang"
            "$guix_shell"
            "$haskell"
            "$haxe"
            "$helm"
            "$java"
            "$julia"
            "$kotlin"
            "$gradle"
            "$lua"
            "$nim"
            "$nodejs"
            "$ocaml"
            "$opa"
            "$perl"
            "$php"
            "$pulumi"
            "$purescript"
            "$python"
            "$raku"
            "$rlang"
            "$red"
            "$ruby"
            "$rust"
            "$scala"
            "$solidity"
            "$swift"
            "$terraform"
            "$vlang"
            "$vagrant"
            "$zig"
            "$buf"
            "$nix_shell"
            "$conda"
            "$meson"
            "$spack"
            "$memory_usage"
            "$aws"
            "$gcloud"
            "$openstack"
            "$azure"
            "$env_var"
            "$crystal"
            "$custom"
            "$sudo"
            # "$cmd_duration"
            "$line_break"
            "$jobs"
            "$battery"
            "$time"
            "$status"
            "$os"
            "$container"
            "$shell"
            "$character"
          ];

          add_newline = false;

          palette = "kanagawa";

          palettes.kanagawa = {
            oldwhite = "#c8c093";
            roninyellow = "#ff9e3b";
            autumngreen = "#76946A";
            crystalblue = "#7E9CD8";
            surimiorange = "#FFA066";
            samuraired = "#E82424";
            autumnred = "#C34043";
          };

          username = {
            style_user = "autumngreen bold";
            style_root = "black bold";
            format = "[$user]($style) ";
            disabled = false;
            show_always = true;
          };

          hostname = {
            ssh_only = false;
            format = "[$ssh_symbol](bold cyan)[$hostname](bold roninyellow) ";
            trim_at = ".companyname.com";
            disabled = false;
          };

          directory = {
            style = "crystalblue";
            read_only = " ";
            truncation_length = 2;
            truncate_to_repo = false;
          };

          git_branch = {
            symbol = " ";
            format = "[$symbol$branch]($style) ";
            style = "surimiorange";
          };

          git_state = {
            format = "([$state( $progress_current/$progress_total)]($style)) ";
            style = "bright-black";
          };

          git_status = {
            format = ''([\[$all_status$ahead_behind\]]($style) )'';
            style = "cyan";
          };

          git_metrics.disabled = false;

          fill.symbol = " ";

          nodejs = {
            format = "[$symbol($version )]($style)";
            disabled = true;
          };

          python = {
            symbol = "󰌠 ";
          };

          rust = {
            symbol = " ";
          };

          golang = {
            symbol = "󰟓 ";
          };

          nix_shell = {
            disabled = false;
            # impure_msg = "[impure shell](bold autumnred)";
            # pure_msg = "[pure shell](bold autumngreen)";
            # unknown_msg = "[unknown shell](bold roninyellow)";
            format = ''[$symbol shell](bold crystalblue) '';
            symbol = "";
          };

          shlvl = {
            disabled = false;
            symbol = "󰜮";
            style = "samuraired bold";
          };

          jobs = {
            symbol = "";
            style = "bold red";
            number_threshold = 1;
            format = "[$symbol]($style)";
          };

          memory_usage = {
            symbol = "󰍛 ";
          };

          character = {
            success_symbol = "[❯](purple)";
            error_symbol = "[❯](red)";
            vicmd_symbol = "[❮](green)";
          };
        };
      };
    };
  };
}
