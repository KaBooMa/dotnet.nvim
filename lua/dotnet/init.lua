local refactor_delegator = require("dotnet.refactoring.delegator")
local dotnet_delegator = require("dotnet.dotnet.delegator")

-- Import assists
require("dotnet.assists.bootstrap_files")

local M = {}

M.setup = function(opts) end

vim.api.nvim_create_user_command("Dotnet", function(opts)
	local args = opts.fargs
	if args[1] == "refactor" then
		table.remove(args, 1)
		refactor_delegator.delegate(args)
	elseif args[1] == "project" then
		table.remove(args, 1)
		dotnet_delegator.delegate(args)
	end
end, {
	nargs = "+", -- Require at least one argument, support multiple
	desc = "Dotnet.nvim",
	complete = function(arg_lead, cmd_line, cursor_pos)
		local split = vim.split(cmd_line, "%s+")
		if #split == 2 then
			return { "refactor", "project" }
		elseif split[2] == "refactor" then
			return { "namespaces" }
		elseif split[2] == "project" then
			return { "new" }
		end
	end,
})

return M
