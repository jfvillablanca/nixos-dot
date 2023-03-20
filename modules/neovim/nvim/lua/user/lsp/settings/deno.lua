local lspconfig_status_ok, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status_ok then
	return
end
local deno_root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc")

local config = {
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		-- "typescript",
		-- "typescriptreact",
		-- "typescript.tsx",
	},
	init_options = {
		enable = true,
		unstable = false,
	},
	root_dir = deno_root_dir
}

return config
