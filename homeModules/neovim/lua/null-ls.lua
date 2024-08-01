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

		-- lua --
		formatting.stylua,
		diagnostics.selene,

		-- sh --
		formatting.shfmt,

		-- nix --
		formatting.alejandra,
		diagnostics.statix,
		diagnostics.deadnix,
		code_actions.statix,

		-- rust --
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

		-- c --
		formatting.clang_format,

		-- go --
		formatting.gofumpt,

		-- sql --
		formatting.sql_formatter,

		-- github actions --
		diagnostics.actionlint,

		-- markdown --
		-- diagnostics.write_good,
	},
})
