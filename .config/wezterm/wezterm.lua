local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font configuration
--config.font = wezterm.font('JetBrains Mono')
config.font = wezterm.font("JetBrainsMono NF")
config.font_size = 12.0

function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return "Catppuccin Mocha"
	else
		return "Catppuccin Latte"
	end
end

-- Color scheme (WezTerm ships with over 1,000 built-in themes)
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

-- Visual customization
config.window_background_opacity = 1

-- Trim the gap between the terminal content (including the tmux status bar)
-- and the window edges. WezTerm's default padding leaves a noticeable strip
-- at the bottom; pull it in, with no padding below the last row.
config.window_padding = {
	left = 4,
	right = 4,
	top = 2,
	bottom = 0,
}

-- "INTEGRATED_BUTTONS|RESIZE" keeps the borders resizable and
-- puts the Min/Max/Close buttons in the tab bar (modern look).
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"

-- Cursor style
config.default_cursor_style = "BlinkingBar"

-- Launch WSL2 Ubuntu by default, but only on Windows.
-- WezTerm auto-discovers each installed WSL distro as a domain
-- named "WSL:<distro>". Setting default_domain makes every new
-- tab/window (and the startup window) open inside that distro.
-- On Linux/macOS there is no WSL, so we leave the default local domain.
if wezterm.target_triple:find("windows") then
	config.default_domain = "WSL:Ubuntu"
end

config.automatically_reload_config = true

return config
