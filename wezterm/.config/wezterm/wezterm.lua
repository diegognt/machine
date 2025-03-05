--- wezterm.lua
---
--- __      __      _
--- \ \    / /__ __| |_ ___ _ _ _ __
---  \ \/\/ / -_)_ /  _/ -_) '_| '  \
---   \_/\_/\___/__|\__\___|_| |_|_|_|
---
--- A Wezterm config file
--
local wezterm = require("wezterm")
local act = wezterm.action

local config = {}

-- Use config builder object if possible
if wezterm.config_builder then config = wezterm.config_builder() end

-- Settings
config.color_scheme = "nightfox"
config.font = wezterm.font_with_fallback({
  -- {
  --   family = "Monaspace Argon",
  --   scale = 1,
  --   weight = "Regular",
  --   harfbuzz_features = { 'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04'},
  -- },
  {
    family = "JetBrains Mono",
    scale = 1,
    weight = "Regular",
  },
})

-- config.font_rules = {
--   {
--     intensity = 'Bold',
--     italic = true,
--     font = wezterm.font {
--       family = 'Monaspace Radon',
--       weight = 'Bold',
--       style = 'Italic',
--       harfbuzz_features = { 'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04'},
--     },
--   },
--   {
--     italic = true,
--     intensity = 'Half',
--     font = wezterm.font {
--       family = 'Monaspace Radon',
--       weight = 'DemiBold',
--       style = 'Italic',
--       harfbuzz_features = { 'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04'},
--     },
--   },
--   {
--     italic = true,
--     intensity = 'Normal',
--     font = wezterm.font {
--       family = 'Monaspace Radon',
--       style = 'Italic',
--       weight = 'Medium',
--       harfbuzz_features = { 'calt', 'liga', 'dlig', 'ss01', 'ss02', 'ss03', 'ss04'},
--     },
--   },
-- }

config.window_background_opacity = 1
config.window_decorations = "NONE"
config.window_close_confirmation = "AlwaysPrompt"
config.scrollback_lines = 3000
config.default_workspace = "main"

-- -- Keys
-- config.leader = {
--   key = "a",
--   mods = "CTRL",
--   timeout_milliseconds = 1000
-- }
-- config.keys = {
--   -- Send C-a when pressing C-a twice
--   { key = "a",          mods = "LEADER|CTRL", action = act.SendKey { key = "a", mods = "CTRL" } },
--   { key = "c",          mods = "LEADER",      action = act.ActivateCopyMode },
--   { key = "phys:Space", mods = "LEADER",      action = act.ActivateCommandPalette },
--
--   -- Pane keybindings
--   { key = "s",          mods = "LEADER",      action = act.SplitVertical { domain = "CurrentPaneDomain" } },
--   { key = "v",          mods = "LEADER",      action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
--   { key = "q",          mods = "LEADER",      action = act.CloseCurrentPane { confirm = true } },
--   { key = "h",          mods = "LEADER",      action = act.ActivatePaneDirection("Left") },
--   { key = "j",          mods = "LEADER",      action = act.ActivatePaneDirection("Down") },
--   { key = "k",          mods = "LEADER",      action = act.ActivatePaneDirection("Up") },
--   { key = "l",          mods = "LEADER",      action = act.ActivatePaneDirection("Right") },
--   { key = "z",          mods = "LEADER",      action = act.TogglePaneZoomState },
--   { key = "o",          mods = "LEADER",      action = act.RotatePanes "Clockwise" },
--
--   -- We can make separate keybindings for resizing panes
--   -- But Wezterm offers custom "mode" in the name of "KeyTable"
--   { key = "r",          mods = "LEADER",      action = act.ActivateKeyTable { name = "resize_pane", one_shot = false } },
--
--   -- Tab keybindings
--   { key = "t",          mods = "LEADER",      action = act.SpawnTab("CurrentPaneDomain") },
--   { key = "[",          mods = "LEADER",      action = act.ActivateTabRelative(-1) },
--   { key = "]",          mods = "LEADER",      action = act.ActivateTabRelative(1) },
--   { key = "n",          mods = "LEADER",      action = act.ShowTabNavigator },
--   {
--     key = "e",
--     mods = "LEADER",
--     action = act.PromptInputLine {
--       description = wezterm.format {
--         { Attribute = { Intensity = "Bold" } },
--         { Foreground = { AnsiColor = "Fuchsia" } },
--         { Text = "Renaming Tab Title...:" },
--       },
--       action = wezterm.action_callback(function(window, pane, line)
--         if line then
--           window:active_tab():set_title(line)
--         end
--       end)
--     }
--   },
--   -- Key table for moving tabs around
--   { key = "m", mods = "LEADER",       action = act.ActivateKeyTable { name = "move_tab", one_shot = false } },
--   -- Or shortcuts to move tab w/o move_tab table. SHIFT is for when caps lock is on
--   { key = "{", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) },
--   { key = "}", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },
--
--   -- Lastly, workspace
--   { key = "w", mods = "LEADER",       action = act.ShowLauncherArgs { flags = "FUZZY|WORKSPACES" } },
-- }
--
-- -- I can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
-- for i = 1, 9 do
--   table.insert(config.keys, {
--     key = tostring(i),
--     mods = "LEADER",
--     action = act.ActivateTab(i - 1)
--   })
-- end
--
-- config.key_tables = {
--   resize_pane = {
--     { key = "h",      action = act.AdjustPaneSize { "Left", 1 } },
--     { key = "j",      action = act.AdjustPaneSize { "Down", 1 } },
--     { key = "k",      action = act.AdjustPaneSize { "Up", 1 } },
--     { key = "l",      action = act.AdjustPaneSize { "Right", 1 } },
--     { key = "Escape", action = "PopKeyTable" },
--     { key = "Enter",  action = "PopKeyTable" },
--   },
--   move_tab = {
--     { key = "h",      action = act.MoveTabRelative(-1) },
--     { key = "j",      action = act.MoveTabRelative(-1) },
--     { key = "k",      action = act.MoveTabRelative(1) },
--     { key = "l",      action = act.MoveTabRelative(1) },
--     { key = "Escape", action = "PopKeyTable" },
--     { key = "Enter",  action = "PopKeyTable" },
--   }
-- }
--
-- Tab bar
-- I don't like the look of "fancy" tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = false
wezterm.on("update-status", function (window, _)
  local stat = window:active_workspace()
  local stat_color = "#7dcfff"
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat_color = "#f7768e"
    stat = window:active_key_table()
  end
  if window:leader_is_active() then
    stat = "Leader Key"
    stat_color = "#bb9af7"
  end
  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = "  " },
    { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
    { Text = " | " },
  }))
end)

-- Neovim Zen mode
wezterm.on('user-var-changed', function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    if name == "ZEN_MODE" then
        local incremental = value:find("+")
        local number_value = tonumber(value)
        if incremental ~= nil then
            while (number_value > 0) do
                window:perform_action(wezterm.action.IncreaseFontSize, pane)
                number_value = number_value - 1
            end
            overrides.enable_tab_bar = false
        elseif number_value < 0 then
            window:perform_action(wezterm.action.ResetFontSize, pane)
            overrides.font_size = nil
            overrides.enable_tab_bar = true
        else
            overrides.font_size = number_value
            overrides.enable_tab_bar = false
        end
    end
    window:set_config_overrides(overrides)
end)

return config
