local keymap = vim.api.nvim_set_keymap
local present, zk = pcall(require, "zk")
if not present then
	return
end

local commands = require("zk.commands")

zk.setup({
	-- can be "telescope", "fzf" or "select" (`vim.ui.select`)
	-- it's recommended to use "telescope" or "fzf"
	picker = "telescope",

	lsp = {
		-- `config` is passed to `vim.lsp.start_client(config)`
		config = {
			cmd = { "zk", "lsp" },
			name = "zk",
			-- on_attach = ...
			-- etc, see `:h vim.lsp.start_client()`
		},

		-- automatically attach buffers in a zk notebook that match the given filetypes
		auto_attach = {
			enabled = true,
			filetypes = { "markdown" },
		},
	},
})

commands.add("ZkOrphans", function(options)
	options = vim.tbl_extend("force", { orphan = true }, options or {})
	zk.edit(options, { title = "Zk Orphans" })
end)

-- Zk mapping
keymap("n", 	 "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: '), dir = 'notes' }<CR>", 	  { desc = "Zk New Note"})
keymap("n", 	 "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", 	  { desc = "Zk Open Notes"})
keymap("n", 	 "<leader>zt", "<Cmd>ZkTags<CR>", 	  { desc = "Zk Open Notes with selected tags"})
-- keymap("n", 	 "<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' }, match = vim.fn.input('Search: ') }<CR>", 	  { desc = "Zk Search Match Query"})
keymap("v", 	 "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = 'notes' }<CR>", 	  { desc = "Zk New From Title Selection"})
