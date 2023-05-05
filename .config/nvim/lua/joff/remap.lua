local opts = { noremap = True }

vim.g.mapleader = " "

-- Clear search highlights
vim.keymap.set("n", "<leader>nh", ":nohl<CR>")

-- Delete the char but doesn't place it into a register
vim.keymap.set("n", "x", '"_x')

-- Display project view (files)
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- To move selected lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- To get out of insert mode without pressing Escape
vim.api.nvim_set_keymap("i", "jk", "<ESC>", opts)
vim.api.nvim_set_keymap("i", "kj", "<ESC>", opts)

-- Window management
vim.keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width & height
vim.keymap.set("n", "<leader>sx", ":close<CR>") -- close current split window

vim.keymap.set("n", "<leader>to", ":tabnew<CR>") -- open new tab
vim.keymap.set("n", "<leader>tx", ":tabclose<CR>") -- close current tab
vim.keymap.set("n", "<leader>tn", ":tabn<CR>") --  go to next tab
vim.keymap.set("n", "<leader>tp", ":tabp<CR>") --  go to previous tab

-- Nvim-tree
vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<cr>")
