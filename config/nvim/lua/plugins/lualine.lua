return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_c, {
        function()
          return vim.bo.modified and "[+]" or ""
        end,
        color = { fg = "#ff9e64" }, -- Optional: makes the plus sign orange
      })
    end,
  },
}
