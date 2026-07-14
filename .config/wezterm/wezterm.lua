local wezterm = require("wezterm")

local config = {}

-- Hide the tab bar when there is only one tab
config.hide_tab_bar_if_only_one_tab = true

-- Use the Catppuccin Mocha color scheme
config.color_scheme = "Catppuccin Mocha"

-- Set the font
config.font = wezterm.font("JetBrainsMonoNerdFont")

return config
