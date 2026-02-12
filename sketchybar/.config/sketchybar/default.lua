local settings = require("settings")
local colors = require("colors")

sbar.default({
    updates = "when_shown",
    icon = {
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Bold"],
            size = 25
        },
        background = {
            image = {
                corner_radius = 10
            }
        },
        padding_left = settings.item_spacing,
        padding_right = settings.item_spacing
    },
    label = {
        font = {
            family = settings.font.text,
            style = settings.font.style_map["Semibold"],
            size = 14.0
        },
        padding_left = settings.item_spacing,
        padding_right = settings.item_spacing
    },
    background = {
        height = 30,
        corner_radius = 10,
        image = {
            corner_radius = 10
        },
        color = colors.bg2
    },
    popup = {
        background = {
            corner_radius = 10,
            shadow = {
                drawing = true
            }
        },
        blur_radius = 50
    },
    padding_left = settings.paddings,
    padding_right = settings.paddings,
    scroll_texts = true
})
