return {
  {
    "ms-jpq/coq_nvim",
    branch = "coq",
    lazy = false,
    init = function()
      vim.g.coq_settings = { auto_start = "shut-up" }
    end,
    dependencies = {
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
      { "ms-jpq/coq.thirdparty", branch = "3p" },
      { "neovim/nvim-lspconfig" },
    },
  },
  { "ms-jpq/coq.artifacts", branch = "artifacts" },
  { "ms-jpq/coq.thirdparty", branch = "3p" },
}
