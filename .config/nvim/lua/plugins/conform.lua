return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
      format_on_save = {
        timeout_ms = 1000,
        lsp_fallback = true, -- Falls back to Roslyn/OmniSharp LSP if CSharpier isn't available
      },
      require("conform").setup({
        format_on_save = {
          -- These options will be passed to conform.format()
          timeout_ms = 500,
          lsp_format = "fallback",
        },
      }),
    },
  },
}
