return function(path)
	-- TODO: Find a more concrete way that is OS-agnostic
	local delimiter = "/"

	-- Table with each part of the path (folders and file)
	-- ex: ["this", "is", "folders", "class.cs"]
	local path_parts = vim.split(path, delimiter)
	vim.notify("path:" .. path)

	-- Remove the file name from the path
	-- ex: ["this", "is", "folders"]
	table.remove(path_parts)

	-- Find the .csproj to use as the "root" of the project
	-- HACK: This entire while loop feels wrong. Need to find a better way to determine `project_file_name`
	-- RootNamespace also could exist and not match the file.
	local found_project_root = false
	local namespace_parts = {}
	while not found_project_root do
		local current_path = table.concat(path_parts, delimiter)
		vim.notify("c: " .. current_path)
		local glob_path = #path_parts > 0 and (current_path .. delimiter .. "*.csproj") or "*.csproj"
		local found = vim.fn.glob(glob_path)
		vim.notify("g:" .. glob_path)
		vim.notify("|" .. tostring(found ~= "") .. "|")

		if found ~= "" then
			found_project_root = true
			local project_file_name = string.gsub(found, ".csproj", "")
			table.insert(namespace_parts, 1, project_file_name)
			break
		end
		if #path_parts > 0 then
			table.insert(namespace_parts, 1, table.remove(path_parts))
		else
			break
		end
	end

	-- Setup the namespace we will use
	local namespace = "MyNamespace"
	if found_project_root then
		namespace = table.concat(namespace_parts, ".")
	end
	vim.notify("ns: " .. namespace)

	return namespace
end
