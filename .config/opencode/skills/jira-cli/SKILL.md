---
name: jira-cli
description: Use the Jira CLI (`jira`) to manage Jira work from the terminal. Trigger this skill whenever the user asks to list, create, view, edit, assign, transition, comment on, or otherwise operate on Jira issues, projects, boards, sprints, epics, or releases from the command line, even if they do not explicitly mention "skill".
---

# Jira CLI

Use this skill to execute Jira workflows with the `jira` command line tool (`ankitpokhrel/jira-cli`).

## When to use

Use this skill when a user asks to do Jira work in terminal, including:
- issue triage (`list`, filters, JQL)
- issue lifecycle (`create`, `edit`, `move`, `assign`)
- collaboration (`comment`, `worklog`)
- planning objects (`epic`, `sprint`, `release`, `board`)
- setup/troubleshooting of Jira CLI config (`jira init`, auth, project context)

## Frequent project context

Prioritize these projects when the user does not specify a project key:
- `OS`
- `B2B`

Project selection rule:
1. If user gives a project key, use it.
2. If not, check recent work in `OS` first, then `B2B`.
3. If both are plausible and action is write/destructive, ask which one.

Examples:

```bash
jira issue list -pOS
jira issue list -pB2B -a"$(jira me)" -s"In Progress"
jira issue create -pOS -tTask -s"Short summary" --no-input
```

## Core principles

1. Confirm context first: default project, board, and authenticated user.
2. Prefer read-only commands before write commands.
3. For destructive operations (`delete`, unlinking), require explicit user intent.
4. When scripting/automation is needed, use machine-readable output (`--raw`, `--csv`, `--plain`).
5. Show the exact command you ran and summarize the result clearly.
6. Keep all generated text extremely concise.
7. Prefer bullet lists over paragraphs.

## Quick setup and health check

Run these checks before substantial Jira operations:

```bash
jira version
jira me
jira serverinfo
```

If CLI is not initialized:

```bash
jira init
```

Useful init flags:
- `--installation cloud|local`
- `--server <jira-base-url>`
- `--login <email-or-username>`
- `--auth-type basic|bearer|mtls`
- `--project <project-key>`
- `--board <board-name>`

## Discovery commands

Use discovery commands to avoid guessing identifiers.

```bash
jira project list
jira board list
jira sprint list
jira release list
```

Issue browsing patterns:

```bash
jira issue list
jira issue list -a"$(jira me)" -s"In Progress" -yHigh
jira issue list -q "summary ~ \"login\" and statusCategory != Done"
jira issue list --raw
```

## Common task playbooks

### 1) List and filter issues

Prefer `jira issue list` with structured flags first; use `-q/--jql` for complex cases.

Examples:

```bash
jira issue list --created week -a"$(jira me)"
jira issue list -s~Done --created-before -24w -a~x
jira issue list --plain --columns key,summary,status,assignee
```

### 2) Create issue

Interactive:

```bash
jira issue create
```

Non-interactive (automation-friendly):

```bash
jira issue create -tBug -s"Login button not working" -yHigh -lbug -b"Steps to reproduce..." --no-input
```

With parent epic or sub-task parent:

```bash
jira issue create -tStory -s"Implement dark mode" -PEPIC-42
```

Description from template/stdin:

```bash
jira issue create --template /path/to/description.md
echo "Description from stdin" | jira issue create -tTask -s"Task from pipe"
```

### 3) View and update issue

```bash
jira issue view PROJ-123 --comments 5
jira issue edit PROJ-123
jira issue assign PROJ-123 "user@example.com"
jira issue move PROJ-123 "In Progress"
```

### 4) Comment and collaboration

```bash
jira issue comment add PROJ-123 "Investigating now"
jira issue comment add PROJ-123 --template /path/to/comment.md
echo "Done, please verify" | jira issue comment add PROJ-123
jira issue list -w
```

### 5) Epic and sprint workflows

```bash
jira epic create
jira epic add EPIC-42 PROJ-123 PROJ-124
jira sprint list
jira sprint add 123 PROJ-123 PROJ-124
```

## Safe execution model

For each user request, follow this sequence:

1. **Understand intent**: identify target project, issue keys, status names, and whether output should be human-readable or JSON.
2. **Resolve ambiguity**: if issue key/status is uncertain, list candidates first (`jira issue list`, `jira issue view`).
3. **Preview action**: for write operations, state exact command before running.
4. **Execute**: run the command.
5. **Verify**: re-read updated issue or list to confirm expected state.
6. **Report**: include what changed and any follow-up command.

## Escaping and quoting

Use safe shell quoting every time:
- Wrap values with spaces in double quotes.
- Escape inner quotes in JQL with `\"`.
- Prefer single quotes around full JQL when possible.
- Use `$'...'` when you need explicit newlines.

Examples:

```bash
jira issue list -q 'project = OS AND summary ~ "login"'
jira issue create -pB2B -tBug -s"Checkout fails on promo code"
jira issue create -pOS -tTask -s"Release prep" -b $'- item 1\n- item 2' --no-input
```

## Comment and description writing rules

Apply these defaults unless the user explicitly asks for more detail:

- **Comments**
  - Keep to 1 short line when possible.
  - Mention recipients with Jira mention syntax: `[~<USER_ID>]`.
  - Use user IDs, not clear-text names or emails.
  - Match Jira user ID exactly (case-sensitive where required).
  - Example: `[~DE10K21533] pls verify in stage.`

- **Descriptions**
  - Keep extremely concise.
  - Include only required facts: scope, impact, and context.
  - Prefer bullet lists; avoid long prose.
  - Remove background/context that is not required to execute.

Description template:

```text
- Scope: <what changes>
- Impact: <who/what is affected>
- Context: <dependencies/links/notes>
```

## Acceptance criteria policy

- In the OS project, acceptance criteria are stored in the dedicated `AC` field (`customfield_16104`), not in description text.
- This field is a checklist-type custom field (`com.okapya.jira.checklist:checklist`).
- If user does not provide AC, draft concise AC bullets and store them in `AC`.
- Keep AC testable and minimal (2-5 bullets).
- Keep description focused on scope/context; do not duplicate AC in description unless user explicitly asks.

Acceptance criteria template:

```text
AC (checklist):
- <observable condition 1>
- <observable condition 2>
- <observable condition 3>
```

AC workflow:
1. Propose concise AC draft.
2. Ask user to confirm or adjust.
3. Apply AC to the dedicated `AC` field after confirmation using the REST-script path (do not use `jira issue edit --custom` for AC).
4. Re-read the issue to verify AC persisted.

Implementation notes:
- `jira issue edit --custom ...` may reject raw custom field keys if handles are not mapped in local config.
- `jira issue edit --custom ...` can print `Issue updated` while silently not persisting AC checklist changes.
- In this environment, AC updates are reliable only via REST-backed scripts in `scripts/`; treat CLI custom-field writes as unsupported for AC.
- For checklist updates, keep the full checklist item structure (`id`, `rank`, `mandatory`, `statusId`, etc.) unless intentionally creating a fresh list.
- Verification is mandatory: re-read `jira issue view <KEY> --raw` and confirm `fields.customfield_16104` values persisted.
- Checklist item shape for AC field:

```json
[
  {
    "name": "<criterion>",
    "checked": false,
    "mandatory": true,
    "id": 1,
    "rank": 0,
    "assigneeIds": [],
    "isHeader": false,
    "statusId": "none"
  }
]
```

### AC check/uncheck playbook (OS)

Use this when a user asks to mark AC checklist items checked/unchecked.

1) Read current AC list and target index

```bash
jira issue view OS-12345 --raw
```

2) Toggle target AC item via REST (recommended reliable path)

```bash
python3 ~/.config/opencode/skills/jira-cli/scripts/os_ac_toggle.py \
  --issue OS-12345 \
  --index 1 \
  --checked true
```

3) Verify persisted state

```bash
jira issue view OS-12345 --raw
```

If AC still does not change, treat it as a write failure and report exact API error payload.

### AC set/create playbook (OS)

Use this when AC items must be created/replaced.

1) Set full AC checklist via REST script (required path)

```bash
python3 ~/.config/opencode/skills/jira-cli/scripts/os_ac_set.py \
  --issue OS-12345 \
  --item "Observable condition 1" \
  --item "Observable condition 2" \
  --item "Observable condition 3"
```

2) Verify persisted state

```bash
jira issue view OS-12345 --raw
```

Policy:
- Always use `os_ac_set.py` for setting/replacing AC items.
- Never use `jira issue edit --custom` for AC writes.

## Output format for responses

When using this skill, respond in this compact structure:

1. `Intent`: what the user asked for
2. `Command(s)`: exact command(s) executed
3. `Result`: key outcome (issue key/status/assignee/comment confirmation)
4. `Verification`: read-back command or proof
5. `Next options`: 1-3 practical follow-ups

Response style:
- Keep lines short.
- Use bullets, not paragraphs.
- Omit non-essential details.

## Troubleshooting

- Auth/config errors: rerun `jira init` or check config file path from `jira --help`.
- SSL/self-signed environments: use `jira init --insecure` only when required by the environment.
- Empty results: confirm project context (`-p`) and filter strictness.
- Transition errors: list current issue details and available statuses, then retry with exact transition name.

## Notes for automation-heavy tasks

- Prefer `--raw` for stable parsing in scripts.
- Use `--paginate` for large result sets.
- Use `--plain --columns ...` for predictable tabular terminal output.
- Use explicit `-p <PROJECT>` to avoid accidental default-project changes.
