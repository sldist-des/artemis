#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

queue="artifacts/artemis-symphony-queue/run-01/symphony-queue.json"
artifact_root="artifacts/artemis-symphony-queue-bridge/run-01"
ticket=""
queue_id=""
command=""
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-queue-bridge.sh (--ticket TKT-000 | --queue-id queue-000) --command "cmd" [--queue path] [--artifact-root path] [--json]

Consumes one reviewed ARTEMIS Symphony queue item and calls the supervised
bridge in plan-only mode. This cut never passes --execute to the bridge.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --queue)
      queue="${2:-}"
      if [ -z "$queue" ]; then usage; exit 2; fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --ticket)
      ticket="${2:-}"
      if [ -z "$ticket" ]; then usage; exit 2; fi
      shift 2
      ;;
    --queue-id)
      queue_id="${2:-}"
      if [ -z "$queue_id" ]; then usage; exit 2; fi
      shift 2
      ;;
    --command)
      command="${2:-}"
      if [ -z "$command" ]; then usage; exit 2; fi
      shift 2
      ;;
    --execute)
      echo "--execute is reserved for TKT-048; this queue bridge is plan-only" >&2
      exit 2
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

if [ -z "$ticket" ] && [ -z "$queue_id" ]; then
  usage
  exit 2
fi

if [ -z "$command" ]; then
  usage
  exit 2
fi

mkdir -p "$artifact_root"

python3 - "$queue" "$artifact_root" "$ticket" "$queue_id" "$command" "$format" <<'PY'
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

queue_path = Path(sys.argv[1])
artifact_root = Path(sys.argv[2])
ticket_arg = sys.argv[3]
queue_id_arg = sys.argv[4]
command = sys.argv[5]
output_format = sys.argv[6]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slug(value):
    text = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(value).lower()).strip("-")
    return text or "task"


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


if not queue_path.is_file():
    raise SystemExit(f"queue artifact not found: {queue_path}")

queue_payload = json.loads(queue_path.read_text(encoding="utf-8"))
items = queue_payload.get("items", [])
if not isinstance(items, list):
    raise SystemExit("queue JSON must contain an items array")

selected = None
for item in items:
    if ticket_arg and item.get("ticket") == ticket_arg:
        selected = item
        break
    if queue_id_arg and item.get("queue_id") == queue_id_arg:
        selected = item
        break

errors = []
bridge_payload = {}
bridge_status = None
bridge_stdout = ""
bridge_stderr = ""
bridge_planned = False
bridge_called = False
source_kernel = ""
task_source = ""
max_concurrency = 1
queue_item_found = selected is not None
queue_item_reviewed = bool(selected and selected.get("state") == "review_required")
terminal_override_required = bool(selected and selected.get("terminal_override_required") is True)

if selected:
    source_kernel = str(selected.get("source_kernel", ""))
    kernel_path = Path(source_kernel)
    if not kernel_path.is_file():
        errors.append(f"source kernel not found: {kernel_path}")
    else:
        kernel_payload = json.loads(kernel_path.read_text(encoding="utf-8"))
        task_source = str(kernel_payload.get("task_source", ""))
        try:
            max_concurrency = int(kernel_payload.get("summary", {}).get("max_concurrency", 1))
        except (TypeError, ValueError):
            max_concurrency = 1
        if max_concurrency < 1:
            max_concurrency = 1
        if not task_source:
            errors.append("source kernel does not define task_source")

    if not queue_item_reviewed:
        errors.append("selected queue item is not in review_required state")
    if not terminal_override_required:
        errors.append("selected queue item does not require terminal override")

    if not errors:
        bridge_root = artifact_root / "bridge"
        bridge_cmd = [
            "scripts/artemis-symphony-bridge.sh",
            "--input",
            task_source,
            "--ticket",
            str(selected.get("ticket", "")),
            "--command",
            command,
            "--artifact-root",
            str(bridge_root),
            "--max-concurrency",
            str(max_concurrency),
            "--json",
        ]
        bridge_called = True
        result = subprocess.run(bridge_cmd, text=True, capture_output=True, check=False)
        bridge_status = result.returncode
        bridge_stdout = result.stdout
        bridge_stderr = result.stderr
        write_text(artifact_root / "bridge.stdout.json", bridge_stdout)
        write_text(artifact_root / "bridge.stderr.txt", bridge_stderr)
        if result.returncode == 0:
            try:
                bridge_payload = json.loads(bridge_stdout)
            except json.JSONDecodeError as exc:
                errors.append(f"bridge emitted invalid JSON: {exc}")
        else:
            errors.append(f"bridge exited with status {result.returncode}")
else:
    errors.append("queue item not found")

if bridge_payload:
    bridge_summary = bridge_payload.get("summary", {})
    bridge_planned = (
        bridge_payload.get("overall") == "runner_plan_ready"
        and bridge_summary.get("execute_requested") is False
        and bridge_summary.get("commands_executed") == 0
    )

if bridge_planned:
    overall = "bridge_plan_ready"
elif queue_item_found:
    overall = "human_gate"
else:
    overall = "not_in_queue"

summary = {
    "queue_item_found": queue_item_found,
    "queue_item_reviewed": queue_item_reviewed,
    "terminal_override_required": terminal_override_required,
    "terminal_override_used": queue_item_found and terminal_override_required,
    "explicit_command_provided": bool(command),
    "bridge_called": bridge_called,
    "bridge_planned": bridge_planned,
    "bridge_exit_code": bridge_status,
    "bridge_overall": bridge_payload.get("overall", ""),
    "execute_requested": False,
    "commands_executed": int(bridge_payload.get("summary", {}).get("commands_executed", 0) or 0),
    "runner_executed": False,
    "validation_gate_required_before_execute": True,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-queue-bridge.sh",
    "mode": "supervised_queue_bridge_plan_only",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "queue": str(queue_path),
    "queue_id": str(selected.get("queue_id", "")) if selected else queue_id_arg,
    "ticket": str(selected.get("ticket", ticket_arg)) if selected else ticket_arg,
    "command": command,
    "source_kernel": source_kernel,
    "task_source": task_source,
    "bridge": str(artifact_root / "bridge" / "symphony-bridge.json"),
    "summary": summary,
    "selected_queue_item": selected,
    "errors": errors,
    "invariants": [
        "Queue bridge consumes exactly one reviewed queue item.",
        "Queue bridge requires an explicit command from the terminal.",
        "Queue bridge calls the supervised bridge in plan-only mode.",
        "Queue bridge never passes --execute in this cut.",
        "Commands executed remain zero until a later explicit execution cut.",
        "Validation Gate remains required before real execution.",
        "Human Gates remain explicit and non-bypassable.",
    ],
    "next_cut": "TKT-048 - Execucao real opt-in com Validation Gate da fila ARTEMIS Symphony",
}

write_text(
    artifact_root / "queue-bridge.json",
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
)

producer = {
    "adapter": "local_queue_bridge",
    "name": "scripts/artemis-symphony-queue-bridge.sh",
    "mode": "plan_only",
}
events = [
    event(
        event_id=f"evt_{slug(payload['ticket'] or payload['queue_id'])}_symphony_queue_bridge",
        event_type="runner.attempt_planned" if bridge_planned else "human_gate.opened",
        generated_at=generated_at,
        producer=producer,
        ticket=payload["ticket"] or "TASK",
        title=str((selected or {}).get("title", "ARTEMIS Symphony queue bridge")),
        exec_pack=str((selected or {}).get("exec_pack", "docs/symphony/ARTEMIS_SYMPHONY_QUEUE_BRIDGE.md")),
        artifact_root=str(artifact_root),
        state_from="review" if queue_item_found else "context",
        state_to="running" if bridge_planned else "human_gate",
        runner={"kind": "codex_cli" if bridge_planned else "none", "command": command},
        severity="info" if bridge_planned else "warning",
        logs=[
            str(queue_path),
            str(artifact_root / "queue-bridge.json"),
            str(artifact_root / "bridge" / "symphony-bridge.json"),
        ],
        payload={
            "reason": "Queue item was routed to the supervised bridge in plan-only mode."
            if bridge_planned
            else "; ".join(errors),
            "queue_id": payload["queue_id"],
            "bridge_planned": bridge_planned,
            "execute_requested": False,
            "commands_executed": summary["commands_executed"],
            "validation_gate_required_before_execute": True,
        },
    )
]
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-symphony-queue-bridge.sh", generated_at=generated_at, events=events),
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"ARTEMIS Symphony queue bridge esta `{overall}`.",
    "",
    "## Execucao supervisionada",
    "",
    f"- Queue: `{queue_path}`.",
    f"- Queue item found: `{str(queue_item_found).lower()}`.",
    f"- Ticket: `{payload['ticket'] or 'none'}`.",
    f"- Queue id: `{payload['queue_id'] or 'none'}`.",
    f"- Source kernel: `{source_kernel or 'none'}`.",
    f"- Task source: `{task_source or 'none'}`.",
    f"- Bridge planned: `{str(bridge_planned).lower()}`.",
    f"- Execute requested: `false`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Validation Gate required before execute: `true`.",
    "",
    "## Invariantes",
    "",
]
status_lines.extend(f"- {item}" for item in payload["invariants"])
if errors:
    status_lines.extend(["", "## Bloqueios", ""])
    status_lines.extend(f"- {item}" for item in errors)
write_text(artifact_root / "STATUS.md", "\n".join(status_lines) + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Queue item found: `{str(queue_item_found).lower()}`.",
    f"- Bridge planned: `{str(bridge_planned).lower()}`.",
    "- Execute requested: `false`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    "- Runner executed: `false`.",
    "- Validation Gate required before execute: `true`.",
    "",
    "## Comando",
    "",
    f"- `scripts/artemis-symphony-queue-bridge.sh --queue {queue_path} --ticket {payload['ticket'] or ticket_arg} --command \"{command}\" --artifact-root {artifact_root} --json`",
]
write_text(artifact_root / "VALIDATION.md", "\n".join(validation_lines) + "\n")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"- Queue bridge: `{overall}`.",
    "- Real execution: `not_implemented_in_this_cut`.",
    "- Commands executed: `0`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-048 - Execucao real opt-in com Validation Gate da fila ARTEMIS Symphony`.",
    "- Antes de qualquer `--execute`, exigir Validation Gate verde e decisao humana explicita.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Queue Bridge: {overall}")
    print(f"Artifacts: {artifact_root}")

if overall != "bridge_plan_ready":
    raise SystemExit(3)
PY
