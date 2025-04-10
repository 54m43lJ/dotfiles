local map = vim.keymap.set

map('n', '<C-Tab>', ':bnext<CR>')
map('n', '<C-S-Tab>', ':bNext<CR>')
map('n', '<C-N>', ':enew<CR>')
map('n', '<C-Q>', ':bd<CR>')
map({ 'n', 'i', 'v' }, '<C-Right>', 'zL')
map({ 'n', 'i', 'v' }, '<C-Left>', 'zH')
map({ 'n', 'i', 'v' }, '<C-Up>', '<C-U>')
map({ 'n', 'i', 'v' }, '<C-Down>', '<C-D>')
map('n', '<C-L>', ':noh<CR>')
