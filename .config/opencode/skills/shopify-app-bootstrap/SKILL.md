---
name: shopify-app-bootstrap
description: Guide and execute Shopify app bootstrap steps from Smartbox, using defaults and derived values to minimize user input, and always return created URLs for verification. When TaskBox Application Consulting tickets are needed, prefer the `taskbox-application-consulting-api` skill over a fully UI-driven browser workflow after the user authenticates in headed Playwright.
---

# Shopify App Bootstrap

## Playwright Quick Start

Use `playwright-cli` for all browser actions in this skill.

Most important commands:
- Open target page: `playwright-cli open "<url>"`
- Show browser for interactive login: `playwright-cli show`
- Let user enter credentials manually in shown browser, then continue automation
- Capture current state: `playwright-cli snapshot`
- Navigate while keeping session: `playwright-cli goto "<url>"`
- Read visible text quickly: `playwright-cli eval "document.body ? document.body.innerText.slice(0,2000) : 'no-body'"`
- Close session when done: `playwright-cli close`

Credential handling rule:
- Never ask user to share passwords/tokens in chat.
- Always use `playwright-cli show` and wait for user to complete login directly in browser.

TaskBox ticketing preference:
- For `Application Consulting` tickets, prefer the `taskbox-application-consulting-api` skill after login.
- Use full UI clicking only for authentication, live form discovery, or fallback when the direct request path changes.

Use this skill to set up a new Shopify app following Smartbox guidance:
`https://smartbox.karcher.com/spaces/ECP/pages/701184431/Shopify+App+Deployment`

This skill is optimized for low user effort:
- Ask only for essential business inputs
- Derive names/values where possible
- Use stable defaults for recurring fields
- Never submit tickets or forms unless the user explicitly says to submit

## Operating Modes

This skill supports three execution modes:

- `single_action` (default): execute only one requested action
- `step_subset`: execute a user-specified subset of steps/actions
- `full_flow`: execute the full Smartbox bootstrap flow

Intent routing rules:
- If user asks for one action, use `single_action`
- If user asks for several explicit actions, use `step_subset`
- If user explicitly asks for end-to-end setup, use `full_flow`
- If request is ambiguous, default to `single_action`

When in `single_action` or `step_subset`, ask only for inputs required by those selected actions.

## Scope

The flow covers:
1. Step 0.9 Repo Creation Ticket (via Application Consulting)
2. Step 1 LeanIX Factsheet
3. Step 2 SP-Number Request
4. Step 3 Cloud Application Setup (Application Consulting)
5. Step 4 Domain Request
6. Step 5 CI/CD pipeline + chart alignment checklist
7. Step 2.1 Infrastructure checklist
8. Step 3.1 ArgoCD app-of-apps PR checklist
9. Step 6 Shopify distribution checklist

## Action Catalog

Use these action IDs when mapping user requests:

- `repo_ticket_create` (Step 0.9)
- `leanix_factsheet_create` (Step 1)
- `sp_number_ticket_create` (Step 2)
- `cloud_setup_ticket_create` (Step 3)
- `dns_ticket_create` (Step 4)
- `cicd_setup_check` (Step 5)
- `infra_repo_check_or_pr` (Step 2.1)
- `argocd_app_of_apps_pr` (Step 3.1)
- `shopify_distribution_check` (Step 6)

## Critical Rule

After each create action, return the resulting URL to the user.

Always output URLs in a clear block:
- LeanIX factsheet URL
- Taskbox ticket URL(s)
- PR URL(s)
- GitHub Actions workflow URL(s) (or Jenkins job URL for legacy cases)
- Shopify install/distribution URL (if generated)

CI/CD default policy:
- For new projects, use GitHub Actions by default.
- Use Jenkins only when the user explicitly requests it or for legacy migration constraints.

## Required User Inputs (Minimal)

Full-flow baseline inputs (ask once, then reuse):

- `app_slug` (kebab-case, e.g. `email-template-generator`)
- `app_display_name` (human readable)
- `app_description` (1-2 sentences)
- `responsible_run_group` (team tag/owner group)
- `dedicated_infra_repo` (`yes`/`no`)
- `domain_prefix` (for `<domain_prefix>.app.shop.karcher.com`)
- `needs_dev_url` (`yes`/`no`)
- `google_chat_space` (link or identifier)
- `google_chat_webhook` (URL)
- `target_shopify_store_url` (optional override for app distribution test)

Action-specific minimums (for `single_action`/`step_subset`):
- `repo_ticket_create`: `app_slug`, `app_display_name`, `dedicated_infra_repo`
- `leanix_factsheet_create`: `app_display_name`, `app_description`, `responsible_run_group`
- `sp_number_ticket_create`: `app_display_name`, `leanix_factsheet_url`
- `cloud_setup_ticket_create`: `app_display_name`, `app_repo_url`, `platform_repo_url`, `google_chat_space`, `google_chat_webhook`
- `dns_ticket_create`: `app_display_name`, `domain_prefix`, `sp_number`
- `cicd_setup_check`: `app_repo_url` (and `ci_platform` only if overriding default)
- `infra_repo_check_or_pr`: `app_slug` (and infra repo URL if already exists)
- `argocd_app_of_apps_pr`: `app_slug`, `environment_scope`
- `shopify_distribution_check`: no input required if default store URL is accepted; otherwise `target_shopify_store_url`

## Defaults

Use these unless user overrides:

- Organization: `Alfred Karcher SE & Co. KG (DE10)`
- Cost Center: `DE10 006240 WIN Digital Channel Products`
- DNS Resource Type: `CNAME`
- DNS targets:
  - `ak-ecommerce-test.sys.karcher.com`
  - `ak-ecommerce-prod.sys.karcher.com`
- Repo creation vehicle: Taskbox Application Consulting (`Github Enterprise Cloud`)
- Default Shopify store URL: `https://admin.shopify.com/store/ie-dev-karcher/`

## Derived Values

### Repository Names

From `app_slug`:
- App repo: `sho-shopify-<app_slug>-app`
- Platform repo: `sho-shopify-<app_slug>-app-platform`
- Infra repo (only if dedicated): `sho-shopify-<app_slug>-infrastructure`

### Titles and Summaries

- Step 0.9 title: `Create GitHub repositories for <app_display_name>`
- Step 2 title: `SP-Number Request <app_display_name>`
- Step 3 title: `Cloud Application Setup <app_display_name>`
- Step 4 summary: `DNS for <app_display_name> (<domain_prefix>.app.shop.karcher.com)`

### Domain URLs

- Main URL: `<domain_prefix>.app.shop.karcher.com`
- Optional dev URL (if needed): `dev.<domain_prefix>.app.shop.karcher.com` or agreed pattern

## Step-by-Step Procedure

### Step 0.9 - Repo Creation Ticket (Application Consulting)

Create a Taskbox ticket via Application Consulting and request repo setup.

Preferred execution path:
- Use the `taskbox-application-consulting-api` skill for this step.
- Authenticate in headed Playwright, refresh the live form metadata, and submit through the authenticated request endpoint.
- Fall back to manual UI submission only if the direct request flow fails or the live payload has changed.

Required form fields observed:
- `Title *`
- `Application Consulting *`
- `Description *`
- `Organization *`
- `Cost Center *`

Include in description:
- Requested repositories (app/platform/(optional)infrastructure)
- Domain/team context
- Cost center and organization (default unless overridden)

Taskbox field interaction notes:
- Fill `Title *` first using `Create GitHub repositories for <app_display_name>`.
- For object fields (`Application Consulting`, `Organization`, `Cost Center`), type a short prefix and select from autocomplete options.
  - Suggested prefixes: `Git` -> `Github Enterprise Cloud`, `Alf` -> `DE10 - AKW - Alfred Kärcher SE & Co. KG - Germany`, `006` -> `DE10 006240 WIN Digital Channel Products`.
- Confirm each object field shows a selected value chip/text entry, not only typed free text.
- In `Description *`, paste real line breaks (multi-line text), not escaped `\\n` sequences.
- Use `Browse` dialogs only when inline autocomplete does not return the required value.

Do not submit without explicit user instruction.

On submit, return:
- Ticket URL
- Ticket key

### Step 1 - LeanIX Factsheet

Create a LeanIX IT Component factsheet using Smartbox template as reference:
`https://kaercher.leanix.net/Kaercher/factsheet/ITComponent/3de587eb-f273-47cf-bf6c-e9f187a8390f`

Populate at minimum:
- Name
- Description
- Responsible/run-group metadata
- Provider/ownership fields required by LeanIX

On creation, return:
- LeanIX factsheet URL

### Step 2 - SP-Number Request

Use Taskbox form:
`https://taskbox.karcher.com/plugins/servlet/desk/portal/97/create/4140`

Required form fields observed:
- `Title *`
- `Please enter the fact sheet URL *`
- `Organization *`

Fill optional fields when helpful (`Application name`, notes).

On submit, return:
- Ticket URL
- Ticket key
- SP-number (when available)

### Step 3 - Cloud Application Setup (Application Consulting)

Use Taskbox form:
`https://taskbox.karcher.com/plugins/servlet/desk/portal/97/create/4030`

Preferred execution path:
- Use the `taskbox-application-consulting-api` skill here too, since this is the same `Application Consulting` request type.
- Prefer direct authenticated submission over full UI entry after login.

Required form fields observed:
- `Title *`
- `Application Consulting *`
- `Description *`
- `Organization *`

Description must include:
- App repo URL
- Platform repo URL
- Google Chat space and webhook
- Request for namespace/ECR/Argo access setup

On submit, return:
- Ticket URL
- Ticket key

### Step 4 - Domain Request

Use Taskbox form:
`https://taskbox.karcher.com/plugins/servlet/desk/portal/53/create/1509`

Required form fields observed:
- `Summary *`
- `DNS Ressource Type *`
- `Target *`

Put Smartbox-required context into Summary/Description:
- SP-number
- Requested domain(s)
- Env URL requirement (dev/stage)

Use default targets unless user overrides.

On submit, return:
- Ticket URL
- Ticket key

### Step 5 - CI/CD and Chart

Default to GitHub Actions for new projects.

If Jenkins is required (legacy/explicit request), use guide:
`https://smartbox.karcher.com/x/wM0_Kw`

Verify/checklist:
- CI pipeline exists in GitHub Actions (or Jenkins if legacy)
- Repository integration and credentials/secrets configured
- Chart placeholders replaced with namespace/domain
- Pipeline runs successfully

Return:
- GitHub Actions workflow URL and latest run URL
- Jenkins job/build URL only if Jenkins path was used

### Step 2.1 - Infrastructure

If dedicated infra repo:
- Create/adapt Terraform with IAM/IRSA and SSM entries

Required secrets names:
- `SHOPIFY_API_KEY`
- `SHOPIFY_API_SECRET`

Return:
- Infra repo URL
- PR URL(s)

### Step 3.1 - ArgoCD App-of-Apps

Create PR in app-of-apps repo with new application entries.

Return:
- PR URL
- merged commit URL (if merged)

### Step 6 - Shopify Distribution

Document distribution setup through Shopify Partners and target store install.

Return:
- Distribution or install URL used
- Target store URL

## Request Parsing Examples

- "Create SP-number ticket for this LeanIX factsheet" -> `single_action` + `sp_number_ticket_create`
- "Do Step 0.9 and Step 3" -> `step_subset` + `repo_ticket_create`, `cloud_setup_ticket_create`
- "Set up the full app" -> `full_flow`
- "Prepare DNS request but don't submit" -> `single_action` + `dns_ticket_create` in prepare mode

## Safety and Interaction Rules

- Never click `Create`, `Submit`, or equivalent action unless user explicitly says so.
- Before submission, show a compact preview of filled values.
- After submission, immediately capture and return resulting URL.
- If a step fails due to access/permissions, stop that step and provide exact missing entitlement.

## Output Format

For each run, provide:

1. `Mode` (`single_action`, `step_subset`, or `full_flow`)
2. `Requested actions`
3. `Inputs` (only what user gave/what was needed)
4. `Derived values` (repo names/domains/titles)
5. `Execution log` (`prepared`, `submitted`, `blocked` per action)
6. `Result URLs` (mandatory list)
7. `Next required action`

## Versioning Notes

This process changes over time. Keep the skill maintainable:
- Prefer configurable constants for portals, defaults, and naming
- Keep required-field lists close to each step
- Update URLs and defaults from Smartbox or ticket-form changes
