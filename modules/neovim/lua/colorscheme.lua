local colorscheme = "kanagawa"

if colorscheme == "rose-pine" then
	require("rosepine")
end
if colorscheme == "kanagawa" then
	require("kanagawa")
end

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
	return
end
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatermBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = "none" })
-- vim.api.nvim_set_hl(0, "CmpCompletionBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "LspInfoBorder", { bg = "none" })
vim.api.nvim_set_hl(0, "PMenu", { bg = "none" })
-- vim.api.nvim_set_hl(0, "LineNr", { bg = "none" })
-- vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
-- vim.api.nvim_set_hl(0, "DiagnosticSignError", { bg = "none" })
-- vim.api.nvim_set_hl(0, "DiagnosticSignWarn", { bg = "none" })
-- vim.api.nvim_set_hl(0, "DiagnosticSignInfo", { bg = "none" })
-- vim.api.nvim_set_hl(0, "DiagnosticSignHint", { bg = "none" })
