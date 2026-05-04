#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
ticket=""
format="text"
artifact_root=""
generated=""
materialize=0

usage() {
  echo "usage: scripts/artemis-workspace.sh [--input path] [--ticket TKT-000] [--artifact-root path] [--materialize] [--json]" >&2
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
    --materialize)
      materialize=1
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

if [ "$materialize" -eq 1 ] && [ -z "$ticket" ]; then
  echo "--materialize requires --ticket" >&2
  usage
  exit 2
fi

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

if [ "$materialize" -eq 1 ] && [ -z "$artifact_root" ]; then
  artifact_root=$(python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
workspaces = payload.get("workspaces", [])
if len(workspaces) != 1:
    raise SystemExit("--materialize requires exactly one workspace")
print(workspaces[0]["workspace"]["artifact_root"])
PY
)
fi

if [ "$materialize" -eq 1 ]; then
  materialize_status=0
  set +e
  payload=$(python3 - "$artifact_root" <<'PY' "$payload"
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

artifact_root = sys.argv[1]
payload = json.loads(sys.argv[2])

workspaces = payload.get("workspaces", [])
if len(workspaces) != 1:
    raise SystemExit("--materialize requires exactly one workspace")

item = workspaces[0]
workspace = item["workspace"]
ticket = item["ticket"]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
root = Path.cwd()

def git(*args):
    return subprocess.run(
        ["git", *args],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )

def emit_result(status, reason, **extra):
    result = {
        "status": status,
        "reason": reason,
        "generated_at": now,
        "ticket": ticket,
        "task_id": item["task_id"],
        "branch": workspace["branch"],
        "worktree_path": workspace["worktree_path"],
        "lock_path": workspace["lock_path"],
        "artifact_root": artifact_root,
        "created": extra.pop("created", []),
        "cleanup": {
            "automatic": False,
            "instructions": [
                "Inspect and commit or discard work inside the materialized worktree.",
                "Remove the worktree manually only after human review.",
                "Remove the local lock only after the workspace is no longer owned by an active writer.",
            ],
        },
    }
    result.update(extra)
    payload["materialization"] = result
    print(json.dumps(payload, ensure_ascii=False, indent=2))

if item["readiness"] != "ready":
    emit_result("human_gate" if item["readiness"] == "human_gate" else "blocked", item["reason"])
    raise SystemExit(3)

branch = workspace["branch"]
worktree_path = Path(workspace["worktree_path"])
lock_path = Path(workspace["lock_path"])
branch_ref = f"refs/heads/{branch}"

if git("show-ref", "--verify", "--quiet", branch_ref).returncode == 0:
    emit_result("human_gate", "planned branch already exists; inspect before reuse")
    raise SystemExit(3)
if worktree_path.exists():
    emit_result("human_gate", "planned worktree path already exists")
    raise SystemExit(3)
if lock_path.exists():
    emit_result("human_gate", "writer lock already exists")
    raise SystemExit(3)

head = git("rev-parse", "--short", "HEAD").stdout.strip()
try:
    worktree_path.parent.mkdir(parents=True, exist_ok=True)
except OSError as exc:
    emit_result("blocked", "could not create worktree parent directory", error=str(exc))
    raise SystemExit(3)
created = []

worktree_add = git("worktree", "add", "-b", branch, str(worktree_path), "HEAD")
if worktree_add.returncode != 0:
    emit_result(
        "blocked",
        "git worktree add failed",
        git_stdout=worktree_add.stdout,
        git_stderr=worktree_add.stderr,
    )
    raise SystemExit(3)
created.append("worktree")
created.append("branch")

lock_path.parent.mkdir(parents=True, exist_ok=True)
lock = {
    "schema_version": 1,
    "created_at": now,
    "source": "scripts/artemis-workspace.sh --materialize",
    "ticket": ticket,
    "task_id": item["task_id"],
    "title": item["title"],
    "writer": workspace["writer"],
    "branch": branch,
    "worktree_path": str(worktree_path),
    "lock_path": str(lock_path),
    "artifact_root": artifact_root,
    "head": head,
    "cleanup_state": "active",
}
try:
    lock_path.write_text(json.dumps(lock, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
except OSError as exc:
    emit_result("blocked", "could not write workspace lock", error=str(exc))
    raise SystemExit(3)
created.append("lock")

workspace["mode"] = "materialized"
workspace["cleanup_state"] = "active"

emit_result(
    "materialized",
    "workspace materialized with explicit command",
    created=created,
    head=head,
    lock=lock,
    git_stdout=worktree_add.stdout,
    git_stderr=worktree_add.stderr,
)
PY
)
  materialize_status=$?
  set -e
fi

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

materialization = payload.get("materialization")
if materialization:
    lines.extend([
        "## Materialization",
        "",
        f"- Status: `{materialization['status']}`",
        f"- Reason: {materialization['reason']}",
        f"- Branch: `{materialization['branch']}`",
        f"- Worktree: `{materialization['worktree_path']}`",
        f"- Lock: `{materialization['lock_path']}`",
        "",
    ])
    materialization_lines = [
        "# ARTEMIS WORKSPACE MATERIALIZATION",
        "",
        f"- Status: `{materialization['status']}`",
        f"- Reason: {materialization['reason']}",
        f"- Generated at: {materialization['generated_at']}",
        f"- Ticket: {materialization['ticket']}",
        f"- Branch: `{materialization['branch']}`",
        f"- Worktree: `{materialization['worktree_path']}`",
        f"- Lock: `{materialization['lock_path']}`",
        "",
        "## Cleanup",
        "",
    ]
    for instruction in materialization.get("cleanup", {}).get("instructions", []):
        materialization_lines.append(f"- {instruction}")
    (root / "materialization.json").write_text(
        json.dumps(materialization, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (root / "MATERIALIZATION.md").write_text(
        "\n".join(materialization_lines).rstrip() + "\n",
        encoding="utf-8",
    )

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
materialization = payload.get("materialization")
if materialization:
    print("")
    print("materialization:")
    print(f"  status: {materialization['status']}")
    print(f"  reason: {materialization['reason']}")
    print(f"  branch: {materialization['branch']}")
    print(f"  worktree: {materialization['worktree_path']}")
    print(f"  lock: {materialization['lock_path']}")
PY
fi

if [ "${materialize_status:-0}" -ne 0 ]; then
  exit "$materialize_status"
fi

if [ -n "$generated" ]; then
  rm -f "$generated"
fi
