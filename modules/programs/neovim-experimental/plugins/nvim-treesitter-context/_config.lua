require("treesitter-context").setup({
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
