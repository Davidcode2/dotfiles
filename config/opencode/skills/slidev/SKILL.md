---
name: slidev
description: Create and present web-based slides for developers using Markdown, Vue components, code highlighting, animations, and interactive features. Use when building technical presentations, conference talks, or teaching materials.
---

# Slidev - Presentation Slides for Developers

Slidev is a web-based slide maker built on Vite, Vue, and Markdown. Use it for
technical presentations, interactive demos, mathematical equations, diagrams,
recordings, and presentations exported to PDF or hosted as an SPA.

## Quick Start

```bash
pnpm create slidev    # Create project
pnpm run dev          # Start dev server
pnpm run export       # Export to PDF
```

## Basic Syntax

```md
---
theme: default
title: My Presentation
---

# First Slide

Content here

---

# Second Slide

More content

<!--
Presenter notes go here
-->
```

- `---` separates slides; the first frontmatter is the deck configuration.
- HTML comments contain presenter notes.
- Layouts include `cover`, `center`, `default`, `two-cols`, `image`, `iframe`,
  `quote`, `section`, `fact`, `statement`, `intro`, and `end`.
- Slidev supports code highlighting, click animations, Monaco, Mermaid, LaTeX,
  Vue components, custom styling, and presenter tools.

## References

Consult the [official documentation](https://sli.dev/) for current syntax,
features, configuration, layouts, CLI commands, and export options. The
[theme gallery](https://sli.dev/resources/theme-gallery) provides examples.
