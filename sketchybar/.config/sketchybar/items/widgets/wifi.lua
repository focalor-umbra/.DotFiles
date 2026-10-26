local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec("killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0")

local popup_width = 360
local content_width = popup_width - 24
local title_width = 86
-- SketchyBar fixed text widths already include their text padding.
-- Fill the row exactly so unused width cannot accumulate on the right.
local text_font = { family = "Helvetica Neue", style = "Regular", size = 13 }
local function trim(value) return (value or ""):match("^%s*(.-)%s*$") end
local function quote(value) return "'" .. value:gsub("'", "'\\''") .. "'" end
local wifi = sbar.add("item", "wifi.wifi", {
    position = "right",
    icon = { font = { style = settings.font.style_map.Bold }, color = colors.sky },
    label = { font = { style = settings.font.style_map.Bold }, color = colors.sky },
    popup = {
        align = "right", drawing = "off", height = 34, y_offset = 6,
        background = { drawing = true, color = colors.base, border_color = colors.surface2,
            border_width = 1, corner_radius = 10, shadow = { drawing = true } }
    }
})

local function row(name, title)
    local item = sbar.add("item", "wifi." .. name, {
        position = "popup." .. wifi.name, width = content_width,
        padding_left = 12, padding_right = 12,
        background = { drawing = true, color = colors.transparent, corner_radius = 6, height = 30 },
        icon = { string = title, font = text_font, color = colors.sky,
            width = title_width, align = "left", padding_left = 8, padding_right = 0 },
        label = { string = "—", font = text_font, color = colors.sky,
            width = content_width - title_width, align = "right", padding_left = 0, padding_right = 8,
            max_chars = 32, scroll_duration = 160 }
    })
    item:subscribe("mouse.clicked", function()
        local value = item:query().label.value
        if value == "—" then return end
        sbar.exec("printf '%s' " .. quote(value) .. " | pbcopy")
    end)
    item:subscribe("mouse.entered", function() item:set({ background = { color = colors.surface0 } }) end)
    item:subscribe("mouse.exited", function() item:set({ background = { color = colors.transparent } }) end)
    return item
end

local ssid = row("ssid", "Network")
local hostname = row("hostname", "Hostname")
local ip = row("ip", "IP address")
local mask = row("mask", "Subnet mask")
local router = row("router", "Router")
local preferences = sbar.add("item", "wifi.settings", {
    position = "popup." .. wifi.name, width = content_width,
    padding_left = 12, padding_right = 12,
    background = { drawing = true, color = colors.transparent, corner_radius = 6,
        height = 30 },
    icon = { drawing = false },
    label = { string = "Network Settings…", font = text_font, color = colors.sky,
        align = "left", padding_left = 8, padding_right = 8 },
    click_script = "open 'x-apple.systempreferences:com.apple.Network-Settings.extension'"
})

local function hide_details() wifi:set({ popup = { drawing = "off" } }) end
local function get_connection_status()
    sbar.exec("ipconfig getifaddr en0", function(result)
        wifi:set({ icon = { string = trim(result) ~= "" and icons.wifi.connected or icons.wifi.disconnected } })
    end)
end
local function refresh(item, command)
    sbar.exec(command, function(result)
        local value = trim(result)
        item:set({ label = { string = value ~= "" and value or "—" } })
    end)
end
local function toggle_details(env)
    if env.NAME and env.NAME ~= wifi.name then return end
    if env.BUTTON == "right" then
        sbar.exec("open 'x-apple.systempreferences:com.apple.Network-Settings.extension'")
        return
    end
    if wifi:query().popup.drawing ~= "off" then hide_details(); return end
    sbar.set("widgets.battery", { popup = { drawing = "off" } })
    sbar.set("widgets.volume1", { popup = { drawing = "off" } })
    sbar.remove('/volume.device\\.*/')
    wifi:set({ popup = { drawing = "on" } })
    refresh(hostname, "networksetup -getcomputername")
    refresh(ip, "ipconfig getifaddr en0")
    refresh(ssid, "ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}'")
    refresh(mask, "networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'")
    refresh(router, "networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'")
end

wifi:subscribe("network_update", function(env)
    wifi:set({ label = { string = icons.wifi.upload .. env.upload .. icons.wifi.download .. env.download } })
end)
wifi:subscribe({ "wifi_change", "system_woke" }, get_connection_status)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)
preferences:subscribe("mouse.entered", function()
    preferences:set({ background = { color = colors.surface0 } })
end)
preferences:subscribe("mouse.exited", function()
    preferences:set({ background = { color = colors.transparent } })
end)
preferences:subscribe("mouse.clicked", hide_details)
get_connection_status()
