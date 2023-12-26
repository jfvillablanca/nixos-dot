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
		formatting.stylelint,
		formatting.rustywind,
		code_actions.eslint,

		-- lua --
		formatting.stylua,
		diagnostics.luacheck,

		-- sh --
		formatting.shfmt,
		diagnostics.shellcheck,

		-- nix --
		formatting.nixpkgs_fmt,
		diagnostics.statix,
		diagnostics.deadnix,
		code_actions.statix,

		-- rust --
		formatting.rustfmt.with({ tab_spaces = 4 }),
		formatting.leptosfmt.with({
			condition = function(utils)
				return utils.root_has_file({ "leptosfmt.toml" })
			end,
		}),

		-- python --
		formatting.isort,
		formatting.black,
		diagnostics.pylint,
		diagnostics.mypy,

		-- haskell --
		formatting.fourmolu,

		-- c --
		formatting.clang_format,
		diagnostics.clang_check,

		-- go --
		formatting.gofumpt,

		-- sql --
		formatting.sql_formatter,

		-- github actions --
		diagnostics.actionlint,

		-- markdown --
		diagnostics.write_good,

		-- all filetypes --
		diagnostics.codespell,
        formatting.trim_whitespace,
	},
})
