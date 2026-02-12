local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

sbar.exec(
    "killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0")

local popup_width = 250

local wifi = sbar.add("item", "wifi.wifi", {
    position = "right",
    icon = {
        font = {
            style = settings.font.style_map["Bold"]
        },
        color = colors.sky
    },
    label = {
        font = {
            style = settings.font.style_map["Bold"]
        },
        color = colors.sky
    },
    popup = {
        align = "center"
    }
})

local ssid = sbar.add("item", {
    position = "popup." .. wifi.name,
    icon = {
        font = {
            style = settings.font.style_map["Bold"]
        },
        string = icons.wifi.router
    },
    width = popup_width,
    align = "center",
    label = {
        font = {
            size = 15,
            style = settings.font.style_map["Bold"]
        },
        max_chars = 18,
        string = "????????????"
    },
    background = {
        color = colors.sky
    }

})

local hostname = sbar.add("item", {
    position = "popup." .. wifi.name,
    icon = {
        align = "left",
        string = "Hostname:",
        width = popup_width / 2,
        font = {
            size = 15
        }
    },
    label = {
        max_chars = 20,
        string = "????????????",
        width = popup_width / 2,
        align = "right"
    },
    background = {
        color = colors.sky
    }

})

local ip = sbar.add("item", {
    position = "popup." .. wifi.name,
    icon = {
        align = "left",
        string = "IP:",
        width = popup_width / 2,
        font = {
            size = 15
        }

    },
    label = {
        string = "???.???.???.???",
        width = popup_width / 2,
        align = "right"
    },
    background = {
        color = colors.sky
    }

})

local mask = sbar.add("item", {
    position = "popup." .. wifi.name,
    icon = {
        align = "left",
        string = "Subnet mask:",
        width = popup_width / 2,
        font = {
            size = 15
        }

    },
    label = {
        string = "???.???.???.???",
        width = popup_width / 2,
        align = "right"
    },
    background = {
        color = colors.sky
    }

})

local router = sbar.add("item", {
    position = "popup." .. wifi.name,
    icon = {
        align = "left",
        string = "Router:",
        width = popup_width / 2,
        font = {
            size = 15
        }

    },
    label = {
        string = "???.???.???.???",
        width = popup_width / 2,
        align = "right"
    },
    background = {
        color = colors.sky
    }

})

local function network_update(env)
    wifi:set({
        label = {
            string = icons.wifi.upload .. env.upload .. icons.wifi.download .. env.download
        }
    })
end

local function get_connection_status(env)
    sbar.exec("ipconfig getifaddr en0", function(ip)
        local connected = not (ip == "")
        wifi:set({
            icon = {
                string = connected and icons.wifi.connected or icons.wifi.disconnected
            }
        })
    end)

end

local function hide_details()
    wifi:set({
        popup = {
            drawing = "off"
        }
    })
end

local function toggle_details()
    if wifi:query().popup.drawing == "off" then
        wifi:set({
            popup = {
                drawing = "on"
            }
        })
        sbar.exec("networksetup -getcomputername", function(result)
            hostname:set({
                label = result
            })
        end)
        sbar.exec("ipconfig getifaddr en0", function(result)
            ip:set({
                label = result
            })
        end)
        sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
            ssid:set({
                label = result
            })
        end)
        sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
            mask:set({
                label = result
            })
        end)
        sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
            router:set({
                label = result
            })
        end)
    else
        hide_details()
    end
end

local function copy_label_to_clipboard(env)
    local label = sbar.query(env.NAME).label.value
    sbar.exec("echo \"" .. label .. "\" | pbcopy")
    sbar.set(env.NAME, {
        label = {
            string = icons.clipboard,
            align = "center"
        }
    })
    sbar.delay(1, function()
        sbar.set(env.NAME, {
            label = {
                string = label,
                align = "right"
            }
        })
    end)
end

wifi:subscribe("network_update", network_update)
wifi:subscribe({"wifi_change", "system_woke"}, get_connection_status)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
