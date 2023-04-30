local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions

null_ls.setup({
	debug = false,
	sources = {
		-- webdev --
		-- require("typescript.extensions.null-ls.code-actions"),

		-- formatting.deno_fmt,
		formatting.prettier.with({
			extra_args = { "--jsx-single-quote", "--tab-width", "4", "--html-whitespace-sensitivity", "ignore" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"css",
				"sass",
				"scss",
				"less",
				"html",
				"json",
				"jsonc",
				"yaml",
				"markdown",
				"markdown.mdx",
				"graphql",
				"handlebars",
			},
		}),

		-- lua --
		formatting.stylua,

		-- sh --
		formatting.shfmt,
		diagnostics.shellcheck,

		-- nix --
		formatting.nixpkgs_fmt,
		diagnostics.statix,

		-- rust --
		formatting.rustfmt.with({ tab_spaces = 4 }),

		-- python --
		formatting.black,               -- Include python310Packages.black to flake.nix packages
		diagnostics.flake8,             -- Include python310Packages.flake8 to flake.nix packages

		code_actions.refactoring,
	},
})
