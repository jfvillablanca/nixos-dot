-- treesj setup. Default keymaps: <space>m toggle, <space>j join, <space>s split.
require("treesj").setup({
    use_default_keymaps = true,
    check_syntax_error = true,
    max_join_length = 120,
    cursor_behavior = "hold",
    notify = true,
    langs = {},
    dot_repeat = true,
})
