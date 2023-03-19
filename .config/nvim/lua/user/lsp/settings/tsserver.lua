local util_loaded, util = pcall(require, "lspconfig.util")

if not util_loaded then
    print("lspconfig.util not loaded")
    return
end

local config = { root_dir = util.root_pattern("package.json"), single_file_support = false }

return config
