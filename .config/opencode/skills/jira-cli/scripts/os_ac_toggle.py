#!/usr/bin/env python3
"""Toggle OS Jira AC checklist items via REST API.

Usage:
  python3 os_ac_toggle.py --issue OS-12345 --index 1 --checked true
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path


CONFIG_PATH = Path.home() / ".config" / ".jira" / ".config.yml"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Toggle AC checklist item in OS issue")
    parser.add_argument("--issue", required=True, help="Issue key, e.g. OS-12345")
    parser.add_argument(
        "--index",
        type=int,
        required=True,
        help="1-based AC item index in customfield_16104",
    )
    parser.add_argument(
        "--checked",
        required=True,
        choices=["true", "false"],
        help="Target checked state",
    )
    parser.add_argument(
        "--server",
        default=None,
        help="Jira base URL (defaults to JIRA_SERVER or ~/.config/.jira/.config.yml)",
    )
    return parser.parse_args()


def fail(msg: str, code: int = 1) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(code)


def parse_server_from_config(path: Path) -> str | None:
    if not path.exists():
        return None

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("server:"):
            _, value = line.split(":", 1)
            return value.strip()
    return None


def request_json(method: str, url: str, token: str, body: dict | None = None) -> tuple[int, dict | None]:
    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(req) as resp:
            payload = resp.read()
            if payload:
                return resp.status, json.loads(payload.decode("utf-8"))
            return resp.status, None
    except urllib.error.HTTPError as err:
        detail = err.read().decode("utf-8", errors="replace")
        fail(f"HTTP {err.code} {method} {url}: {detail}")


def main() -> None:
    args = parse_args()

    token = os.environ.get("JIRA_API_TOKEN")
    if not token:
        fail("JIRA_API_TOKEN is not set")

    server = args.server or os.environ.get("JIRA_SERVER") or parse_server_from_config(CONFIG_PATH)
    if not server:
        fail("Jira server URL not found (set --server or JIRA_SERVER)")

    issue_key = args.issue.upper()
    index = args.index
    if index < 1:
        fail("--index must be >= 1")

    issue_url = f"{server.rstrip('/')}/rest/api/2/issue/{issue_key}"

    _, issue_data = request_json("GET", issue_url, token)
    if not issue_data:
        fail("Empty issue response")

    fields = issue_data.get("fields", {})
    ac_items = fields.get("customfield_16104")
    if not isinstance(ac_items, list):
        fail("customfield_16104 is missing or not a checklist array")

    zero_index = index - 1
    if zero_index >= len(ac_items):
        fail(f"index {index} out of range (AC has {len(ac_items)} item(s))")

    target_value = args.checked == "true"
    old_value = bool(ac_items[zero_index].get("checked", False))

    updated_items: list[dict] = []
    for i, item in enumerate(ac_items):
        if not isinstance(item, dict):
            fail("AC checklist item has invalid shape")
        copy_item = dict(item)
        if i == zero_index:
            copy_item["checked"] = target_value
        updated_items.append(copy_item)

    request_json(
        "PUT",
        issue_url,
        token,
        body={"fields": {"customfield_16104": updated_items}},
    )

    _, verify_data = request_json("GET", issue_url, token)
    if not verify_data:
        fail("Empty verify response")
    verify_items = verify_data.get("fields", {}).get("customfield_16104")
    if not isinstance(verify_items, list) or zero_index >= len(verify_items):
        fail("Verification failed: AC checklist missing after update")

    new_value = bool(verify_items[zero_index].get("checked", False))
    if new_value != target_value:
        fail(
            f"Verification failed: item {index} still checked={str(new_value).lower()}"
        )

    item_name = str(verify_items[zero_index].get("name", ""))
    print(f"Issue: {issue_key}")
    print(f"Item: {index}")
    print(f"Name: {item_name}")
    print(f"Checked: {str(old_value).lower()} -> {str(new_value).lower()}")


if __name__ == "__main__":
    main()
