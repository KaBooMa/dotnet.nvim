local new_project = require("dotnet.dotnet.new_project")

local M = {}

function M.delegate(args)
	if args[1] == "new" then
		new_project()
	end
end

return M
