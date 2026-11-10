local colors = require("colors")
local icons = require("icons")

local popup_width = 300
local text_font = { family = "Helvetica Neue", style = "Regular", size = 13 }
local devices = {}
local generation = 0
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local function trim(value) return (value or ""):match("^%s*(.-)%s*$") end

local volume = sbar.add("item", "widgets.volume1", {
    position = "right",
    icon = { string = icons.volume._100, color = colors.sapphire },
    label = { string = "??%", color = colors.sapphire },
    popup = {
        align = "right", drawing = "off", height = 34, y_offset = 6,
        background = {
            drawing = true, color = colors.base, border_color = colors.surface2,
            border_width = 1, corner_radius = 10, shadow = { drawing = true }
        }
    }
})

sbar.add("item", "volume.heading", {
    position = "popup." .. volume.name, width = popup_width - 24,
    padding_left = 12, padding_right = 12, background = { drawing = false },
    icon = { drawing = false },
    label = { string = "Sound output", font = text_font, color = colors.sapphire,
        align = "left", padding_left = 8, padding_right = 8 }
})

local volume_slider = sbar.add("slider", "volume.slider", popup_width - 24, {
    position = "popup." .. volume.name,
    padding_left = 12, padding_right = 12,
    background = { drawing = false },
    icon = { drawing = false }, label = { drawing = false },
    slider = {
        highlight_color = colors.sapphire,
        background = { height = 5, corner_radius = 3, color = colors.surface1 },
        knob = { string = "●", font = { family = "Helvetica Neue", size = 15 },
            color = colors.sapphire, drawing = true }
    },
    click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

local function collapse()
    generation = generation + 1
    volume:set({ popup = { drawing = "off" } })
    sbar.remove('/volume.device\\.*/')
    devices = {}
end

local function select_device(name)
    sbar.exec("SwitchAudioSource -t output -s " .. quote(name), function(_, code)
        if code ~= 0 then return end
        for _, entry in ipairs(devices) do
            entry.item:set({ icon = { string = entry.name == name and "✓" or "" },
                label = { color = colors.sapphire } })
        end
    end)
end

local function toggle(env)
    if env.NAME and env.NAME ~= volume.name then return end
    if env.BUTTON == "right" then
        sbar.exec("open 'x-apple.systempreferences:com.apple.Sound-Settings.extension'")
        return
    end
    if volume:query().popup.drawing ~= "off" then collapse(); return end
    devices = {}
    sbar.remove('/volume.device\\.*/')
    generation = generation + 1
    local request = generation
    -- Close the other dropdown so two panels cannot overlap.
    sbar.set("widgets.battery", { popup = { drawing = "off" } })
    sbar.set("wifi.wifi", { popup = { drawing = "off" } })
    volume:set({ popup = { drawing = "on" } })
    sbar.exec("SwitchAudioSource -t output -c", function(current)
        if request ~= generation then return end
        current = trim(current)
        sbar.exec("SwitchAudioSource -a -t output", function(available, code)
            if request ~= generation or volume:query().popup.drawing == "off" then return end
            if code ~= 0 then return end
            for name in (available or ""):gmatch("[^\n]+") do
                local device_name = trim(name)
                local item = sbar.add("item", "volume.device." .. (#devices + 1), {
                    position = "popup." .. volume.name, width = popup_width - 24,
                    padding_left = 12, padding_right = 12,
                    background = { drawing = true, color = colors.transparent, corner_radius = 6, height = 30 },
                    icon = { drawing = true, string = current == device_name and "✓" or "",
                        font = text_font, color = colors.sapphire, width = 20,
                        padding_left = 8, padding_right = 4 },
                    label = { string = device_name, font = text_font, max_chars = 36,
                        color = colors.sapphire,
                        align = "left", padding_left = 0, padding_right = 8 }
                })
                table.insert(devices, { name = device_name, item = item })
                item:subscribe("mouse.clicked", function() select_device(device_name) end)
                item:subscribe("mouse.entered", function() item:set({ background = { color = colors.surface0 } }) end)
                item:subscribe("mouse.exited", function() item:set({ background = { color = colors.transparent } }) end)
            end
        end)
    end)
end

volume:subscribe("mouse.clicked", toggle)
volume:subscribe("mouse.exited.global", collapse)
volume:subscribe("mouse.scrolled", function(env)
    local delta = tonumber(env.SCROLL_DELTA) or 0
    sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)
volume:subscribe("volume_change", function(env)
    local value = tonumber(env.INFO)
    if not value then return end
    local icon = value > 60 and icons.volume._100 or value > 30 and icons.volume._66
        or value > 10 and icons.volume._33 or value > 0 and icons.volume._10 or icons.volume._0
    volume:set({ icon = { string = icon }, label = { string = string.format("%02d%%", value) } })
    volume_slider:set({ slider = { percentage = value } })
end)
