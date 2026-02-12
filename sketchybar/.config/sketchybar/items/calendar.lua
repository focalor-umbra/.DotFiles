local settings = require("settings")
local colors = require("colors")
local icons = require("icons")

local cal = sbar.add("item", {
    icon = {
        string = icons.calendar,
        color = colors.lavender

    },
    label = {
        color = colors.lavender,
        align = "right"
    },
    position = "right",
    update_freq = 1
})

cal:subscribe({"forced", "routine", "system_woke"}, function(env)
    cal:set({
        label = os.date("%a. %d/%m/%Y %H:%M:%S")
    })
end)
