sbar = require("sketchybar")
sbar.begin_config()
require("bar")
require("default")
require("items")
sbar.end_config()
-- The lock keeps one monitor alive across configuration reloads.
sbar.exec('"' .. os.getenv("CONFIG_DIR") .. '/helpers/menu_toggle/bin/sb-menu-toggle"'
    .. ' --lock-file "' .. os.getenv("CONFIG_DIR")
    .. '/helpers/menu_toggle/bin/monitor.lock" >/dev/null 2>&1 &')
sbar.event_loop()
