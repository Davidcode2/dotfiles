-- lua/plugins/snacks.lua
return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = { enabled = false },
    },
    keys = {
      -- Disable explorer keymaps
      { "<leader>e", false },
      { "<leader>E", false },

      -- You might also want to disable these if they exist in your version
      { "<leader>fe", false },
      { "<leader>fE", false },
    },
  },
}
