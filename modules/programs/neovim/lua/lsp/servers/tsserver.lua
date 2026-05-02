local util_loaded, util = pcall(require, "lspconfig.util")

if not util_loaded then
    print("lspconfig.util not loaded")
    return
end

local config = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    root_dir = util.root_pattern("package.json", ".git"),
    single_file_support = false,
}

return config
