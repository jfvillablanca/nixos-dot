-- Core keymaps + leader. Modern vim.keymap.set; replaces the legacy
-- nvim_set_keymap shape used in modules/programs/neovim/lua/keymaps.lua.
--
-- Two sections:
-- 1. Behavior tweaks — augment vim's defaults (centered scrolling, wrap-aware
--    motion, stay-in-indent visual, etc.).
-- 2. User shortcuts — leader-prefixed convenience for vim-builtin operations
--    (save/quit/close-buffer). Plugin-bound shortcuts live in each plugin's
--    module via the `nvim.keymaps` spine.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

---@type vim.keymap.set.Opts
local opts = { noremap = true, silent = true }

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param o vim.keymap.set.Opts?
local function map(mode, lhs, rhs, o)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, o or {}))
end

map("", "<Space>", "<Nop>")

-- ===== Behavior tweaks =====

-- Center cursor on vertical navigation
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search instance" })
map("n", "N", "Nzzzv", { desc = "Prev search instance" })

-- Resize with arrows
map("n", "<C-A-Left>", ":vertical resize -2<CR>")
map("n", "<C-A-Down>", ":resize +2<CR>")
map("n", "<C-A-Up>", ":resize -2<CR>")
map("n", "<C-A-Right>", ":vertical resize +2<CR>")

-- Window navigation
map("n", "<C-Left>", "<C-w>h")
map("n", "<C-Down>", "<C-w>j")
map("n", "<C-Up>", "<C-w>k")
map("n", "<C-Right>", "<C-w>l")

-- Buffer navigation
map("n", "<S-Right>", ":bnext<CR>")
map("n", "<S-Left>", ":bprevious<CR>")

-- Move text up and down
map("n", "<S-Down>", "mz:m+<cr>`z")
map("n", "<S-Up>", "mz:m-2<cr>`z")

-- Wrap-aware vertical motion
map("n", "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map("n", "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map("v", "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true })
map("v", "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Visual: stay in indent mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Visual: move text up and down
map("v", "<S-Down>", "mz:m+<cr>`zgv")
map("v", "<S-Up>", "mz:m-2<cr>`zgv")

-- Visual: paste without yanking the replaced text
map("v", "p", '"_dP')
map("n", "cp", '"_ciw<C-R>"<ESC>')

-- Visual block: move text up and down
map("x", "<S-Down>", ":move '>+1<CR>gv-gv")
map("x", "<S-Up>", ":move '<-2<CR>gv-gv")

-- Terminal: escape to normal
map("t", "<ESC>", "<C-\\><C-n>")

-- ===== User shortcuts =====

-- Save / quit / close buffer. Plain vim-builtin commands.
map("n", "<leader>w", "<cmd>w!<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q!<CR>", { desc = "Quit" })
map("n", "<leader>c", "<cmd>bd!<CR>", { desc = "Close buffer" })
map("n", "<leader>d", "<cmd>bp|bd#<CR>", { desc = "Close buffer (keep window)" })
