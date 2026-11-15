local function parser_loads(lang)
  local ok, loaded = pcall(vim.treesitter.language.add, lang)
  return ok and loaded ~= false and loaded ~= nil
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    config = function(plugin, opts)
      local treesitter = require("nvim-treesitter")
      local util = require("lazyvim.util.treesitter")
      local have_query = util.have_query
      util.have_query = function(lang, query)
        return parser_loads(lang) and have_query(lang, query)
      end

      local broken = vim.tbl_filter(function(lang)
        return not parser_loads(lang)
      end, treesitter.get_installed("parsers"))

      require("lazyvim.plugins.treesitter")[1].config(plugin, opts)
      if #broken > 0 then
        LazyVim.treesitter.build(function()
          treesitter.install(broken, { force = true, summary = true }):await(function(success)
            util.get_installed(true)
            if not success then
              vim.schedule(function()
                vim.notify("Tree-sitter parser repair failed; run :TSInstall " .. table.concat(broken, " "), vim.log.levels.ERROR)
              end)
            end
          end)
        end)
      end
    end,
  },
}
