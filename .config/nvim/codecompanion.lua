require("codecompanion").setup({
  interactions = {
    chat = {
      adapter = "anthropic",
      model = "haiku-4.5",
    },
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true
      }
    }
  },
  rules = {
    default = {
      description = "Collection of common files for all projects",
      files = {
        ".clinerules",
        ".cursorrules",
        ".goosehints",
        ".rules",
        ".windsurfrules",
        ".github/copilot-instructions.md",
        "AGENT.md",
        "AGENTS.md",
        { path = "CLAUDE.md",           parser = "claude" },
        { path = "CLAUDE.local.md",     parser = "claude" },
        { path = "~/.claude/CLAUDE.md", parser = "claude" },
      },
      is_preset = true,
    },
    opts = {
      chat = {
        enabled = true,
        default_rules = "default", -- The rule groups to load
      },
    },
  },
})
