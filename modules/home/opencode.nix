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
    "opencode/skills/confluence-cli" = { source = ../../config/opencode/skills/confluence-cli; recursive = true; };
    "opencode/skills/github-actions-migration" = { source = ../../config/opencode/skills/github-actions-migration; recursive = true; };
    "opencode/skills/jira-cli" = { source = ../../config/opencode/skills/jira-cli; recursive = true; };
    "opencode/skills/shopify-app-bootstrap" = { source = ../../config/opencode/skills/shopify-app-bootstrap; recursive = true; };
    "opencode/skills/slidev" = { source = ../../config/opencode/skills/slidev; recursive = true; };
    "opencode/skills/taskbox-application-consulting-api" = { source = ../../config/opencode/skills/taskbox-application-consulting-api; recursive = true; };
  };
}
