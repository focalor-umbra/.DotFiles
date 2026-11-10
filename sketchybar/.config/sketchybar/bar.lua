local colors = require("colors")

sbar.bar({
    topmost = "window",
    height = 40,
    color = colors.with_alpha(colors.bar.bg, 0.5),
    padding_right = 15,
    padding_left = 15
})
