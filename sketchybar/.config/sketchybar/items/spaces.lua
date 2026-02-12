local colors = require("colors")
local settings = require("settings")
local app_icons = require("app_icons")
local json = require("cjson")

local workspaces = {}
local app_variable = "app"
local subrole_variable = "subrole"

local function focusedWorkspace(focused_workspace)
    for workspace_index, workspace in pairs(workspaces) do
        workspace:set({
            icon = {
                highlight = workspace_index == tonumber(focused_workspace)
            },
            label = {
                highlight = workspace_index == tonumber(focused_workspace)
            }
        })
    end
end

local function redesignSpace(space)
    local command = string.format("yabai -m query --windows --space %d", space.index)
    sbar.exec(command, function(result, error_code)
        if error_code ~= 0 then
            print("Error executing command: " .. result)
            return ""
        end

        local icon_line = ""
        for _, window in pairs(result) do
            if window[subrole_variable] == "AXStandardWindow" then
                local app_name = window[app_variable]
                local icon_code = app_icons[app_name] or app_icons["Default"]
                icon_line = icon_line .. " " .. icon_code or ""
            end
        end

        workspaces[tonumber(space.index)]:set({
            label = {
                string = icon_line
            }
        })
    end)
end

local function designSpace(space, callback)
    local command = string.format("yabai -m query --windows --space %d", space.index)
    sbar.exec(command, function(result, error_code)
        if error_code ~= 0 then
            print("Error executing command: " .. result)
            if callback then
                callback()
            end
            return ""
        end
        local icon_line = ""
        for _, window in pairs(result) do
            if window[subrole_variable] == "AXStandardWindow" then
                print(window[app_variable])
                local app_name = window[app_variable]
                local icon_code = app_icons[app_name] or app_icons["Default"]
                icon_line = icon_line .. " " .. (icon_code or "")
            end
        end
        local workspace = sbar.add("item", {
            click_script = "yabai -m space --focus " .. tonumber(space.index)
        })
        workspaces[tonumber(space.index)] = workspace
        workspaces[tonumber(space.index)]:set({
            icon = {
                drawing = true,
                font = {
                    size = 16
                },
                color = colors.maroon,
                highlight_color = colors.peach,
                string = space.index
            },
            label = {
                drawing = true,
                string = icon_line,
                padding_right = 10,
                color = colors.maroon,
                highlight_color = colors.peach,
                font = "sketchybar-app-font:Regular:20.0",
                y_offset = -2
            },
            background = {
                drawing = true
            }
        })
        if callback then
            callback()
        end
    end)
end

sbar.exec("yabai -m query --spaces", function(result, exit_code)
    if result == nil then
        print("Error executing command: " .. result)
        return
    end
    if exit_code ~= 0 then
        print("Error executing command: " .. result)
        return
    end

    local bar = sbar.add("item", {
        background = {
            drawing = true,
            color = colors.maroon
        },
        icon = {
            drawing = false
        },
        label = {
            drawing = false
        }
    })
    bar:subscribe("yabai_space_change", function(event)
        sbar.exec("yabai -m query --spaces --space", function(result, exit_code)
            if result == nil then
                print("Error executing command: " .. result)
                return
            end
            if exit_code ~= 0 then
                print("Error executing command: " .. result)
                return
            end
            focusedWorkspace(result.index)
        end)
    end)
    bar:subscribe("yabai_window_created", function(event)
        sbar.exec("yabai -m query --spaces", function(result, exit_code)
            if result == nil or exit_code ~= 0 then
                return
            end
            for _, space in ipairs(result) do
                redesignSpace(space)
            end
        end)
    end)
    bar:subscribe("yabai_window_destroyed", function(event)
        sbar.exec("yabai -m query --spaces", function(result, exit_code)
            if result == nil or exit_code ~= 0 then
                return
            end
            for _, space in ipairs(result) do
                redesignSpace(space)
            end
        end)
    end)

    local spaces = {}
    for _, space in pairs(result) do
        table.insert(spaces, space)
    end
    table.sort(spaces, function(a, b)
        return a.index < b.index
    end)
    local function designSpacesSequentially(index)
        if index > #spaces then
            return
        end
        local space = spaces[index]
        designSpace(space, function()
            designSpacesSequentially(index + 1)
        end)
    end

    designSpacesSequentially(1)
end)
