-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- WSL2 clipboard fix.
-- Under WSL, Neovim auto-selects the `wl-copy` provider because $WAYLAND_DISPLAY
-- is set, but with systemd enabled the WSLg wayland socket isn't reachable at
-- $XDG_RUNTIME_DIR, so yanks never reach the Windows clipboard. Route the system
-- clipboard through Windows tools instead. Only applies on WSL (has("wsl")).
if vim.fn.has("wsl") == 1 then
  local pwsh_paste =
    "powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw))"
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = {
      ["+"] = "clip.exe",
      ["*"] = "clip.exe",
    },
    paste = {
      ["+"] = pwsh_paste,
      ["*"] = pwsh_paste,
    },
    cache_enabled = 0,
  }
end
