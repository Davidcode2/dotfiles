{ ... }: {
  # Individual files leave credentials, plugins and runtime data writable and local.
  xdg.configFile = {
    "opencode/opencode.json".source = ../../config/opencode/opencode.json;
    "opencode/tui.json".source = ../../config/opencode/tui.json;
    "opencode/settings.json".source = ../../config/opencode/settings.json;
    "opencode/AGENTS.md".source = ../../config/opencode/AGENTS.md;
    "opencode/skills/deploy-app" = { source = ../../config/opencode/skills/deploy-app; recursive = true; };
    "opencode/skills/deploy-image" = { source = ../../config/opencode/skills/deploy-image; recursive = true; };
    "opencode/skills/create-contact-form" = { source = ../../config/opencode/skills/create-contact-form; recursive = true; };
    "opencode/skills/frontend-design-gpt" = { source = ../../config/opencode/skills/frontend-design-gpt; recursive = true; };
  };
}
