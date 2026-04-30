#!/usr/bin/env sh
set -u

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root=""
format="text"

usage() {
  echo "usage: scripts/artemis-event-log.sh [--artifact-root path] [--json]" >&2
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

payload=$(python3 - <<'PY'
import json
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(".")
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def load_json(path):
    with Path(path).open("r", encoding="utf-8") as handle:
        return json.load(handle)

def base_event(event_id, event_type, producer, ticket, title, exec_pack, artifact_root, state_to, payload, *, state_from=None, runner=None, gate=None, severity="info"):
    return {
        "schema_version": 1,
        "event_id": event_id,
        "event_type": event_type,
        "generated_at": generated_at,
        "producer": producer,
        "subject": {
            "ticket": ticket,
            "task_id": ticket.lower(),
            "title": title,
            "exec_pack": exec_pack,
            "artifact_root": artifact_root,
        },
        "runner": runner or {"kind": "none"},
        "state": {
            "from": state_from,
            "to": state_to,
            "reason": payload.get("reason", ""),
        },
        "gate": gate or {"kind": "none", "status": "not_applicable"},
        "severity": severity,
        "evidence": {
            "artifact_path": artifact_root,
            "status_path": f"{artifact_root}/STATUS.md",
            "validation_path": f"{artifact_root}/VALIDATION.md",
            "handoff_path": f"{artifact_root}/HANDOFF.md",
        },
        "links": {
            "correlation_id": ticket.lower(),
        },
        "payload": payload,
    }

events = []

tasks = load_json("control-plane/tasks.json")
for task in tasks.get("tasks", []):
    if task.get("ticket") == "TKT-016":
        events.append(base_event(
            "evt_tkt-016_task_discovered",
            "task.discovered",
            {"adapter": "exec_pack", "name": "scripts/artemis-tasks.sh", "mode": "read_only"},
            task["ticket"],
            task.get("title", ""),
            task.get("exec_pack", ""),
            task.get("evidence", ""),
            "ready",
            {
                "summary": task.get("summary", ""),
                "risk": task.get("risk", ""),
                "owner": task.get("owner", ""),
                "tags": task.get("tags", []),
                "reason": "Active Exec Pack discovered by local task source.",
            },
        ))
        break

github = load_json("artifacts/artemis-github-issues-adapter/run-01/github-issues.json")
events.append(base_event(
    "evt_tkt-013_github_issues_readiness",
    "runner.readiness_checked",
    {"adapter": "github_issues", "name": "scripts/artemis-github-issues.sh", "mode": "read_only"},
    "TKT-013",
    "Criar GitHub Issues adapter",
    "docs/exec-packs/done/TKT-013-github-issues-adapter.md",
    "artifacts/artemis-github-issues-adapter/run-01",
    "human_gate" if github.get("overall") == "human_gate" else "done",
    {
        "overall": github.get("overall"),
        "reason": github.get("reason"),
        "repo": github.get("repo"),
        "issue_count": len(github.get("issues", [])),
        "contract": github.get("contract", {}),
    },
    state_from="ready",
    runner={"kind": "none"},
    gate={
        "kind": "human" if github.get("overall") == "human_gate" else "none",
        "status": github.get("overall", "not_applicable"),
        "reason": github.get("reason", ""),
        "options": ["authenticate gh", "configure CODEOWNERS", "continue local-only"],
    },
    severity="warning" if github.get("overall") == "human_gate" else "info",
))

codex = load_json("artifacts/artemis-codex-app-server-adapter/run-01/codex-app-server-adapter.json")
events.append(base_event(
    "evt_tkt-014_codex_app_server_contract",
    "adapter.contract_recorded",
    {"adapter": "codex_app_server", "name": "scripts/artemis-codex-app-server.sh", "mode": "read_only"},
    "TKT-014",
    "Preparar Codex app-server adapter",
    "docs/exec-packs/done/TKT-014-codex-app-server-adapter.md",
    "artifacts/artemis-codex-app-server-adapter/run-01",
    "done",
    {
        "overall": codex.get("overall"),
        "reason": codex.get("reason"),
        "mapping_count": len(codex.get("mapping", [])),
        "event_contract": codex.get("event_contract", {}),
        "contract": codex.get("contract", {}),
    },
    state_from="handoff",
    runner={"kind": "codex_app_server"},
))

claude = load_json("artifacts/artemis-claude-code-adapter/run-01/claude-code-adapter.json")
events.append(base_event(
    "evt_tkt-015_claude_code_contract",
    "adapter.contract_recorded",
    {"adapter": "claude_code", "name": "scripts/artemis-claude-code.sh", "mode": "read_only"},
    "TKT-015",
    "Preparar Claude Code adapter",
    "docs/exec-packs/done/TKT-015-claude-code-adapter.md",
    "artifacts/artemis-claude-code-adapter/run-01",
    "done",
    {
        "overall": claude.get("overall"),
        "reason": claude.get("reason"),
        "mapping_count": len(claude.get("mapping", [])),
        "event_contract": claude.get("event_contract", {}),
        "contract": claude.get("contract", {}),
    },
    state_from="handoff",
    runner={"kind": "claude_code"},
))

validation = load_json("artifacts/artemis-validation-gate/run-01/validation-gate.json")
events.append(base_event(
    "evt_validation_gate_current",
    "validation.completed",
    {"adapter": "validation_gate", "name": "scripts/artemis-validation-gate.sh", "mode": "read_only"},
    "TASK",
    "ARTEMIS Validation Gate",
    "ARTEMIS_WORKFLOW.md",
    "artifacts/artemis-validation-gate/run-01",
    "human_gate" if validation.get("overall") == "human_gate" else validation.get("overall", "done"),
    {
        "overall": validation.get("overall"),
        "summary": validation.get("summary"),
        "checks": validation.get("checks", []),
        "reason": "Validation Gate completed with structured technical and Human Gate results.",
    },
    state_from="validating",
    runner={"kind": "none"},
    gate={
        "kind": "validation",
        "status": validation.get("overall", "not_applicable"),
        "reason": "Validation Gate result.",
    },
    severity="warning" if validation.get("overall") == "human_gate" else "info",
))

event_log = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-event-log.sh",
    "events": events,
}

print(json.dumps(event_log, ensure_ascii=False, indent=2))
PY
)

if [ -n "$artifact_root" ]; then
  printf '%s\n' "$payload" >"$artifact_root/event-log.example.json"
  python3 - "$artifact_root" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
payload = json.loads((root / "event-log.example.json").read_text(encoding="utf-8"))

lines = [
    "# ARTEMIS EVENT LOG SCHEMA",
    "",
    f"- Schema version: {payload['schema_version']}",
    f"- Events: {len(payload['events'])}",
    f"- Source: {payload['source']}",
    "",
    "## Event Types",
    "",
]
for event in payload["events"]:
    lines.append(f"- `{event['event_type']}`: `{event['event_id']}` -> {event['state']['to']}")

lines.extend([
    "",
    "## Invariants",
    "",
    "- Exec Pack remains the task contract.",
    "- Artifacts remain canonical evidence.",
    "- Git remains durable memory.",
    "- Control Plane may consume events but does not become canonical state.",
    "- Human Gate is explicit event data, not hidden UI state.",
])

(root / "EVENT_LOG_SCHEMA.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
fi

if [ "$format" = "json" ]; then
  printf '%s\n' "$payload"
else
  python3 - <<'PY' "$payload"
import json
import sys

payload = json.loads(sys.argv[1])
types = sorted({event["event_type"] for event in payload["events"]})
print("ARTEMIS Event Log Schema: passed")
print(f"events={len(payload['events'])}")
print("event_types=" + ",".join(types))
PY
fi
