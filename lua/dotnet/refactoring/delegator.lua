local rename_namespaces = require("dotnet.refactoring.rename_namespaces")

local M = {}

function M.delegate(args)
	if args[1] == "namespaces" then
		rename_namespaces()
	end
end

return M
