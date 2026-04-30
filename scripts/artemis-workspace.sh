#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
ticket=""
format="text"
artifact_root=""
generated=""

usage() {
  echo "usage: scripts/artemis-workspace.sh [--input path] [--ticket TKT-000] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      input="${2:-}"
      if [ -z "$input" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --ticket)
      ticket="${2:-}"
      if [ -z "$ticket" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --json)
      format="json"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ ! -f "$input" ]; then
  generated=$(mktemp "${TMPDIR:-/tmp}/artemis-workspace.XXXXXX.json")
  scripts/artemis-tasks.sh >"$generated"
  input="$generated"
fi

payload=$(python3 - "$input" "$ticket" <<'PY'
import json
import sys
from datetime import datetime, timezone

from scripts.artemis_workspace_common import plan_workspace, summarize

input_path = sys.argv[1]
ticket_filter = sys.argv[2]

with open(input_path, "r", encoding="utf-8") as handle:
    task_payload = json.load(handle)

tasks = task_payload.get("tasks", [])
if not isinstance(tasks, list):
    raise SystemExit("task source JSON must contain a tasks array")

if ticket_filter:
    selected = [task for task in tasks if str(task.get("ticket")) == ticket_filter]
    if not selected:
        raise SystemExit(f"ticket not found in task source: {ticket_filter}")
else:
    selected = [task for task in tasks if str(task.get("state", "")).lower() != "done"]

plans = [plan_workspace(task) for task in selected]
payload = {
    "schema_version": 1,
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "source": "scripts/artemis-workspace.sh",
    "task_source": input_path,
    "summary": summarize(plans),
    "workspaces": plans,
}
print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root"
  printf '%s\n' "$payload" >"$artifact_root/workspace-readiness.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "workspace-readiness.json").read_text(encoding="utf-8"))

lines = [
    "# ARTEMIS WORKSPACE READINESS",
    "",
    f"- Ready: {payload['summary']['ready']}",
    f"- Blocked: {payload['summary']['blocked']}",
    f"- Human Gate: {payload['summary']['human_gate']}",
    "",
    "## Workspaces",
    "",
]
for item in payload["workspaces"]:
    workspace = item["workspace"]
    lines.extend([
        f"### {item['ticket']} - {item['readiness']}",
        "",
        f"- Branch: `{workspace['branch']}`",
        f"- Worktree: `{workspace['worktree_path']}`",
        f"- Lock: `{workspace['lock_path']}`",
        f"- Artifact root: `{workspace['artifact_root']}`",
        f"- Writer: `{workspace['writer']}`",
        f"- Reason: {item['reason']}",
        "",
    ])

(root / "WORKSPACE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
summary = payload["summary"]
print("ARTEMIS Workspace Readiness")
print(f"source: {payload['task_source']}")
print(f"summary: ready={summary['ready']} blocked={summary['blocked']} human_gate={summary['human_gate']}")
print("")
for item in payload["workspaces"]:
    workspace = item["workspace"]
    print(f"- {item['ticket']} [{item['readiness']}]")
    print(f"  reason: {item['reason']}")
    print(f"  branch: {workspace['branch']}")
    print(f"  worktree: {workspace['worktree_path']}")
    print(f"  lock: {workspace['lock_path']}")
    print(f"  artifact_root: {workspace['artifact_root']}")
PY
fi

if [ -n "$generated" ]; then
  rm -f "$generated"
fi
