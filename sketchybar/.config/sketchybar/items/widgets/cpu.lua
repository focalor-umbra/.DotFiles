local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("graph", "widgets.cpu", 50, {
    position = "right",
    graph = {
        color = colors.teal
    },
    icon = {
        string = icons.cpu,
        color = colors.teal
    },
    label = {
        drawing = false
    },
    background = {
        drawing = true

    }
})

cpu:subscribe("cpu_update", function(env)
    local load = tonumber(env.total_load)
    cpu:push({load / 100.})
end)

cpu:subscribe("mouse.clicked", function(env)
    sbar.exec("open -a 'Activity Monitor'")
end)

