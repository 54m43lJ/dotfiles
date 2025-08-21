-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
-- local umap = vim.keymap.del

map('n', '<C-PageDown>', ':bnext<CR>')
map('n', '<C-PageUp>', ':bNext<CR>')
map('n', '<C-N>', ':enew<CR>')
map('n', '<C-Q>', ':bd<CR>')
map('n', '<C-Right>', 'zL')
map('n', '<C-Left>', 'zH')
map('n', '<C-Up>', '<C-U>')
map('n', '<C-Down>', '<C-D>')
map('n', '<C-L>', ':noh<CR>')
map({'n', 'i', 'v'}, '<C-`>', function ()
Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Open terminal" })
map('t', '<C-`>', "<cmd>close<cr>", {desc = "Hide Terminal"})
map('n', '<c-/>', 'gcc', {remap = true, desc = "Toggle Comment"})
map('v', '<c-/>', 'gc', {remap = true, desc = "Toggle Comment"})
map('n', '\\', ':', {noremap = true})
