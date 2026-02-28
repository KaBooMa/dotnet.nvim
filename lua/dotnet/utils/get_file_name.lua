return function(path)
	-- TODO: See msg in get_file_namespace.lua
	-- Need to accomplish same here.
	local delimiter = "/"
	local parts = vim.split(path, delimiter)
	return parts[#parts]
end
