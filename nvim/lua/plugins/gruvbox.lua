return {
  --{
  --"morhetz/gruvbox",
  --config = function()
  --vim.g.gruvbox_contrast_light = "soft"
  --vim.opt.background = "light"
  --end,
  --},
  {
    "ellisonleao/gruvbox.nvim",
    config = function()
      vim.opt.background = "light"
    end,
    opt = {
      contrast = "soft",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
