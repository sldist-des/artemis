#!/usr/bin/env sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root=""
format="text"
label="artemis"
limit="50"

usage() {
  echo "usage: scripts/artemis-github-issues.sh [--artifact-root path] [--json] [--label label] [--limit n]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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
    --label)
      label="${2:-}"
      if [ -z "$label" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --limit)
      limit="${2:-}"
      if [ -z "$limit" ]; then
        usage
        exit 2
      fi
      shift 2
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

if [ -n "$artifact_root" ]; then
  mkdir -p "$artifact_root/check-logs"
fi

remote_url=$(git remote get-url origin 2>/dev/null || true)
repo=""
case "$remote_url" in
  git@github.com:*)
    repo=${remote_url#git@github.com:}
    repo=${repo%.git}
    ;;
  https://github.com/*)
    repo=${remote_url#https://github.com/}
    repo=${repo%.git}
    ;;
esac

gh_installed=0
if command -v gh >/dev/null 2>&1; then
  gh_installed=1
fi

auth_status=1
auth_log=""
if [ "$gh_installed" -eq 1 ]; then
  auth_log=$(gh auth status 2>&1)
  auth_status=$?
else
  auth_log="gh is not installed"
fi

issues_json="[]"
issues_status=0
issues_log=""

if [ "$gh_installed" -eq 1 ] && [ "$auth_status" -eq 0 ] && [ -n "$repo" ]; then
  issues_log=$(gh issue list \
    --repo "$repo" \
    --label "$label" \
    --limit "$limit" \
    --json number,title,state,labels,url,assignees,updatedAt 2>&1)
  issues_status=$?
  if [ "$issues_status" -eq 0 ]; then
    issues_json="$issues_log"
    issues_log=""
  fi
fi

codeowners_state="missing"
if [ -f ".github/CODEOWNERS" ]; then
  if grep -v '^#' .github/CODEOWNERS | grep -q '@'; then
    codeowners_state="active"
  else
    codeowners_state="human_gate"
  fi
fi

overall="passed"
reason="GitHub Issues adapter read-only check passed."
if [ "$gh_installed" -ne 1 ]; then
  overall="failed"
  reason="gh CLI is not installed."
elif [ -z "$repo" ]; then
  overall="human_gate"
  reason="origin remote is not a GitHub repository URL."
elif [ "$auth_status" -ne 0 ]; then
  overall="human_gate"
  reason="gh auth status did not pass."
elif [ "$codeowners_state" != "active" ]; then
  overall="human_gate"
  reason="CODEOWNERS has no active owner entries."
elif [ "$issues_status" -ne 0 ]; then
  overall="failed"
  reason="gh issue list failed."
fi

payload=$(python3 - "$overall" "$reason" "$repo" "$label" "$limit" "$gh_installed" "$auth_status" "$codeowners_state" "$issues_status" "$auth_log" "$issues_log" "$issues_json" <<'PY'
import json
import sys
from datetime import datetime, timezone

(
    overall,
    reason,
    repo,
    label,
    limit,
    gh_installed,
    auth_status,
    codeowners_state,
    issues_status,
    auth_log,
    issues_log,
    issues_json,
) = sys.argv[1:13]

try:
    issues = json.loads(issues_json)
except json.JSONDecodeError:
    issues = []

payload = {
    "schema_version": 1,
    "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "overall": overall,
    "reason": reason,
    "mode": "read_only",
    "repo": repo,
    "label": label,
    "limit": int(limit),
    "checks": {
        "gh_installed": gh_installed == "1",
        "gh_auth_exit_code": int(auth_status),
        "codeowners": codeowners_state,
        "issue_list_exit_code": int(issues_status),
    },
    "contract": {
        "issue_defines": "intent",
        "exec_pack_defines": "contract",
        "control_plane_shows": "state",
        "remote_writes": "human_gate_only",
        "labels": [
            "artemis",
            "artemis:intake",
            "artemis:ready",
            "artemis:running",
            "artemis:human-gate",
            "artemis:done",
        ],
    },
    "issues": issues,
    "logs": {
        "auth": auth_log,
        "issues": issues_log,
    },
}
print(json.dumps(payload, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  printf '%s\n' "$payload" >"$artifact_root/github-issues.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path
from scripts.artemis_event_common import event, event_log, write_event_log

root = Path(sys.argv[1])
payload = json.loads((root / "github-issues.json").read_text(encoding="utf-8"))
lines = [
    "# GITHUB ISSUES ADAPTER RESULT",
    "",
    f"- Overall: {payload['overall']}",
    f"- Reason: {payload['reason']}",
    f"- Repo: {payload['repo'] or 'unresolved'}",
    f"- Label: {payload['label']}",
    f"- Issues: {len(payload['issues'])}",
    "",
    "## Contract",
    "",
    "- Issue defines intent.",
    "- Exec Pack defines contract.",
    "- Control Plane shows state.",
    "- Remote writes require Human Gate.",
    "",
    "## Labels",
    "",
]
for label in payload["contract"]["labels"]:
    lines.append(f"- `{label}`")

(root / "GITHUB_ISSUES.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
(root / "check-logs" / "gh-auth.txt").write_text(payload["logs"]["auth"] + "\n", encoding="utf-8")
(root / "check-logs" / "gh-issues.txt").write_text(payload["logs"]["issues"] + "\n", encoding="utf-8")

state_to = "done"
severity = "info"
gate = {"kind": "none", "status": "not_applicable"}
if payload["overall"] == "human_gate":
    state_to = "human_gate"
    severity = "warning"
    gate = {
        "kind": "human",
        "status": "human_gate",
        "reason": payload["reason"],
        "options": ["authenticate gh", "configure CODEOWNERS", "continue local-only"],
    }
elif payload["overall"] == "failed":
    state_to = "blocked"
    severity = "error"
    gate = {"kind": "validation", "status": "failed", "reason": payload["reason"]}

event_payload = {
    "overall": payload["overall"],
    "reason": payload["reason"],
    "repo": payload["repo"],
    "label": payload["label"],
    "issue_count": len(payload["issues"]),
    "checks": payload["checks"],
    "contract": payload["contract"],
}
events = [
    event(
        event_id="evt_tkt-013_github_issues_readiness",
        event_type="runner.readiness_checked",
        generated_at=payload["generated_at"],
        producer={"adapter": "github_issues", "name": "scripts/artemis-github-issues.sh", "mode": "read_only"},
        ticket="TKT-013",
        title="Criar GitHub Issues adapter",
        exec_pack="docs/exec-packs/done/TKT-013-github-issues-adapter.md",
        artifact_root=str(root),
        state_from="ready",
        state_to=state_to,
        runner={"kind": "none"},
        gate=gate,
        severity=severity,
        logs=[
            str(root / "check-logs" / "gh-auth.txt"),
            str(root / "check-logs" / "gh-issues.txt"),
        ],
        payload=event_payload,
    )
]
write_event_log(root / "events.json", event_log(source="scripts/artemis-github-issues.sh", generated_at=payload["generated_at"], events=events))
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
print(f"ARTEMIS GitHub Issues Adapter: {payload['overall']}")
print(f"reason={payload['reason']}")
print(f"repo={payload['repo'] or 'unresolved'} label={payload['label']} issues={len(payload['issues'])}")
PY
fi

case "$overall" in
  failed)
    exit 1
    ;;
  *)
    exit 0
    ;;
esac
