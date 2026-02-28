local get_file_namespace = require("dotnet.utils.get_file_namespace")

local FORBIDDEN_FILES_AND_FOLDERS = {
	"obj",
	"bin",
}

return function()
	-- rg --files --glob "*.lua"
	local ignore = table.concat(
		vim.tbl_map(function(item)
			return '--glob "!' .. item .. '"'
		end, FORBIDDEN_FILES_AND_FOLDERS),
		" "
	)
	local raw_class_paths = string.sub(vim.fn.system("rg --files " .. ignore .. ' --glob "*.cs"'), 1, -2)
	local class_paths = vim.split(raw_class_paths, "\n")

	local need_updated = {}
	for _, class_path in ipairs(class_paths) do
		if class_path == "" then
			goto continue_loop
		end
		local rg_namespace = vim.fn.system('rg --no-filename "namespace" "' .. class_path .. '"')

		-- Ignore classes that don't define namespaces for whatever reason they might have...
		if rg_namespace == "" then
			goto continue_loop
		end

		rg_namespace = string.sub(rg_namespace, 1, -2)
		local current_namespace = string.match(rg_namespace, "namespace%s+([%w_%.]+)") -- allow underscores in namespace
		local is_file_scoped = string.sub(rg_namespace, -1) == ";"
		local expected_namespace = get_file_namespace(class_path)

		if current_namespace ~= expected_namespace then
			table.insert(need_updated, {
				class_path = class_path,
				current_namespace = current_namespace,
				expected_namespace = expected_namespace,
				is_file_scoped = is_file_scoped,
			})
		end

		::continue_loop::
	end

	if #need_updated == 0 then
		vim.notify("All namespaces are valid.")
		return
	end

	local should_adjust_namespaces =
		vim.fn.confirm("Adjust namespace for " .. #need_updated .. " file(s)?", "&Yes\n&No\n&Ask", 2)
	local confirm_each_file = should_adjust_namespaces == 3

	-- Head out if they selected `No`
	if should_adjust_namespaces == 2 then
		return
	end

	local update_count = 0
	for _, update in ipairs(need_updated) do
		-- Read buffer lines
		local bufnr = vim.fn.bufnr(update.class_path, true)
		if bufnr == -1 then
			vim.notify("Could not open buffer for " .. update.class_path, vim.log.levels.ERROR)
			goto continue
		end

		-- Ensure the buffer is loaded
		if not vim.api.nvim_buf_is_loaded(bufnr) then
			vim.fn.bufload(bufnr)
		end

		if confirm_each_file then
			-- Create a full screen pop up that the user can read the original namespace (in theory) inside
			local display_win = vim.api.nvim_open_win(bufnr, false, {
				relative = "editor",
				row = 0,
				col = 0,
				width = vim.o.columns,
				height = vim.o.lines,
				style = "minimal",
				border = "rounded",
			})

			local should_replace_lines =
				vim.fn.confirm("Replace namespace with " .. update.expected_namespace .. "?", "&Yes\n&No", 2)

			-- Close the display pop up
			vim.api.nvim_win_close(display_win, true)

			if should_replace_lines == 2 then
				goto continue
			end
		end

		-- Update the namespace line
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		for i, line in ipairs(lines) do
			if line:match("^%s*namespace%s+") then
				local new_line = "namespace " .. update.expected_namespace .. (update.is_file_scoped and ";" or "")
				vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_line }) -- Lua is 1-indexed, Neovim API is 0-indexed
				update_count = update_count + 1
				break
			end
		end

		vim.api.nvim_buf_call(bufnr, function()
			vim.cmd("write")
		end)
		::continue::
	end
	-- This approach avoids external sed, works on all platforms, and updates the buffer in-place.

	vim.notify("Updated namespace for " .. update_count .. " file(s)!")
end
