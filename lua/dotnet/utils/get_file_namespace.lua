return function(path)
	-- TODO: Find a more concrete way that is OS-agnostic
	local delimiter = "/"

	-- Table with each part of the path (folders and file)
	-- ex: ["this", "is", "folders", "class.cs"]
	local path_parts = vim.split(path, delimiter)

	-- Remove the file name from the path
	-- ex: ["this", "is", "folders"]
	table.remove(path_parts)

	-- Find the .csproj to use as the "root" of the project
	local found_project_root = false
	local namespace_parts = {}
	while #path_parts > 0 and not found_project_root do
		local path = table.concat(path_parts, delimiter)
		local found = vim.fn.glob(path .. delimiter .. "*.csproj")
		table.insert(namespace_parts, 1, table.remove(path_parts))
		if found ~= "" then
			found_project_root = true
			break
		end
	end

	-- Setup the namespace we will use
	local namespace = "MyNamespace"
	if found_project_root then
		namespace = table.concat(namespace_parts, ".")
	end

	return namespace
end
