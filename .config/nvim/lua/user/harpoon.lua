local status_ok, mark= pcall(require, "harpoon.mark")
if not status_ok then
	return
end

local ok, ui= pcall(require, "harpoon.ui")
if not ok then
	return
end

vim.keymap.set("n", "<leader>aa", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end, { desc = "harpoon file 1" })
vim.keymap.set("n", "<C-j>", function() ui.nav_file(2) end, { desc = "harpoon file 2" })
vim.keymap.set("n", "<C-k>", function() ui.nav_file(3) end, { desc = "harpoon file 3" })
vim.keymap.set("n", "<C-l>", function() ui.nav_file(4) end, { desc = "harpoon file 4" })
