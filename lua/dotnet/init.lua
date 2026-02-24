local telescope = require("telescope")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local picker = require("telescope.pickers")
local M = {}

M.setup = function(opts) end

function M.get_templates()
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

function M.select_folder(title, callback)
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

function M.new_project_selector()
    local templates = M.get_templates()
    M.select_folder("Where To Create New Project", function(path)
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

vim.api.nvim_create_user_command("DotnetNewProject", M.new_project_selector, {})

return M
