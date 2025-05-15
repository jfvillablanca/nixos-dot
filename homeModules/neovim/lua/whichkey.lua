local status_ok, wk = pcall(require, "which-key")
if not status_ok then
	return
end

local setup = {
	plugins = {
		marks = true, -- shows a list of your marks on ' and `
		registers = true, -- shows your registers on " in NORMAL or <C-r> in INSERT mode
		spelling = {
			enabled = false, -- enabling this will show WhichKey when pressing z= to select spelling suggestions
			suggestions = 20, -- how many suggestions should be shown in the list?
		},
		-- the presets plugin, adds help for a bunch of default keybindings in Neovim
		-- No actual key bindings are created
		presets = {
			operators = false, -- adds help for operators like d, y, ... and registers them for motion / text object completion
			motions = true, -- adds help for motions
			text_objects = true, -- help for text objects triggered after entering an operator
			windows = true, -- default bindings on <c-w>
			nav = true, -- misc bindings to work with windows
			z = true, -- bindings for folds, spelling and others prefixed with z
			g = true, -- bindings for prefixed with g
		},
	},
	-- add operators that will trigger motion and text object completion
	-- to enable all native operators, set the preset / operators plugin above
	-- operators = { gc = "Comments" },
	icons = {
		breadcrumb = "»", -- symbol used in the command line area that shows your active key combo
		separator = "➜", -- symbol used between a key and it's label
		group = "+", -- symbol prepended to a group
	},
	layout = {
		height = { min = 4, max = 25 }, -- min and max height of the columns
		width = { min = 20, max = 50 }, -- min and max width of the columns
		spacing = 3, -- spacing between columns
		align = "left", -- align columns left, center or right
	},
	show_help = true, -- show help message on the command line when the popup is visible
}

local opts = {
	mode = { "n" }, -- NORMAL mode
}

wk.add({
   {"<leader>w",  "<cmd>w!<CR>", desc = "Save" },
   {"<leader>q",  "<cmd>q!<CR>", desc = "Quit" },
   {"<leader>c",  "<cmd>bd!<CR>", desc = "Close Buffer" },
   -- https://stackoverflow.com/questions/1444322/how-can-i-close-a-buffer-without-closing-the-window#comment107676238_19620009
   {"<leader>d",  "<cmd>bp|bd#<CR>", desc = "Close buffer on this split and open prev buffer" },
   {"<leader>T",  "<cmd>set foldmethod=expr<cr>", desc = "Treesitter foldmethod" },
}, opts)

wk.add({
    { "<leader>n", group = "NvimTree" },
    { "<leader>ne", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
}, opts)


wk.add({
    { "<leader>g", group = "Git", nowait = true, remap = false },
    { "<leader>gn", "<cmd>diffget //3<cr>", desc = "Diffget from merge branch", nowait = true, remap = false },
    { "<leader>gs", group = "Gitsigns", nowait = true, remap = false },
    { "<leader>gsR", "<cmd>Gitsigns reset_buffer<cr>", desc = "Reset Buffer", nowait = true, remap = false },
    { "<leader>gse", "<cmd>Gitsigns prev_hunk<cr>", desc = "Prev Hunk", nowait = true, remap = false },
    { "<leader>gsl", "<cmd>Gitsigns blame_line<cr>", desc = "Blame", nowait = true, remap = false },
    { "<leader>gsn", "<cmd>Gitsigns next_hunk<cr>", desc = "Next Hunk", nowait = true, remap = false },
    { "<leader>gsp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview Hunk", nowait = true, remap = false },
    { "<leader>gsr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset Hunk", nowait = true, remap = false },
    { "<leader>gss", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage Hunk", nowait = true, remap = false },
    { "<leader>gsu", "<cmd>Gitsigns undo_stage_hunk<cr>", desc = "Undo Stage Hunk", nowait = true, remap = false },
    { "<leader>gt", "<cmd>diffget //2<cr>", desc = "Diffget from target branch", nowait = true, remap = false },
}, opts)

wk.add({
    { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Find Text", nowait = true, remap = false },
    { "<leader><space>", "<cmd>Telescope buffers<cr>", desc = "Buffers", nowait = true, remap = false },
    { "<leader>t", group = "Telescope", nowait = true, remap = false },
    { "<leader>tC", "<cmd>Telescope commands<cr>", desc = "Commands", nowait = true, remap = false },
    { "<leader>tR", "<cmd>Telescope registers<cr>", desc = "Registers", nowait = true, remap = false },
    { "<leader>tb", "<cmd>Telescope git_branches<cr>", desc = "Checkout branch", nowait = true, remap = false },
    { "<leader>tc", "<cmd>Telescope git_commits<cr>", desc = "Checkout commit", nowait = true, remap = false },
    { "<leader>tf", "<cmd>lua require('telescope.builtin').find_files(require('telescope.themes').get_dropdown{previewer = false})<cr>", desc = "Find files", nowait = true, remap = false },
    { "<leader>th", "<cmd>lua require('telescope.builtin').help_tags(require('telescope.themes').get_dropdown{previewer = false})<cr>", desc = "Find help", nowait = true, remap = false },
    { "<leader>tk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps", nowait = true, remap = false },
    { "<leader>to", "<cmd>Telescope git_status<cr>", desc = "Open changed file", nowait = true, remap = false },
    { "<leader>tr", "<cmd>Telescope oldfiles<cr>", desc = "Open Recent File", nowait = true, remap = false },
    { "<leader>tw", "<cmd>Telescope grep_string<cr>", desc = "Search current word", nowait = true, remap = false },
}, opts)

wk.add({
    { "<leader>m", group = "TreeSJ", nowait = true, remap = false },
    { "<leader>mt", "<cmd>TSJToggle<cr>", desc = "TreeSJ Toggle", nowait = true, remap = false },
}, opts)

wk.add({
    { "<leader>l", group = "LSP", nowait = true, remap = false },
    { "<leader>lS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols", nowait = true, remap = false },
    { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action", nowait = true, remap = false },
    { "<leader>ld", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics", nowait = true, remap = false },
    { "<leader>lf", "<cmd>lua vim.lsp.buf.format{ async = true }<cr>", desc = "Format", nowait = true, remap = false },
    { "<leader>li", "<cmd>LspInfo<cr>", desc = "Info", nowait = true, remap = false },
    { "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action", nowait = true, remap = false },
    { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename", nowait = true, remap = false },
    { "<leader>ls", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols", nowait = true, remap = false },
    { "<leader>lw", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics", nowait = true, remap = false },
    { "<leader>m", group = "Trouble", nowait = true, remap = false },
    { "<leader>md", "<cmd>Trouble diagnostics<cr>", desc = "Diagnostics", nowait = true, remap = false },
    { "<leader>ml", "<cmd>Trouble loclist<cr>", desc = "Loclist", nowait = true, remap = false },
    { "<leader>mq", "<cmd>Trouble quickfix<cr>", desc = "Quickfix", nowait = true, remap = false },
    { "<leader>mx", "<cmd>Trouble<cr>", desc = "Toggle", nowait = true, remap = false },
    { "K", "<cmd>lua vim.lsp.buf.hover()<CR>", desc = "LSP Hover", nowait = true, remap = false },
    { "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", desc = "LSP Declaration", nowait = true, remap = false },
    { "gI", "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "LSP Implementation", nowait = true, remap = false },
    { "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", desc = "LSP Definition", nowait = true, remap = false },
    { "gr", "<cmd>Trouble lsp_references<cr>", desc = "LSP References", nowait = true, remap = false },
}, opts)

wk.add({
    { "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>", nowait = true, remap = false },
    { "<leader>fmg", "<cmd>CellularAutomaton game_of_life<CR>", nowait = true, remap = false },
    { "<leader>fms", "<cmd>CellularAutomaton scramble<CR>", nowait = true, remap = false },
}, opts)

wk.setup(setup)
