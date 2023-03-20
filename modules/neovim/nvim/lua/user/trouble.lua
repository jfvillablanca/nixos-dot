local present, trouble = pcall(require, "trouble")
if not present then
  return
end

local keymap = vim.api.nvim_set_keymap

trouble.setup()
-- Trouble.nvim mapping
keymap("n", 	 "<leader>mx", "<cmd>TroubleToggle<cr>", 	  { desc = "Trouble toggle"})
keymap("n", 	 "<leader>mw", "<cmd>TroubleToggle workspace_diagnostics<cr>", 	  { desc = "Trouble workspace diag"})
keymap("n", 	 "<leader>md", "<cmd>TroubleToggle document_diagnostics<cr>", 	  { desc = "Trouble document diag"})
keymap("n", 	 "<leader>ml", "<cmd>TroubleToggle loclist<cr>", 	  { desc = "Trouble loclist"})
keymap("n", 	 "<leader>mq", "<cmd>TroubleToggle quickfix<cr>", 	  { desc = "Trouble quickfix"})
keymap("n", 	 "gr",         "<cmd>TroubleToggle lsp_references<cr>", 	  { desc = "Trouble lsp ref"})
