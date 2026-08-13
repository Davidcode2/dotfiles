local b2b_root = vim.fs.normalize(vim.fn.expand("~/code/b2b"))

local grep_excludes = {
  "**/.git/**",
  "**/.next/**",
  "**/.nuget/**",
  "**/.pnpm-store/**",
  "**/.turbo/**",
  "**/.yarn/**",
  "**/bin/**",
  "**/build/**",
  "**/coverage/**",
  "**/dist/**",
  "**/node_modules/**",
  "**/obj/**",
}

local function is_in_b2b(cwd)
  cwd = vim.fs.normalize(cwd or (vim.uv or vim.loop).cwd() or ".")
  return cwd == b2b_root or cwd:sub(1, #b2b_root + 1) == b2b_root .. "/"
end

local function configure_b2b_picker(picker_opts)
  if not is_in_b2b(picker_opts.cwd) then
    return picker_opts
  end

  picker_opts.ignored = true
  picker_opts.exclude = vim.list_extend(vim.deepcopy(picker_opts.exclude or {}), grep_excludes)
  return picker_opts
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.explorer = { enabled = false }
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.grep = vim.tbl_deep_extend("force", opts.picker.sources.grep or {}, {
        config = configure_b2b_picker,
      })
      opts.picker.sources.files = vim.tbl_deep_extend("force", opts.picker.sources.files or {}, {
        config = configure_b2b_picker,
      })
    end,
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
