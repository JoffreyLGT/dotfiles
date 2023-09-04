-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- Allow usage of vim keybindings to move between panes in vim and tmux.
  -- Must have tmux plugin installed as well in tmux.
  'christoomey/vim-tmux-navigator',
  -- Dark theme with pastel colors.
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'rose-pine'
    end,
  },
}
