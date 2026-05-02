local util_loaded, util = pcall(require, "lspconfig.util")

if not util_loaded then
    print("lspconfig.util not loaded")
    return
end

local config = {
    cmd = { "nil" },
    filetypes = { "nix" },
    root_dir = util.root_pattern("flake.nix", ".envrc", ".git"),
    single_file_support = true,
}

return config
