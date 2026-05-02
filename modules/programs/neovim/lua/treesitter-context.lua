local status_ok, context = pcall(require, "treesitter-context")
if not status_ok then
    return
end
context.setup({
    on_attach = function()
        local disabled = { "lua", "nix" }
        for _, ft in ipairs(disabled) do
            if ft == vim.bo.filetype then
                return false
            end
        end
        return true
    end,
})
