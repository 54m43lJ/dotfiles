return {
  {
    "folke/noice.nvim",
    init = function()
      vim.cmd("hi! link NoiceCmdlinePopupBorder DiagnosticInfo")
      vim.cmd("hi! link NoiceCmdlineIcon DiagnosticInfo")
      vim.cmd("hi! link NoiceCmdlinePopupTitle DiagnosticInfo")
    end,
    opts = {
      views = {
        cmdline_popup = {
          win_options = {
            --winhighlight = { Normal = "Normal" },
          },
        },
        popupmenu = {
          win_options = {
            --winhighlight = { Normal = "Normal" },
          },
        },
      },
    },
  },
}
