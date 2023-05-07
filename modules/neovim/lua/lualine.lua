local status_ok, lualine = pcall(require, "lualine")
if not status_ok then
	return
end

local hide_in_width = function()
	return vim.fn.winwidth(0) > 80
end

local diagnostics = {
	"diagnostics",
	sources = { "nvim_diagnostic" },
	sections = { "error", "warn" }, -- [possible values] sections = { "error", "warn", "info", "hint", },
	symbols = { error = " ", warn = " " }, -- [possible values] symbols = { error = " ", warn = " ", info = "󰋼 ", hint = "󰌵 " },
	colored = true,
	update_in_insert = false,
	always_visible = true,
}

local diff = {
	"diff",
	colored = true,
	symbols = { added = " ", modified = " ", removed = " " }, -- changes diff symbols
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
		modified = "[+]",       -- Text to show when the file is modified.
		readonly = "",         -- Text to show when the file is non-modifiable or readonly.
		unnamed = "[Unnamed]",  -- Text to show for unnamed buffers.
		newfile = "[New]",      -- Text to show for newly created file before first write
	},
	path = 4,                   -- 0: Just the filename
	                            -- 1: Relative path
	                            -- 2: Absolute path
	                            -- 3: Absolute path, with tilde as the home directory
	                            -- 4: Filename and parent dir, with tilde as the home directory
}

local branch = {
	"branch",
	icons_enabled = true,
	icon = "",
}

local location = {
	"location",
	padding = 0,
}

local lspserver = {
	function()
		local msg = "No Active Lsp"
		local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
		local clients = vim.lsp.get_active_clients()
		if next(clients) == nil then
			return msg
		end
		for _, client in ipairs(clients) do
			local filetypes = client.config.filetypes
			if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
				return client.name
			end
		end
		return msg
	end,
	icon = " ",
	color = { gui = "bold" },
}

lualine.setup({
	options = {
		icons_enabled = true,
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
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
