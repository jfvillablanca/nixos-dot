local status_ok, autosession = pcall(require, "auto-session")
if not status_ok then
	return
end

-- local sessionlens = require("auto-session.session-lens")

autosession.setup({
	log_level = "error",
	auto_session_suppress_dirs = { "~/", "~/Downloads", "/" },
	auto_session_create_enabled = true,
	auto_save_enabled = true,
	auto_restore_enabled = true,
	auto_session_use_git_branch = false,
	auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
	-- session_lens = {
	--	theme_conf = { border = true },
	--	previewer = true,
	-- },
	cwd_change_handling = {
		restore_upcoming_session = true,
		pre_cwd_changed_hook = nil,
		-- post_cwd_changed_hook = function()
		-- 	require("lualine").refresh()
		-- end,
	},
})

-- vim.keymap.set("n", "<C-s>", sessionlens.search_session, {
--	noremap = true,
-- })
