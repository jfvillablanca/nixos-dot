local status_ok, colemak = pcall(require, "colemak")
if not status_ok then
	return
end

colemak.setup({})
