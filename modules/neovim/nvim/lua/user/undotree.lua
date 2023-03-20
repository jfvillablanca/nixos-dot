local status_ok, _ = pcall(require, "undotree")
if not status_ok then
	return
end

vim.keymap.set("n", "<F5>", "<cmd>UndotreeToggle<CR>", { desc = "Toggle Undotree" })
