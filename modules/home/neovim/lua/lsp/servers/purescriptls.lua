local util_loaded, util = pcall(require, "lspconfig.util")

if not util_loaded then
    print("lspconfig.util not loaded")
    return
end

local config = {
    cmd = { "purescript-language-server", "--stdio" },
    filetypes = { "purescript" },
    root_dir = util.root_pattern("bower.json", "psc-package.json", "shell.nix", "spago.dhall", "spago.yaml"),
    single_file_support = true,
}

return config
