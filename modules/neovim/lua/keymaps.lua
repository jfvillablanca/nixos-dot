local opts = { noremap = true, silent = true }

-- Shorten function name
local keymap = vim.api.nvim_set_keymap

--Remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- [Guide to Modes]
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --

-- Center cursor on on vertical navigation
keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
keymap("n", "n", "nzzzv", { desc = "Next search instance" })
keymap("n", "N", "Nzzzv", { desc = "Prev search instance" })

-- Resize with arrows
keymap("n", "<C-A-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-A-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-A-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-A-Right>", ":vertical resize +2<CR>", opts)

-- [Better window navigation]

keymap("n", "<C-Left>", "<C-w>h", opts)
keymap("n", "<C-Down>", "<C-w>j", opts)
keymap("n", "<C-Up>", "<C-w>k", opts)
keymap("n", "<C-Right>", "<C-w>l", opts)

-- Navigate buffers
keymap("n", "<S-Right>", ":bnext<CR>", opts)
keymap("n", "<S-Left>", ":bprevious<CR>", opts)

-- Move text up and down
keymap("n", "<S-Down>", "mz:m+<cr>`z", opts)
keymap("n", "<S-Up>", "mz:m-2<cr>`z", opts)

-- Remap for dealing with word wrap
keymap("n", "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap("n", "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap("v", "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
keymap("v", "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<S-Down>", "mz:m+<cr>`zgv", opts)
keymap("v", "<S-Up>", "mz:m-2<cr>`zgv", opts)

-- Black hole register (overwrite highlighted text)
keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "<S-Down>", ":move '>+1<CR>gv-gv", opts)
keymap("x", "<S-Up>", ":move '<-2<CR>gv-gv", opts)

-- ( just in case I need to use a qwerty keyboard 🤮 )

-- [Move text up and down]

-- Normal --
-- keymap("n", "<M-j>", "mz:m+<cr>`z", opts)
-- keymap("n", "<M-k>", "mz:m-2<cr>`z", opts)

-- Visual / Visual Block --
-- keymap("v", "<M-k>", "mz:m-2<cr>`z", opts)
-- keymap("v", "<M-j>", "mz:m+<cr>`z", opts)
-- keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
-- keymap("x", "K", ":move '<-2<CR>gv-gv", opts)
-- keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", opts)
-- keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", opts)

-- [Press jk fast to exit insert mode]

-- keymap("i", "jk", "<ESC>", opts)
-- keymap("i", "kj", "<ESC>", opts)

-- [Navigate buffers]
-- keymap("n", "<S-l>", ":bnext<CR>", opts)
-- keymap("n", "<S-h>", ":bprevious<CR>", opts)

-- [Remap for dealing with word wrap]
-- keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
