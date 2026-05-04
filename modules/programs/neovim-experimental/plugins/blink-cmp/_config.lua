-- blink.cmp setup. Default keymap preset matches roughly what the prior
-- nvim-cmp config used (Tab next, S-Tab prev, CR accept, C-Space trigger,
-- C-e abort, C-b/C-f scroll docs).
require("blink.cmp").setup({
    keymap = { preset = "default" },
    appearance = {
        nerd_font_variant = "mono",
    },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 250 },
        ghost_text = { enabled = false },
        list = { selection = { preselect = false } },
        menu = {
            border = "rounded",
            draw = {
                columns = {
                    { "label", "label_description", gap = 1 },
                    { "kind_icon", "kind", gap = 1 },
                    { "source_name" },
                },
            },
        },
    },
    signature = { enabled = true },
    sources = {
        default = { "lsp", "path", "buffer", "snippets" },
    },
    snippets = {
        preset = "default",
    },
    cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = { menu = { auto_show = true } },
    },
})
