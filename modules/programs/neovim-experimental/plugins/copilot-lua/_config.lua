-- copilot.lua setup. Suggestions accepted via <Right> (same as the prior
-- copilot-vim binding); panel disabled (use blink.cmp's copilot source if
-- the user wants completion-menu integration).

-- NVIM_DISABLE=copilot opts out at runtime (foreign-host runs without auth).
-- _G.nvim_disabled is set up by lib/env-bootstrap.
if _G.nvim_disabled and _G.nvim_disabled("copilot") then
    return
end

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
