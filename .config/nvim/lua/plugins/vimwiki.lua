-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {
  {
    "vimwiki/vimwiki",
    lazy = false, -- Vimwiki handles its own filetype detection, so we load it at startup to be safe
    dependencies = {
      "michal-h21/vim-zettel", -- Load vim-zettel alongside vimwiki
    },
    init = function()
      -- VimWiki List
      vim.g.vimwiki_list = {
        {
          path = "~/documents/notes/",
          syntax = "markdown",
          ext = ".md",
          links_space_char = "_",
        },
      }

      -- Global Extension: 0 means don't treat ALL .md files as vimwiki (crucial for LazyVim)
      vim.g.vimwiki_global_ext = 0

      -- Markdown Fenced Languages
      vim.g.markdown_fenced_languages = {
        "html",
        "vim",
        "python",
        "css",
        "typescript",
        "javascript",
        "c",
      }

      -- Vim Zettel Config
      vim.g.zettel_options = {
        { template = "~/.config/nvim/templates/zettelTemplate.tpl" },
      }
      vim.g.zettel_format = "%y%m%d-%H%M-%title"
    end,
  },
}
