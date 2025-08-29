require('lspconfig').pylsp.setup{
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          ignore = {'E501'}
        }
      }
    }
  }
}
require('lspconfig').ruff.setup({
  init_options = {
    settings = {
      lint = {
        ignore = {'E501'}
      }
    }
  }
})
