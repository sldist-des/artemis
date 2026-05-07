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
execute=0
validation_gate=""
decision=""

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-queue-bridge.sh (--ticket TKT-000 | --queue-id queue-000) --command "cmd" [--queue path] [--artifact-root path] [--execute --validation-gate path --decision path] [--json]

Consumes one reviewed ARTEMIS Symphony queue item and calls the supervised
bridge in plan-only mode by default. With --execute, the script requires a
green technical Validation Gate and an exact approval decision artifact.
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
      execute=1
      shift
      ;;
    --validation-gate)
      validation_gate="${2:-}"
      if [ -z "$validation_gate" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision)
      decision="${2:-}"
      if [ -z "$decision" ]; then usage; exit 2; fi
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

if [ -z "$ticket" ] && [ -z "$queue_id" ]; then
  usage
  exit 2
fi

if [ -z "$command" ]; then
  usage
  exit 2
fi

if [ "$execute" -eq 1 ] && { [ -z "$validation_gate" ] || [ -z "$decision" ]; }; then
  usage
  exit 2
fi

mkdir -p "$artifact_root"

python3 - "$queue" "$artifact_root" "$ticket" "$queue_id" "$command" "$format" "$execute" "$validation_gate" "$decision" <<'PY'
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
execute_requested = sys.argv[7] == "1"
validation_gate_path = Path(sys.argv[8]) if sys.argv[8] else None
decision_path = Path(sys.argv[9]) if sys.argv[9] else None
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
decision_payload = {}
validation_gate_payload = {}
validation_gate_passed = False
approval_exact = False
human_gate_acknowledged = False
source_kernel = ""
task_source = ""
max_concurrency = 1
queue_item_found = selected is not None
queue_item_reviewed = bool(selected and selected.get("state") == "review_required")
terminal_override_required = bool(selected and selected.get("terminal_override_required") is True)

if execute_requested:
    if not validation_gate_path or not validation_gate_path.is_file():
        errors.append(f"validation gate artifact not found: {validation_gate_path}")
    else:
        validation_gate_payload = json.loads(validation_gate_path.read_text(encoding="utf-8"))
        validation_summary = validation_gate_payload.get("summary", {})
        validation_gate_passed = (
            int(validation_summary.get("failed", -1)) == 0
            and validation_gate_payload.get("overall") in {"passed", "human_gate"}
        )
        if not validation_gate_passed:
            errors.append("validation gate must have failed=0 and overall passed or human_gate")

    if not decision_path or not decision_path.is_file():
        errors.append(f"decision artifact not found: {decision_path}")
    else:
        decision_payload = json.loads(decision_path.read_text(encoding="utf-8"))
        if decision_payload.get("decision") != "approved":
            errors.append("decision must be approved")
        if not str(decision_payload.get("decided_by", "")).strip():
            errors.append("decision decided_by is required")
        if not str(decision_payload.get("reason", "")).strip():
            errors.append("decision reason is required")
        if validation_gate_path and str(decision_payload.get("validation_gate", "")) != str(validation_gate_path):
            errors.append("decision validation_gate must exactly match --validation-gate")
        human_gate_acknowledged = bool(decision_payload.get("validation_human_gates_acknowledged") is True)
        if validation_gate_payload.get("overall") == "human_gate" and not human_gate_acknowledged:
            errors.append("decision must acknowledge Validation Gate human_gate state")

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
    if execute_requested and decision_payload:
        approval_exact = (
            str(decision_payload.get("ticket", "")) == str(selected.get("ticket", ""))
            and str(decision_payload.get("queue_id", "")) == str(selected.get("queue_id", ""))
            and str(decision_payload.get("command", "")) == command
        )
        if not approval_exact:
            errors.append("decision must exactly match ticket, queue_id, and command")

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
        if execute_requested:
            bridge_cmd.append("--execute")
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
    if execute_requested:
        bridge_planned = (
            bridge_payload.get("overall") == "runner_executed"
            and bridge_summary.get("execute_requested") is True
            and bridge_summary.get("commands_executed") == 1
        )
    else:
        bridge_planned = (
            bridge_payload.get("overall") == "runner_plan_ready"
            and bridge_summary.get("execute_requested") is False
            and bridge_summary.get("commands_executed") == 0
        )

if bridge_planned and execute_requested:
    overall = "runner_executed"
elif bridge_planned:
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
    "execute_requested": execute_requested,
    "commands_executed": int(bridge_payload.get("summary", {}).get("commands_executed", 0) or 0),
    "runner_executed": bool(execute_requested and bridge_planned),
    "validation_gate": str(validation_gate_path or ""),
    "validation_gate_passed": validation_gate_passed,
    "decision": str(decision_path or ""),
    "decision_approved": bool(decision_payload.get("decision") == "approved"),
    "approval_exact": approval_exact,
    "validation_human_gates_acknowledged": human_gate_acknowledged,
    "validation_gate_required_before_execute": True,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-queue-bridge.sh",
    "mode": "supervised_queue_bridge_execute" if execute_requested else "supervised_queue_bridge_plan_only",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "queue": str(queue_path),
    "queue_id": str(selected.get("queue_id", "")) if selected else queue_id_arg,
    "ticket": str(selected.get("ticket", ticket_arg)) if selected else ticket_arg,
    "command": command,
    "source_kernel": source_kernel,
    "task_source": task_source,
    "bridge": str(artifact_root / "bridge" / "symphony-bridge.json"),
    "validation_gate": str(validation_gate_path or ""),
    "decision": str(decision_path or ""),
    "summary": summary,
    "selected_queue_item": selected,
    "errors": errors,
    "invariants": [
        "Queue bridge consumes exactly one reviewed queue item.",
        "Queue bridge requires an explicit command from the terminal.",
        "Queue bridge calls the supervised bridge in plan-only mode by default.",
        "Queue bridge only passes --execute when Validation Gate and exact approval artifacts are present.",
        "Execution requires exact ticket, queue_id, and command approval.",
        "Validation Gate remains required before real execution.",
        "Human Gates remain explicit and non-bypassable.",
    ],
    "next_cut": "TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony",
}

write_text(
    artifact_root / "queue-bridge.json",
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
)

producer = {
    "adapter": "local_queue_bridge",
    "name": "scripts/artemis-symphony-queue-bridge.sh",
    "mode": "execute" if execute_requested else "plan_only",
}
events = [
    event(
        event_id=f"evt_{slug(payload['ticket'] or payload['queue_id'])}_symphony_queue_bridge",
        event_type="runner.attempt_completed" if execute_requested and bridge_planned else "runner.attempt_planned" if bridge_planned else "human_gate.opened",
        generated_at=generated_at,
        producer=producer,
        ticket=payload["ticket"] or "TASK",
        title=str((selected or {}).get("title", "ARTEMIS Symphony queue bridge")),
        exec_pack=str((selected or {}).get("exec_pack", "docs/symphony/ARTEMIS_SYMPHONY_QUEUE_BRIDGE.md")),
        artifact_root=str(artifact_root),
        state_from="review" if queue_item_found else "context",
        state_to="review" if execute_requested and bridge_planned else "running" if bridge_planned else "human_gate",
        runner={"kind": "codex_cli" if bridge_planned else "none", "command": command},
        severity="info" if bridge_planned else "warning",
        logs=[
            str(queue_path),
            str(artifact_root / "queue-bridge.json"),
            str(artifact_root / "bridge" / "symphony-bridge.json"),
        ],
        payload={
            "reason": "Queue item was routed to the supervised bridge in plan-only mode."
            if bridge_planned and not execute_requested
            else "Queue item was executed through the supervised bridge after Validation Gate and exact approval."
            if bridge_planned
            else "; ".join(errors),
            "queue_id": payload["queue_id"],
            "bridge_planned": bridge_planned,
            "execute_requested": execute_requested,
            "commands_executed": summary["commands_executed"],
            "validation_gate_required_before_execute": True,
            "approval_exact": approval_exact,
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
    f"- Execute requested: `{str(execute_requested).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Runner executed: `{str(summary['runner_executed']).lower()}`.",
    f"- Validation Gate passed: `{str(validation_gate_passed).lower()}`.",
    f"- Approval exact: `{str(approval_exact).lower()}`.",
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
    f"- Execute requested: `{str(execute_requested).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Runner executed: `{str(summary['runner_executed']).lower()}`.",
    f"- Validation Gate passed: `{str(validation_gate_passed).lower()}`.",
    f"- Approval exact: `{str(approval_exact).lower()}`.",
    "- Validation Gate required before execute: `true`.",
    "",
    "## Comando",
    "",
    f"- `scripts/artemis-symphony-queue-bridge.sh --queue {queue_path} --ticket {payload['ticket'] or ticket_arg} --command \"{command}\" --artifact-root {artifact_root}{' --execute --validation-gate ' + str(validation_gate_path) + ' --decision ' + str(decision_path) if execute_requested else ''} --json`",
]
write_text(artifact_root / "VALIDATION.md", "\n".join(validation_lines) + "\n")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"- Queue bridge: `{overall}`.",
    f"- Real execution: `{'completed' if execute_requested and bridge_planned else 'not_requested' if not execute_requested else 'blocked'}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony`.",
    "- Manter `--execute` dependente de Validation Gate e decisao exata.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Queue Bridge: {overall}")
    print(f"Artifacts: {artifact_root}")

if overall not in {"bridge_plan_ready", "runner_executed"}:
    raise SystemExit(3)
PY
