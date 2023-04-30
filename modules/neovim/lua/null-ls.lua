local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/formatting
local formatting = null_ls.builtins.formatting
-- https://github.com/jose-elias-alvarez/null-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions

local tab_width_2_filetypes = {
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
	"handlebars",
}

null_ls.setup({
	debug = false,
	sources = {
		-- webdev --
		-- require("typescript.extensions.null-ls.code-actions"),
		formatting.prettier.with({
			extra_args = function(params)
				local tab_width = "4"
				if vim.tbl_contains(tab_width_2_filetypes, params.ft) then
					tab_width = "2"
				end
				return { "--jsx-single-quote", "--tab-width", tab_width, "--html-whitespace-sensitivity", "ignore" }
			end,
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
		code_actions.statix,

		-- rust --
		formatting.rustfmt.with({ tab_spaces = 4 }),

		-- python --
		formatting.black,               -- Include python310Packages.black to flake.nix packages
		diagnostics.flake8,             -- Include python310Packages.flake8 to flake.nix packages

		code_actions.refactoring,
	},
})
