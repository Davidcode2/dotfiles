#!/usr/bin/env python3
"""Set OS Jira AC checklist items via REST API.

Usage:
  python3 os_ac_set.py --issue OS-12345 --item "AC one" --item "AC two"
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
    parser = argparse.ArgumentParser(description="Set AC checklist items in OS issue")
    parser.add_argument("--issue", required=True, help="Issue key, e.g. OS-12345")
    parser.add_argument(
        "--item",
        action="append",
        default=[],
        help="AC checklist item text. Repeat flag for multiple items.",
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


def build_items(raw_items: list[str]) -> list[dict]:
    items = [item.strip() for item in raw_items if item and item.strip()]
    if not items:
        fail("At least one --item must be provided")

    if len(items) > 20:
        fail("Too many AC items (max 20)")

    result: list[dict] = []
    for i, name in enumerate(items, start=1):
        result.append(
            {
                "name": name,
                "checked": False,
                "mandatory": True,
                "id": i,
                "rank": i - 1,
                "assigneeIds": [],
                "isHeader": False,
                "statusId": "none",
            }
        )
    return result


def main() -> None:
    args = parse_args()

    token = os.environ.get("JIRA_API_TOKEN")
    if not token:
        fail("JIRA_API_TOKEN is not set")

    server = args.server or os.environ.get("JIRA_SERVER") or parse_server_from_config(CONFIG_PATH)
    if not server:
        fail("Jira server URL not found (set --server or JIRA_SERVER)")

    issue_key = args.issue.upper()
    issue_url = f"{server.rstrip('/')}/rest/api/2/issue/{issue_key}"

    payload_items = build_items(args.item)

    request_json(
        "PUT",
        issue_url,
        token,
        body={"fields": {"customfield_16104": payload_items}},
    )

    _, verify_data = request_json("GET", issue_url, token)
    if not verify_data:
        fail("Empty verify response")

    verify_items = verify_data.get("fields", {}).get("customfield_16104")
    if not isinstance(verify_items, list):
        fail("Verification failed: AC checklist missing")

    if len(verify_items) != len(payload_items):
        fail(
            f"Verification failed: expected {len(payload_items)} items, got {len(verify_items)}"
        )

    for idx, expected in enumerate(payload_items):
        name = str(verify_items[idx].get("name", ""))
        checked = bool(verify_items[idx].get("checked", True))
        if name != expected["name"]:
            fail(
                f"Verification failed at item {idx + 1}: expected name '{expected['name']}', got '{name}'"
            )
        if checked:
            fail(f"Verification failed at item {idx + 1}: expected unchecked item")

    print(f"Issue: {issue_key}")
    print(f"Items: {len(verify_items)}")
    for idx, item in enumerate(verify_items, start=1):
        print(f"{idx}. {item.get('name', '')}")


if __name__ == "__main__":
    main()
