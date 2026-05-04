-- copilot.lua setup. Suggestions accepted via <Right> (same as the prior
-- copilot-vim binding); panel disabled (use blink.cmp's copilot source if
-- the user wants completion-menu integration).
require("copilot").setup({
    panel = { enabled = false },
    suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
            accept = "<Right>",
            accept_word = false,
            accept_line = false,
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
        },
    },
    filetypes = {
        ["*"] = true,
        gitcommit = false,
        gitrebase = false,
        help = false,
    },
})
