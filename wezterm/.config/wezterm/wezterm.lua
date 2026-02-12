local wezterm = require "wezterm";
local string = require "string";
local act = wezterm.action
local config = wezterm.config_builder();
local home = wezterm.home_dir

local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider

local color = {
    mocha = {
        rosewater = "#f5e0dc",
        flamingo = "#f2cdcd",
        pink = "#f5c2e7",
        mauve = "#cba6f7",
        red = "#f38ba8",
        maroon = "#eba0ac",
        peach = "#fab387",
        yellow = "#f9e2af",
        green = "#a6e3a1",
        teal = "#94e2d5",
        sky = "#89dceb",
        sapphire = "#74c7ec",
        blue = "#89b4fa",
        lavender = "#b4befe",
        text = "#cdd6f4",
        subtext1 = "#bac2de",
        subtext0 = "#a6adc8",
        overlay2 = "#9399b2",
        overlay1 = "#7f849c",
        overlay0 = "#6c7086",
        surface2 = "#585b70",
        surface1 = "#45475a",
        surface0 = "#313244",
        base = "#1e1e2e",
        mantle = "#181825",
        crust = "#11111b"
    }
}

function tab_title(tab_info)
    local title = tab_info.active_pane.title
    if title and string.len(title) > 0 then
        if title == '~' then
            return "home"
        elseif title == '/' then
            return "root"
        end
        return title
    end
    return tab_info.tab_title
end

local function interpolate_color(color1, color2, factor)
    local function hex_to_rgb(hex)
        return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
    end

    local function rgb_to_hex(r, g, b)
        return string.format("#%02x%02x%02x", r, g, b)
    end

    local r1, g1, b1 = hex_to_rgb(color1)
    local r2, g2, b2 = hex_to_rgb(color2)

    local r = r1 + (r2 - r1) * factor
    local g = g1 + (g2 - g1) * factor
    local b = b1 + (b2 - b1) * factor

    return rgb_to_hex(math.floor(r), math.floor(g), math.floor(b))
end

local function create_gradient_background_title(title, colors, foreground)
    local gradient_title = {}
    local length = string.len(title)
    local num_colors = #colors
    for i = 1, length do
        local factor = (i - 1) / (length - 1)
        local color_index = math.floor(factor * (num_colors - 1)) + 1
        local next_color_index = math.min(color_index + 1, num_colors)
        local local_factor = (factor * (num_colors - 1)) % 1

        local color = interpolate_color(colors[color_index], colors[next_color_index], local_factor)
        table.insert(gradient_title, {
            Background = {
                Color = color
            }
        })
        table.insert(gradient_title, {
            Foreground = {
                Color = foreground
            }
        })
        table.insert(gradient_title, {
            Attribute = {
                Intensity = "Bold"
            }
        })
        table.insert(gradient_title, {
            Text = title:sub(i, i)
        })
    end

    return gradient_title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local background_colors = {}
    local foreground_left = nil
    local foreground_right = nil
    local foreground = nil
    if tab.is_active then
        background_colors = {color.mocha.red, color.mocha.maroon}
        foreground_left = color.mocha.red
        foreground_right = color.mocha.maroon
        foreground = color.mocha.crust
    elseif hover then
        background_colors = {color.mocha.peach, color.mocha.yellow}
        foreground_left = color.mocha.peach
        foreground_right = color.mocha.yellow
        foreground = color.mocha.crust
    else
        background_colors = {color.mocha.sapphire, color.mocha.blue}
        foreground_left = color.mocha.sapphire
        foreground_right = color.mocha.blue
        foreground = color.mocha.crust
    end

    local title = tab_title(tab)
    if string.len(tab_title(tab)) >= max_width then
        title = wezterm.truncate_right(tab_title(tab), max_width - 2)
    end

    local gradient_title = create_gradient_background_title(title, background_colors, foreground)
    table.insert(gradient_title, 1, {
        Text = SOLID_LEFT_ARROW
    })
    table.insert(gradient_title, 1, {
        Foreground = {
            Color = foreground_left
        }
    })
    table.insert(gradient_title, 1, {
        Background = {
            Color = "none"
        }
    })
    table.insert(gradient_title, {
        Foreground = {
            Color = foreground_right
        }
    })
    table.insert(gradient_title, {
        Background = {
            Color = "none"
        }
    })
    table.insert(gradient_title, {
        Text = SOLID_RIGHT_ARROW
    })
    return wezterm.format(gradient_title)
end)

config = {
    automatically_reload_config = true,
    background = {{
        opacity = 0.85,
        source = {
            Color = color.mocha.base
        },
        height = "100%",
        width = "100%"
    }},
    color_scheme = "Catppuccin Mocha",
    colors = {
        tab_bar = {
            background = "none",
            new_tab = {
                bg_color = color.mocha.surface0,
                fg_color = color.mocha.text
            },
            new_tab_hover = {
                bg_color = color.mocha.surface1,
                fg_color = color.mocha.text
            }
        }
    },
    default_cursor_style = "BlinkingBar",
    default_prog = {'/opt/homebrew/bin/nu'},
    enable_tab_bar = true,
    font = wezterm.font("FiraCode Nerd Font Mono"),
    font_size = 16.0,
    hide_mouse_cursor_when_typing = true,
    keys = {{
        key = 'UpArrow',
        mods = 'SHIFT',
        action = act.ScrollByPage(-0.5)
    }, {
        key = 'DownArrow',
        mods = 'SHIFT',
        action = act.ScrollByPage(0.5)
    }},
    scrollback_lines = 10000,
    set_environment_variables = {
        XDG_CONFIG_HOME = home .. '/.config',
        STARSHIP_CONFIG = home .. '/.config/starship/config.toml'
    },
    tab_bar_at_bottom = true,
    tab_max_width = 14,
    use_fancy_tab_bar = false,
    window_close_confirmation = "NeverPrompt",
    window_decorations = "RESIZE",
    window_padding = {
        left = 20,
        right = 20,
        top = 20,
        bottom = 20
    }
}

return config;
