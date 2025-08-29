return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pycodestyle = {
                ignore = {'E501'}
              }
            }
          }
        }
      },
    }
  }
}
