-- Core nvim options. Sourced via `nvim.extraLuaConfig` with `lib.mkBefore`
-- priority so options are in place before any plugin loads.

---@type table<string, any>
local options = {
    backup = false,
    clipboard = "unnamedplus",
    cmdheight = 1,
    completeopt = { "menuone", "noselect" },
    conceallevel = 0,
    fileencoding = "utf-8",
    hlsearch = false,
    ignorecase = true,
    mouse = "a",
    pumheight = 10,
    showmode = false,
    showtabline = 0,
    smartcase = true,
    smartindent = true,
    splitbelow = true,
    splitright = true,
    swapfile = false,
    termguicolors = true,
    timeoutlen = 300,
    undofile = true,
    updatetime = 300,
    writebackup = false,
    expandtab = true,
    shiftwidth = 4,
    tabstop = 4,
    cursorline = true,
    number = true,
    relativenumber = true,
    numberwidth = 2,
    signcolumn = "yes",
    wrap = false,
    linebreak = true,
    scrolloff = 8,
    sidescrolloff = 8,
    colorcolumn = "80",
    whichwrap = "bs<>[]hl",
}

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.opt.shortmess:append("c")
vim.opt.iskeyword:append("-")
vim.opt.formatoptions:remove({ "c", "r", "o" })

-- Over SSH, route the +/* registers through OSC 52 so yanks on the
-- remote land in the *local* terminal's clipboard. No remote display
-- server needed. Locally, leave the auto-detected provider alone.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
        name = "OSC 52",
        copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
        paste = { ["+"] = osc52.paste("+"), ["*"] = osc52.paste("*") },
    }
end
