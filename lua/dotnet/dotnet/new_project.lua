local telescope = require("telescope")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local picker = require("telescope.pickers")
local get_templates = require("dotnet.dotnet.get_templates")

local function select_folder(title, callback)
	telescope.extensions.file_browser.file_browser({
		-- select_buffer = true,
		files = false,
		depth = 10,
		prompt_title = title,
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				local entry = action_state.get_selected_entry()
				actions.close(prompt_bufnr)
				print("Selected directory: " .. entry.value)
				callback(entry.value)
				-- Do something with the selected directory here
			end)
			return true
		end,
	})
end

return function()
	local templates = get_templates()
	select_folder("Where To Create New Project", function(path)
		picker
			.new({}, {
				prompt_title = "Select a Project Template",
				finder = finders.new_table({
					results = templates,
					entry_maker = function(entry)
						return {
							value = entry.identifier,
							display = entry.name,
							ordinal = entry.name,
						}
					end,
				}),
				sorter = require("telescope.config").values.generic_sorter({}),
				attach_mappings = function(_, map)
					actions.select_default:replace(function(prompt_bufnr)
						actions.close(prompt_bufnr)
						local selection = require("telescope.actions.state").get_selected_entry()
						local input = vim.fn.input("Project Name: ")
						if input == nil then
							return
						end

						vim.fn.jobstart({ "dotnet", "new", selection.value, "--name", input }, {
							cwd = path,
							on_exit = function(_, code, _)
								if code == 0 then
									vim.notify("Project created successfully!", vim.log.levels.INFO)
								else
									vim.notify("Project creation failed, exit code: " .. code, vim.log.levels.ERROR)
								end
							end,
						})
					end)
					return true
				end,
			})
			:find()
		vim.fn.jobstart({ "dotnet", "new" })
	end)
end
