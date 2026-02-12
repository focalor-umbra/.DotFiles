local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local apple = sbar.add("item", {
    icon = {
        string = icons.apple,
        padding_right = 8,
        padding_left = 8,
        color = colors.red
    },
    label = {
        drawing = false
    },
    click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s 0"
})
