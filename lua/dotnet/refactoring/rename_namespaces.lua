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
    local need_updated_count = 0
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

        if current_namespace ~= expected_namespace and need_updated[current_namespace] == nil then
            local function escape_for_pattern(str)
                return string.gsub(str, "([\\/&])", "\\%1")
            end

            local escaped_current = escape_for_pattern(current_namespace)
            local escaped_expected = escape_for_pattern(expected_namespace)

            need_updated[current_namespace] = {
                class_path = class_path,
                current_namespace = escaped_current,
                expected_namespace = escaped_expected,
                is_file_scoped = is_file_scoped,
            }
            need_updated_count = need_updated_count + 1
        end

        ::continue_loop::
    end

    if need_updated_count == 0 then
        vim.notify("All namespaces are valid.")
        return
    end

    local should_adjust_namespaces =
        vim.fn.confirm("Adjust " .. need_updated_count .. " namespace(s)?", "&Yes\n&No\n&Ask", 2)
    local confirm_each_file = should_adjust_namespaces == 3

    -- Head out if they selected `No`
    if should_adjust_namespaces == 2 then
        return
    end

    local update_count = 0
    for _, update in pairs(need_updated) do
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

        -- Update the namespace within all files, where found
        vim.cmd(':grep! "' .. update.current_namespace .. '" **/*.cs')
        -- This replacement matches complete C# namespace usages, assignments, and declarations
        vim.cmd(
            ':cfdo ' ..
            '%s/\\<using ' .. update.current_namespace .. '\\>;/using ' .. update.expected_namespace .. ';/ge | ' ..
            '%s/\\<namespace ' ..
            update.current_namespace .. '\\>;/namespace ' .. update.expected_namespace .. ';/ge | ' ..
            '%s/\\<namespace ' ..
            update.current_namespace .. '\\>/namespace ' .. update.expected_namespace .. '/ge | ' ..
            '%s/\\<using \\([^=]*= ' ..
            update.current_namespace .. '\\)\\>;/using \\1' .. update.expected_namespace .. ';/ge | ' ..
            'update'
        )
        update_count = update_count + 1

        ::continue::
    end
    -- This approach avoids external sed, works on all platforms, and updates the buffer in-place.

    vim.notify("Updated namespace for " .. update_count .. " file(s)!")
end
