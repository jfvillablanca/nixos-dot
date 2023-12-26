local function set_semantic_highlights()
	local links = {
		["@lsp.type.namespace"] = "@namespace",
		["@lsp.type.type"] = "@type",
		["@lsp.type.class"] = "@type",
		["@lsp.type.enum"] = "@type",
		["@lsp.type.interface"] = "@type",
		["@lsp.type.struct"] = "@structure",
		["@lsp.type.parameter"] = "@parameter",
		["@lsp.type.variable"] = "@variable",
		["@lsp.type.property"] = "@property",
		["@lsp.type.enumMember"] = "@constant",
		["@lsp.type.function"] = "@function",
		["@lsp.type.method"] = "@method",
		["@lsp.type.macro"] = "@macro",
		["@lsp.type.decorator"] = "@function",
	}

	for newgroup, oldgroup in pairs(links) do
		vim.api.nvim_set_hl(0, newgroup, { link = oldgroup, default = true })
	end
end

set_semantic_highlights()

-- doesn't seem to work, colorscheme still clears @lsp.type.variable on colorscheme change
vim.api.nvim_create_autocmd({ "ColorScheme" }, {
	callback = function()
		set_semantic_highlights()
	end,
})
