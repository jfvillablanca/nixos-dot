require("refactoring").setup({
    prompt_func_return_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
    },
    prompt_func_param_type = {
        go = false,
        java = false,
        cpp = false,
        c = false,
        h = false,
        hpp = false,
        cxx = false,
    },
    printf_statements = {},
    print_var_statements = {},
})

-- Telescope extension is loaded lazily; pcall in case telescope isn't ready yet.
pcall(function()
    require("telescope").load_extension("refactoring")
end)
