local comment_status_ok, comment = pcall(require, "Comment")
if not comment_status_ok then
	return
end

local context_status_ok, ts_context = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
if not context_status_ok then
	return
end

comment.setup({
	-- Integration with 'JoosepAlviste/nvim-ts-context-commentstring'
	pre_hook = ts_context.create_pre_hook(),
	ignore = "^$",
})
