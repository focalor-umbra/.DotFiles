local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
    position = "right",
    icon = {
        font = {
            style = settings.font.style_map["Regular"]
        },
        color = colors.blue

    },
    label = {
        color = colors.blue
    },
    update_freq = 180,
    popup = {
        align = "center",
        drawing = "off"
    }
})

local remaining_time = sbar.add("item", {
    position = "popup." .. battery.name,
    icon = {
        string = "Time remaining:",
        width = 100,
        align = "left",
        font = {
            size = 15
        },
        color = colors.blue
    },
    label = {
        string = "??:??h",
        width = 100,
        align = "right",
        color = colors.blue
    }
})

local function battery_change(env)
    sbar.exec("pmset -g batt", function(batt_info)
        local icon = "!"
        local label = "?"

        local found, _, charge = batt_info:find("(%d+)%%")
        if found then
            charge = tonumber(charge)
            label = charge .. "%"
        end

        local charging, _, _ = batt_info:find("AC Power")

        if charging then
            icon = icons.battery.charging
        else
            if found and charge > 80 then
                icon = icons.battery._100
            elseif found and charge > 60 then
                icon = icons.battery._75
            elseif found and charge > 40 then
                icon = icons.battery._50
            elseif found and charge > 20 then
                icon = icons.battery._25
            else
                icon = icons.battery._0
            end
        end

        local lead = ""
        if found and charge < 10 then
            lead = "0"
        end

        battery:set({
            icon = {
                string = icon
            },
            label = {
                string = lead .. label
            }
        })
    end)
end

local function battery_collapse_details()
    if battery:query().popup.drawing == "on" then
        battery:set({
            popup = {
                drawing = "off"
            }
        })
    end
end

local function battery_expand_details()
    if battery:query().popup.drawing == "off" then
        battery:set({
            popup = {
                drawing = "on"
            }
        })
        sbar.exec("pmset -g batt", function(batt_info)
            local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
            local label = found and remaining .. "h" or "No estimate"
            remaining_time:set({
                label = label
            })
        end)
    else
        battery_collapse_details()
    end
end

battery:subscribe("mouse.clicked", battery_expand_details)
battery:subscribe("mouse.exited.global", battery_collapse_details)
battery:subscribe({"routine", "power_source_change", "system_woke"}, battery_change)

