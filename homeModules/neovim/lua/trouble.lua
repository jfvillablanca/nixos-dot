local present, trouble = pcall(require, "trouble")
if not present then
    return
end

trouble.setup({
    auto_refresh = false,
})
