vim.opt.shiftwidth = 4
vim.opt.tabstop = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.shell = "/bin/bash"
vim.opt.wrap = true
lvim.plugins = {
    {
        "p00f/alabaster.nvim",
        config = function()
            vim.opt.background = "light"
        end,
    }
}
lvim.colorscheme = "alabaster"
lvim.keys.normal_mode["<C-Tab>"] = ":bnext<CR>"
lvim.keys.normal_mode["<S-Tab>"] = ":bNext<CR>"
lvim.keys.normal_mode["<C-N>"] = ":enew<CR>"
lvim.keys.normal_mode["<C-Q>"] = ":bd<CR>"
lvim.keys.normal_mode["<C-Right>"] = "zL"
lvim.keys.normal_mode["<C-Left>"] = "zH"
lvim.keys.normal_mode["<C-Up>"] = "<C-U>"
lvim.keys.normal_mode["<C-Down>"] = "<C-D>"
lvim.keys.normal_mode["<C-L>"] = ":nohl<CR>"
