local status_ok, comment = pcall(require, "Comment")
if not status_ok then
    return
end

-- local status_ok, ts_context = pcall(require, "ts_context_commentstring")
-- if not status_ok then
-- 	return
-- end

comment.setup({
    -- Integration with 'JoosepAlviste/nvim-ts-context-commentstring'
    -- pre_hook = ts_context.integrations.comment_nvim.create_pre_hook(),
    -- ignore = '^$',
})
