local status_ok, highlight = pcall(require, "nvim-highlight-colors")
if not status_ok then
    return
end

highlight.setup({
    render = "background", -- or 'foreground' or 'first_column'
    enable_named_colors = true,
    enable_tailwind = true,
})
