-- lualine-nvim setup. Components are inline; if/when a plugin wants to
-- contribute dynamically, add a `nvim.statusline.components` spine and
-- read it here.

---@return boolean
local function hide_in_width()
    return vim.fn.winwidth(0) > 80
end

local diagnostics = {
    "diagnostics",
    sources = { "nvim_diagnostic" },
    sections = { "error", "warn" },
    symbols = { error = " ", warn = " " },
    colored = true,
    update_in_insert = false,
    always_visible = true,
}

local diff = {
    "diff",
    colored = true,
    symbols = { added = " ", modified = " ", removed = " " },
    cond = hide_in_width,
}

local mode = {
    "mode",
    fmt = function(str)
        return str
    end,
    color = { gui = "bold" },
}

local filetype = {
    "filetype",
    icons_enabled = true,
}

local filename = {
    "filename",
    symbols = {
        modified = "[+]",
        readonly = "",
        unnamed = "[Unnamed]",
        newfile = "[New]",
    },
    path = 4,
}

local branch = {
    "branch",
    icons_enabled = true,
    icon = "",
}

local location = {
    "location",
    padding = 0,
}

local lspserver = {
    ---@return string
    function()
        local buf_ft = vim.bo.filetype
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if next(clients) == nil then
            return "No Active Lsp"
        end
        for _, client in ipairs(clients) do
            local filetypes = client.config.filetypes
            if filetypes and vim.tbl_contains(filetypes, buf_ft) then
                return client.name
            end
        end
        return "No Active Lsp"
    end,
    icon = " ",
    color = { gui = "bold" },
}

require("lualine").setup({
    options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = { "alpha", "dashboard", "Outline" },
        always_divide_middle = true,
    },
    sections = {
        lualine_a = { mode },
        lualine_b = { branch, diagnostics },
        lualine_c = { filename },
        lualine_x = { diff, filetype },
        lualine_y = { location, lspserver },
        lualine_z = {},
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { filename },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
    },
    tabline = {},
    extensions = {},
})
