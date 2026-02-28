return function()
	local output = vim.fn.system("dotnet new list")
	local lines = vim.split(output, "\n")
	local remove_lines_count = 4

	-- Remove headers
	for i = 1, remove_lines_count do
		table.remove(lines, 1)
	end

	-- Remove footer
	table.remove(lines)

	local templates = {}
	for _, line in ipairs(lines) do
		-- example line: API Controller                                apicontroller                 [C#]        Web/ASP.NET
		local name, identifier = string.match(line, "^(.-)%s%s+(.-)%s%s+")
		table.insert(templates, {
			identifier = identifier,
			name = name,
		})
	end

	return templates
end
