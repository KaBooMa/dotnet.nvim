local get_file_name = require("dotnet.utils.get_file_name")
local get_file_namespace = require("dotnet.utils.get_file_namespace")

local M = {}

vim.api.nvim_create_autocmd("BufReadPost", {
	pattern = "*.cs",
	callback = function(args)
		local bufnr = args.buf
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		-- Only bootstrap if buffer is empty
		if #lines == 1 and lines[1] == "" then
			vim.schedule(function()
				-- This gets the current buffer path (relative to workspace)
				local file_path = vim.fn.expand("%:~:.")

				local file_name = get_file_name(file_path)
				local namespace = get_file_namespace(file_path)

				local declaration_name = file_name:match("([^.]+)") or "Class1"
				local is_interface = string.sub(declaration_name, 1, 1) == "I"
					and string.match(string.sub(declaration_name, 2, 2), "%u")
				local declaration_type = is_interface and "interface" or "class"

				local template = {
					string.format("namespace %s;", namespace),
					"",
					string.format("public %s %s", declaration_type, declaration_name),
					"{",
					"    ",
					"}",
				}
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, template)
				vim.api.nvim_win_set_cursor(0, { 5, 8 }) -- put cursor in class body indent
			end)
		end
	end,
})

return {}
