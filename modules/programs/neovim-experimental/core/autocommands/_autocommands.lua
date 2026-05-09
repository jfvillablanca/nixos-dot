-- Core autocommands. Modern lua API; replaces the vim.cmd([[ augroup ... ]])
-- form in modules/programs/neovim/lua/autocommands.lua.

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Quick-close keymap for help-style buffers.
autocmd("FileType", {
    group = augroup("NvimCoreCloseWithQ", { clear = true }),
    pattern = { "qf", "help", "man", "lspinfo", "startuptime", "checkhealth" },
    ---@param args { buf: integer }
    callback = function(args)
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
    end,
})

-- Briefly highlight yanked text. Defaults: higroup=IncSearch, timeout=150
autocmd("TextYankPost", {
    group = augroup("NvimCoreYankHighlight", { clear = true }),
    callback = function()
        pcall(vim.hl.on_yank)
    end,
})

-- Don't auto-insert comment leader on Enter / o / O.
autocmd("BufWinEnter", {
    group = augroup("NvimCoreFormatoptions", { clear = true }),
    callback = function()
        vim.opt_local.formatoptions:remove({ "c", "r", "o" })
    end,
})

-- Wrap + spell for prose-y filetypes.
autocmd("FileType", {
    group = augroup("NvimCoreProse", { clear = true }),
    pattern = { "gitcommit", "markdown" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

-- Quickfix shouldn't appear in :ls.
autocmd("FileType", {
    group = augroup("NvimCoreQfNobuflisted", { clear = true }),
    pattern = "qf",
    callback = function()
        vim.opt_local.buflisted = false
    end,
})

-- Equalize splits on terminal resize.
autocmd("VimResized", {
    group = augroup("NvimCoreAutoResize", { clear = true }),
    callback = function()
        vim.cmd("tabdo wincmd =")
    end,
})
