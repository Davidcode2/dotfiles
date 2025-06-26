local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.completion.spell,
    null_ls.builtins.formatting.prettier.with {
      filetypes = {
        "javascript",
        "typescript",
        "css",
        "scss",
        "html",
        "json",
        "yaml",
        "markdown",
        "graphql",
        "md",
        "txt",
      },
      extra_filetypes = {},
      extra_args = { "--single-quote" },
    },
    null_ls.builtins.formatting.prettier,
    require("none-ls.diagnostics.eslint"),
    require("none-ls.code_actions.eslint"),
  },
})
