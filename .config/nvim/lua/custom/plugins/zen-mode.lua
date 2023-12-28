-- Distraction free coding
-- https://github.com/folke/zen-mode.nvim

vim.keymap.set('n', '<leader>zm', function() require("zen-mode").toggle() end, { desc = 'Toggle Zen mode' })

return {
  "folke/zen-mode.nvim",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
}
