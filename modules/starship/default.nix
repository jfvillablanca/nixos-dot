{ lib, ... }:
{
    programs = {
    starship = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        settings = 
        {
            format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$shlvl"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$git_metrics"
            "$nix_shell"
            "$fill"
            "$nodejs"
            "$rust"
            "$jobs"
            "$memory_usage"
            "$line_break"
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
                read_only = " ";
                truncation_length = 1;
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

            rust = {
                symbol = " ";
            };

            nix_shell = {
                disabled = false;
                impure_msg = "[impure shell](bold autumnred)";
                pure_msg = "[pure shell](bold autumngreen)";
                unknown_msg = "[unknown shell](bold roninyellow)";
                format = ''[$symbol \[$state\]( ($name))](crystalblue) '';
                symbol = "";
            };

            shlvl = {
              disabled = false;
              symbol = "ﰬ";
              style = "samuraired bold";
            };

            jobs = {
                symbol = "";
                style = "bold red";
                number_threshold = 1;
                format = "[$symbol]($style)";
            };

            memory_usage = {
                symbol = " ";
            };

            character = {
                success_symbol = "[❯](purple)";
                error_symbol = "[❯](red)";
                vicmd_symbol = "[❮](green)";
            };
        };
    };
    };
}
