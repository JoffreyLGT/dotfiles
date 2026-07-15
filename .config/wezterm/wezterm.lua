local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Font configuration
--config.font = wezterm.font('JetBrains Mono')
config.font = wezterm.font("JetBrainsMono NF")
config.font_size = 12.0

function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Mocha"
  else
    return "Catppuccin Latte"
  end
end

-- Color scheme (WezTerm ships with over 1,000 built-in themes)
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- Visual customization
config.window_background_opacity = 0.95
-- Hide the tab bar when there is only one tab
-- Note: on Windows, it makes the window bar disappear completely, but not on Gnome (Ubuntu)
-- // TODO @joff: add a function to only activate this option on Ubuntu and not on Windows
--config.hide_tab_bar_if_only_one_tab = true

-- "INTEGRATED_BUTTONS|RESIZE" keeps the borders resizable and
-- puts the Min/Max/Close buttons in the tab bar (modern look).
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- Cursor style
config.default_cursor_style = 'BlinkingBar'

-- Launch WSL2 Ubuntu by default.
-- WezTerm auto-discovers each installed WSL distro as a domain
-- named "WSL:<distro>". Setting default_domain makes every new
-- tab/window (and the startup window) open inside that distro.
config.default_domain = 'WSL:Ubuntu'

config.automatically_reload_config = true

return config
