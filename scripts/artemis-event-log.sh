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
from pathlib import Path
from scripts.artemis_event_common import event, event_log, now_utc, read_json

generated_at = now_utc()

events = []

tasks = read_json("control-plane/tasks.json")
for task in tasks.get("tasks", []):
    if task.get("state") == "ready" and "active" in task.get("tags", []):
        artifact_root = task.get("evidence", "")
        if artifact_root.endswith("/STATUS.md"):
            artifact_root = artifact_root.removesuffix("/STATUS.md")
        events.append(event(
            event_id=f"evt_{task['id']}_task_discovered",
            event_type="task.discovered",
            generated_at=generated_at,
            producer={"adapter": "exec_pack", "name": "scripts/artemis-tasks.sh", "mode": "read_only"},
            ticket=task["ticket"],
            title=task.get("title", ""),
            exec_pack=task.get("exec_pack", ""),
            artifact_root=artifact_root,
            state_to="ready",
            payload={
                "summary": task.get("summary", ""),
                "risk": task.get("risk", ""),
                "owner": task.get("owner", ""),
                "tags": task.get("tags", []),
                "reason": "Active Exec Pack discovered by local task source.",
            },
        ))
        break

github = read_json("artifacts/artemis-github-issues-adapter/run-01/github-issues.json")
events.append(event(
    event_id="evt_tkt-013_github_issues_readiness",
    event_type="runner.readiness_checked",
    generated_at=generated_at,
    producer={"adapter": "github_issues", "name": "scripts/artemis-github-issues.sh", "mode": "read_only"},
    ticket="TKT-013",
    title="Criar GitHub Issues adapter",
    exec_pack="docs/exec-packs/done/TKT-013-github-issues-adapter.md",
    artifact_root="artifacts/artemis-github-issues-adapter/run-01",
    state_to="human_gate" if github.get("overall") == "human_gate" else "done",
    payload={
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

codex = read_json("artifacts/artemis-codex-app-server-adapter/run-01/codex-app-server-adapter.json")
events.append(event(
    event_id="evt_tkt-014_codex_app_server_contract",
    event_type="adapter.contract_recorded",
    generated_at=generated_at,
    producer={"adapter": "codex_app_server", "name": "scripts/artemis-codex-app-server.sh", "mode": "read_only"},
    ticket="TKT-014",
    title="Preparar Codex app-server adapter",
    exec_pack="docs/exec-packs/done/TKT-014-codex-app-server-adapter.md",
    artifact_root="artifacts/artemis-codex-app-server-adapter/run-01",
    state_to="done",
    payload={
        "overall": codex.get("overall"),
        "reason": codex.get("reason"),
        "mapping_count": len(codex.get("mapping", [])),
        "event_contract": codex.get("event_contract", {}),
        "contract": codex.get("contract", {}),
    },
    state_from="handoff",
    runner={"kind": "codex_app_server"},
))

claude = read_json("artifacts/artemis-claude-code-adapter/run-01/claude-code-adapter.json")
events.append(event(
    event_id="evt_tkt-015_claude_code_contract",
    event_type="adapter.contract_recorded",
    generated_at=generated_at,
    producer={"adapter": "claude_code", "name": "scripts/artemis-claude-code.sh", "mode": "read_only"},
    ticket="TKT-015",
    title="Preparar Claude Code adapter",
    exec_pack="docs/exec-packs/done/TKT-015-claude-code-adapter.md",
    artifact_root="artifacts/artemis-claude-code-adapter/run-01",
    state_to="done",
    payload={
        "overall": claude.get("overall"),
        "reason": claude.get("reason"),
        "mapping_count": len(claude.get("mapping", [])),
        "event_contract": claude.get("event_contract", {}),
        "contract": claude.get("contract", {}),
    },
    state_from="handoff",
    runner={"kind": "claude_code"},
))

validation = read_json("artifacts/artemis-validation-gate/run-01/validation-gate.json")
events.append(event(
    event_id="evt_validation_gate_current",
    event_type="validation.completed",
    generated_at=generated_at,
    producer={"adapter": "validation_gate", "name": "scripts/artemis-validation-gate.sh", "mode": "read_only"},
    ticket="TASK",
    title="ARTEMIS Validation Gate",
    exec_pack="ARTEMIS_WORKFLOW.md",
    artifact_root="artifacts/artemis-validation-gate/run-01",
    state_to="human_gate" if validation.get("overall") == "human_gate" else validation.get("overall", "done"),
    payload={
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

attempt_roots = set()
for task in tasks.get("tasks", []):
    task_artifact_root = task.get("evidence", "")
    if task_artifact_root.endswith("/STATUS.md"):
        task_artifact_root = task_artifact_root.removesuffix("/STATUS.md")
    if task_artifact_root.startswith("artifacts/"):
        attempt_roots.add(task_artifact_root)

event_files = set()
for attempt_root in sorted(attempt_roots):
    root_path = Path(attempt_root)
    for candidate in [
        root_path / "events.json",
        root_path / "kernel" / "events.json",
    ]:
        if candidate.is_file():
            event_files.add(candidate)
    for pattern in [
        "attempts/*/events.json",
        "runner/attempts/*/events.json",
    ]:
        event_files.update(root_path.glob(pattern))

for events_path in sorted(event_files):
    attempt_log = read_json(events_path)
    for attempt_event in attempt_log.get("events", []):
        events.append(attempt_event)

for events_path in [
    Path("artifacts/artemis-symphony-remote-source/run-01/events.json"),
    Path("artifacts/artemis-symphony-remote-intake/run-01/events.json"),
    Path("artifacts/artemis-symphony-promotion/run-01/events.json"),
    Path("artifacts/artemis-memory-zone/run-01/events.json"),
    Path("artifacts/artemis-project-graph/run-01/events.json"),
    Path("artifacts/artemis-project-graph-view/run-01/events.json"),
    Path("artifacts/artemis-project-brief/run-01/events.json"),
    Path("artifacts/artemis-guided-collaboration/run-01/events.json"),
    Path("artifacts/artemis-agent-launch-contract/run-01/events.json"),
    Path("artifacts/artemis-agent-runtime-dry-run/run-01/events.json"),
    Path("artifacts/artemis-agent-runtime-approval-gate/run-01/events.json"),
    Path("artifacts/artemis-agent-runtime-decision-intake/run-01/events.json"),
    Path("artifacts/artemis-agent-runtime-launcher-preflight/run-01/events.json"),
]:
    if events_path.is_file():
        remote_log = read_json(events_path)
        for remote_event in remote_log.get("events", []):
            events.append(remote_event)

event_log = event_log(source="scripts/artemis-event-log.sh", generated_at=generated_at, events=events)

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
  printf '%s\n' "$payload" | python3 -c '
import json
import sys

payload = json.loads(sys.stdin.read())
types = sorted({event["event_type"] for event in payload["events"]})
print("ARTEMIS Event Log Schema: passed")
print("events=" + str(len(payload["events"])))
print("event_types=" + ",".join(types))
'
fi
