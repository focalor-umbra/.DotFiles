local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

local popup_width = 250

local volume = sbar.add("item", "widgets.volume1", {
    position = "right",
    icon = {
        string = icons.volume._100,
        font = {
            style = settings.font.style_map["Regular"]
        },
        color = colors.sapphire
    },
    label = {
        string = "??%",
        color = colors.sapphire
    },
    popup = {
        align = "center",
        drawing = "off"
    }
})

local volume_slider = sbar.add("slider", popup_width, {
    position = "popup." .. volume.name,
    slider = {
        highlight_color = colors.teal,
        background = {
            height = 6,
            corner_radius = 3,
            color = colors.crust
        },
        knob = {
            string = "",
            drawing = true
        }
    },
    click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

local function volume_change(env)
    local volume_value = tonumber(env.INFO)
    local icon = icons.volume._0
    if volume_value > 60 then
        icon = icons.volume._100
    elseif volume_value > 30 then
        icon = icons.volume._66
    elseif volume_value > 10 then
        icon = icons.volume._33
    elseif volume_value > 0 then
        icon = icons.volume._10
    end

    local lead = ""
    if volume_value < 10 then
        lead = "0"
    end

    volume:set({
        icon = icon
    })
    volume:set({
        label = lead .. volume_value .. "%"
    })
    volume_slider:set({
        slider = {
            percentage = volume_value
        }
    })
end

local function volume_collapse_details()
    if volume:query().popup.drawing == "off" then
        return
    else
        volume:set({
            popup = {
                drawing = "off"
            }
        })
        sbar.remove('/volume.device\\.*/')
    end
end

local function volume_toggle_details(env)
    if env.BUTTON == "right" then
        sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
        return
    end

    if volume:query().popup.drawing == "off" then
        sbar.exec("SwitchAudioSource -t output -c", function(result)
            local current_audio_device = result:sub(1, -2)
            sbar.exec("SwitchAudioSource -a -t output", function(available)
                local counter = 0
                for device in string.gmatch(available, '[^\n]+') do
                    local device = sbar.add("item", "volume.device." .. counter, {
                        position = "popup." .. volume.name,
                        align = "center",
                        width = popup_width,
                        label = {
                            string = device,
                            color = (current_audio_device == device) and colors.teal or colors.base
                        },
                        background = {
                            color = colors.sapphire
                        },
                        click_script = 'SwitchAudioSource -s "' .. device ..
                            '" && sketchybar --set /volume.device\\.*/ label.color=' .. colors.base ..
                            ' --set $NAME label.color=' .. colors.base

                    })
                    counter = counter + 1
                end
            end)
        end)
        volume:set({
            popup = {
                drawing = "on"
            }
        })

    else
        volume_collapse_details()
    end
end

local function volume_scroll(env)
    local delta = env.SCROLL_DELTA
    sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end

volume:subscribe("mouse.clicked", volume_toggle_details)
volume:subscribe("mouse.exited.global", volume_collapse_details)
volume:subscribe("mouse.scrolled", volume_scroll)
volume:subscribe("volume_change", volume_change)

