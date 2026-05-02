local refactoring_status_ok, refactoring = pcall(require, "refactoring")
if not refactoring_status_ok then
	return
end

refactoring.setup({
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

-- load refactoring Telescope extension
require("telescope").load_extension("refactoring")
