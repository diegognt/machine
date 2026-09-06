-- Hyprland Lua configuration
-- Refer to the wiki for more information: https://wiki.hypr.land/Configuring/Start/

require("monitors")
require("programs")
require("environment")
require("look_and_feel")
require("misc")
require("input")
require("keybindings")
require("rules")

hl.on("hyprland.start", function ()
    hl.exec_cmd("qs & hypridle & hyprpaper")-- Background apps
end)
