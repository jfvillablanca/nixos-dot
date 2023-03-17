{ ... }:
{
    programs = {
        gitui = {
            enable = true;
            theme = 
            ''
            (
                /* Color Palette: rebelot/kanagawa.nvim */
                selected_tab: Reset,
                command_fg: Rgb(220, 215, 186),              // #DCD7BA (fujiWhite) 
                selection_bg: Rgb(84, 84, 109),              // #54546D (sumiInk4)
                selection_fg: White,
                cmdbar_bg: Rgb(84, 84, 109),                 // #54546D (sumiInk4) 
                cmdbar_extra_lines_bg: Rgb(84, 84, 109),     // #54546D (sumiInk4) 
                disabled_fg: Rgb(114, 113, 105),             // #727169 (fujiGray)  
                diff_line_add: Green,
                diff_line_delete: Red,
                diff_file_added: LightGreen,
                diff_file_removed: LightRed,
                diff_file_moved: LightMagenta,
                diff_file_modified: Yellow,
                commit_hash: Rgb(210, 126, 153),             // #D27E99 (sakuraPink)
                commit_time: Rgb(127, 180, 202),             // #7FB4CA (springBlue)
                commit_author: Rgb(152, 187, 108),           // #98BB6C (springGreen)
                danger_fg: Red,
                push_gauge_bg: Blue,
                push_gauge_fg: Reset,
                tag_fg: LightMagenta,
                branch_fg: Rgb(230, 195, 132),               // #E6C384 (carpYellow) 

                /* Default Colors */

                /* selected_tab: Reset, */
                /* command_fg: White, */
                /* selection_bg: Blue, */
                /* selection_fg: White, */
                /* cmdbar_bg: Blue, */
                /* cmdbar_extra_lines_bg: Blue, */
                /* disabled_fg: DarkGray, */
                /* diff_line_add: Green, */
                /* diff_line_delete: Red, */
                /* diff_file_added: LightGreen, */
                /* diff_file_removed: LightRed, */
                /* diff_file_moved: LightMagenta, */
                /* diff_file_modified: Yellow, */
                /* commit_hash: Magenta, */
                /* commit_time: LightCyan, */
                /* commit_author: Green, */
                /* danger_fg: Red, */
                /* push_gauge_bg: Blue, */
                /* push_gauge_fg: Reset, */
                /* tag_fg: LightMagenta, */
                /* branch_fg: LightYellow, */
            )
            '';
        };
    };
}
