---
name: confluence-cli
description: Use the Confluence CLI (`confluence`) to search, read, create, update, move, and manage Confluence pages from the terminal. Trigger this skill whenever the user mentions Confluence docs, spaces, page updates, release notes, architecture docs, runbooks, or documentation cleanup, especially for MyKarcher Business/B2B, Shopify, MX, and Shopify Checkout topics.
---

# Confluence CLI

Use this skill to execute Confluence documentation workflows safely and quickly with the `confluence` command line tool.

## When to use

Use this skill whenever the user asks to:
- find or read Confluence pages
- update standards, architecture docs, runbooks, release notes, or onboarding docs
- create page trees for projects or teams
- upload/download attachments
- reorganize pages under new parents
- audit or clean up docs in key business spaces

Default to this skill even if the user does not explicitly say "Confluence CLI" when the request is clearly about Confluence content operations.

## Priority spaces and discovery

The user is most interested in these Confluence domains and verified space keys:

1. **B2B / MyKarcher Business**: `MBC` (myKarcher Business Community), `BE` (B2B E-Commerce), `BS` (B2B Shop)
2. **Shopify**: `MDCS` (Digital Channel Support), `SC` (Shopify Integration Project)
3. **MX**: `DCH` (MX - Digital Channels), `MXData` (MX Performance & Analytics), `DCSCL` (MX Digital Channel Supply Chain & Logistics)
4. **Shopify Checkout**: `SCK` (Shopify Checkout), `MDCS` (contains active Shopify | OS Checkout pages)

Start with these first when searching, reading, or creating docs.

Some spaces may be empty or access-restricted in the current account. Resolve and confirm keys before write actions:

```bash
confluence spaces
confluence search "type=page AND (space=SPACE_KEY) AND text ~ \"keyword\"" --limit 20
```

If multiple candidate spaces exist, prefer the most domain-specific match (for example, `SCK` or checkout pages in `MDCS` over generic commerce spaces for checkout topics).

Verified examples (use as anchors for fast navigation):
- `646160121` in `MDCS`: "Shopify | OS Checkout"
- `442522446` in `MBC`: "myKarcher Business Community"
- `646154312` in `MDCS`: "MyKärcher Business" (product/project knowledge hub)
- `646152475` in `MAS`: "Software Development Architecture & Standards"

## Safe operating model

For each request, follow this sequence:

1. Confirm scope (read-only vs write) and target space/page.
2. Discover IDs/URLs before changing content.
3. Prefer markdown-based updates unless storage format is explicitly required.
4. For destructive operations (delete/move), summarize exact target and run only with clear user intent.
5. Never delete pages without explicit user approval in the current conversation.
6. Verify by re-reading info/content after mutation.

## Core command playbook

### Install and configure (non-interactive friendly)

```bash
npm install -g confluence-cli
confluence --version
```

Prefer environment variables for agent and CI usage:

```bash
export CONFLUENCE_DOMAIN="confluence.company.com"
export CONFLUENCE_API_PATH="/rest/api"
export CONFLUENCE_AUTH_TYPE="bearer"
export CONFLUENCE_API_TOKEN="your-token"
```

Or initialize config in one command:

```bash
confluence init \
  --domain "confluence.company.com" \
  --api-path "/rest/api" \
  --auth-type bearer \
  --token "your-token"
```

Cloud and Server/DC defaults:
- Atlassian Cloud: `--api-path "/wiki/rest/api"`, `basic` auth with email + token.
- Self-hosted / Data Center: `--api-path "/rest/api"`, typically `bearer` auth with PAT.
- For this workspace, default to `bearer` + `/rest/api` unless the user explicitly provides Cloud settings.

### Health check

```bash
confluence --version
confluence spaces
```

### Find and inspect

```bash
confluence find "Page Title" --space SPACE_KEY
confluence search "deployment pipeline" --limit 20
confluence info 123456789
confluence read 123456789 --format markdown
confluence children 123456789 --recursive --format tree --show-id
```

Prefer numeric page IDs for reliability. When URLs are provided, resolve and confirm the concrete page ID before writes.

### Create and update docs

```bash
confluence create "Page Title" SPACE_KEY --file ./page.md --format markdown
confluence create-child "Child Page" 123456789 --file ./child.md --format markdown
confluence update 123456789 --file ./updated.md --format markdown
```

### Move and copy structure

```bash
confluence move 123456789 987654321
confluence copy-tree 123456789 987654321 --dry-run
confluence copy-tree 123456789 987654321 "Checkout Docs Copy"
```

### Attachments and exports

```bash
confluence attachments 123456789 --pattern "*.pdf"
confluence attachments 123456789 --pattern "*.pdf" --download --dest ./downloads
confluence attachment-upload 123456789 --file ./diagram.png --replace
confluence export 123456789 --format markdown --dest ./docs
```

### Comments

```bash
confluence comments 123456789 --format markdown --all
confluence comment 123456789 --content "Added deployment notes" --location footer
```

### Destructive operations

```bash
confluence delete 123456789 --yes
confluence attachment-delete 123456789 att-987 --yes
confluence comment-delete 456789 --yes
```

Always include `--yes` for agent-driven destructive operations to avoid interactive blocking.
Do not run `confluence delete` unless the user explicitly approves page deletion.

### Useful advanced operations

```bash
confluence edit 123456789 --output ./page.xml
confluence update 123456789 --file ./page.xml --format storage
confluence export 123456789 --format markdown --dest ./local-docs
```

## Development standards to preserve in docs

When creating or updating development documentation, align with these standards:

- **3-repo deployment model**: app repo, platform repo (`-platform`), infrastructure repo (Terraform).
- **Deployment flow**: merge to `stage` or `main`, CI builds/pushes image, platform `values.yaml` image tag update, ArgoCD sync.
- **Image tag convention**: `{env}_{7-char-git-sha}` (example: `prod_3fbd663`).
- **Environment model**: `dev`/`stage` on test cluster/account (namespace separated), `main` on prod account/cluster.
- **Infra patterns**: shared infra repo for many Shopify checkout apps; dedicated infra repos for B2B and some standalone apps.
- **Security + runtime**: IRSA for service access, secrets from SSM via External Secrets Operator.
- **Naming guidance**: prefer `ak-{domain}-{app}-{env}` and `sho-shopify-{app}-{env}` patterns where applicable.

If the current page conflicts with these standards, update it and clearly call out the change rationale in the page content.

## Space-first workflow for this user

For ambiguous prompts, classify intent into one of the priority domains first:

- B2B / MyKarcher Business
- Shopify platform/app topics
- MX topics
- Shopify Checkout apps and related infra

Then run discovery scoped to the likely space before doing global search.

If scoped search returns no results, immediately fall back to keyword search across all spaces, then narrow down with `confluence info <pageId>` before edits.

## Response format

When using this skill, keep responses compact and operational:

1. `Intent`: what is being done
2. `Target`: space key + page title/ID
3. `Commands`: exact commands run
4. `Result`: what changed or what was found
5. `Verification`: read-back proof command/output summary
6. `Next options`: up to 3 practical follow-ups

## Troubleshooting

- If space/page cannot be found, list spaces and re-run scoped search.
- If update fails due to format issues, retry with `--format markdown` and validated file content.
- If move fails, verify same-space constraint and use `copy-tree` if cross-space restructuring is needed.
- If auth/config errors appear, re-run `confluence init` or set required env vars.
- If an inline comment creation returns 400, use footer comments or reply to an existing inline comment.
