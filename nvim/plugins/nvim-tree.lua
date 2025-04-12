return {
  {
    'nvim-tree/nvim-tree.lua',
    init = function ()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {},
    keys = {
      { "<leader>fe", function ()
        local api = require('nvim-tree.api')
        api.tree.toggle({ path = LazyVim.root() })
      end, desc = "Explorer (root dir)" },
      { "<leader>fE", function ()
        local api = require('nvim-tree.api')
        api.tree.toggle({ path = LazyVim.root() })
      end, desc = "Explorer (cwd)" },
      { "<leader>e", "<leader>fe", desc = "Explorer (root dir)", remap=true },
      { "<leader>E", "<leader>fE", desc = "Explorer (cwd)", remap=true },
      { "<C-[>", function ()
        local api = require('nvim-tree.api')
        api.tree.change_root_to_parent()
      end, }
    }
  }
}
