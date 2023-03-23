local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics

null_ls.setup({
	debug = false,
	sources = {
		-- webdev --
		require("typescript.extensions.null-ls.code-actions"),

		-- formatting.deno_fmt,
		formatting.prettier.with({
			extra_args = { "--jsx-single-quote", "--tab-width", "4", "--html-whitespace-sensitivity", "ignore" },
			filetypes = {
				"html",
				"markdown",
				"css",
				"scss",
				"sass",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
			},
		}),

		-- lua --
		formatting.stylua,

		-- bash --
		formatting.shfmt,

		-- rust --
		formatting.rustfmt.with({ tab_spaces = 4 }),
	},
	diagnostics = {
		filetypes = { "javascript", "javascriptreact" },
	},
})
