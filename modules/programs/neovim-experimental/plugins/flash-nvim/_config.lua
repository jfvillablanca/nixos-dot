-- flash-nvim setup. Most fields are defaults; we only override `labels`
-- (qwerty home-row order) and a couple of UX preferences from the prior config.
require("flash").setup({
    labels = "asdfghjklqwertyuiopzxcvbnm",
    search = {
        multi_window = true,
        forward = true,
        wrap = true,
        mode = "exact",
        exclude = {
            "notify",
            "cmp_menu",
            "noice",
            "flash_prompt",
            function(win)
                return not vim.api.nvim_win_get_config(win).focusable
            end,
        },
    },
    jump = {
        autojump = true,
    },
    label = {
        uppercase = true,
        current = true,
        after = true,
    },
    modes = {
        search = {
            enabled = true,
            highlight = { backdrop = false },
            jump = { history = true, register = true, nohlsearch = true },
        },
        char = {
            enabled = true,
            keys = { "f", "F", "t", "T", ";", "," },
        },
    },
})
