local null_ls_status_ok, null_ls = pcall(require, "null-ls")
if not null_ls_status_ok then
	return
end

local formatting = null_ls.builtins.formatting
local diagnostics = null_ls.builtins.diagnostics
local code_actions = null_ls.builtins.code_actions

null_ls.setup({
	debug = false,
	sources = {
		-- webdev --
		formatting.prettier,
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
		diagnostics.codespell.with({
			args = { "-L", "crate" },
		}),
		formatting.trim_whitespace,
	},
})
