#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

daemon="artifacts/artemis-symphony-daemon/run-01/symphony-daemon.json"
artifact_root="artifacts/artemis-symphony-queue/run-01"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-queue.sh [--daemon path] [--artifact-root path] [--json]

Builds a supervised ARTEMIS Symphony queue from the latest daemon dry-run tick.
The queue is review-only and never calls the bridge or runner.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --daemon)
      daemon="${2:-}"
      if [ -z "$daemon" ]; then usage; exit 2; fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
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

mkdir -p "$artifact_root"

python3 - "$daemon" "$artifact_root" "$format" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

daemon_path = Path(sys.argv[1])
artifact_root = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slug(value):
    text = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(value).lower()).strip("-")
    return text or "task"


if not daemon_path.is_file():
    raise SystemExit(f"daemon artifact not found: {daemon_path}")

daemon = json.loads(daemon_path.read_text(encoding="utf-8"))
ticks = daemon.get("ticks", [])
if not isinstance(ticks, list):
    raise SystemExit("daemon JSON must contain a ticks array")

latest_tick = ticks[-1] if ticks else {}
kernel_path = Path(str(latest_tick.get("kernel", ""))) if latest_tick else Path("")
kernel = {}
errors = []
if latest_tick:
    if kernel_path.is_file():
        kernel = json.loads(kernel_path.read_text(encoding="utf-8"))
    else:
        errors.append(f"latest tick kernel not found: {kernel_path}")

dispatch_plan = kernel.get("dispatch_plan", []) if isinstance(kernel, dict) else []
if not isinstance(dispatch_plan, list):
    errors.append("latest kernel dispatch_plan is not a list")
    dispatch_plan = []

non_dispatch = kernel.get("non_dispatch", []) if isinstance(kernel, dict) else []
if not isinstance(non_dispatch, list):
    non_dispatch = []

items = []
for index, item in enumerate(dispatch_plan, start=1):
    ticket = str(item.get("ticket", "TASK"))
    items.append(
        {
            "queue_id": f"queue-{index:03d}-{slug(ticket)}",
            "order": index,
            "ticket": ticket,
            "title": item.get("title", ""),
            "state": "review_required",
            "runner": item.get("runner", "none"),
            "exec_pack": item.get("exec_pack", ""),
            "workspace": item.get("workspace", {}),
            "source_tick": latest_tick.get("tick_id", ""),
            "source_kernel": str(kernel_path),
            "dispatch_decision": item.get("decision", ""),
            "dispatch_reason": item.get("reason", ""),
            "terminal_override_required": True,
            "human_review_required": True,
            "bridge_call_allowed": False,
            "runner_auto_execution_allowed": False,
            "commands_executed": 0,
            "suggested_bridge": {
                "script": "scripts/artemis-symphony-bridge.sh",
                "ticket": ticket,
                "requires_explicit_command": True,
                "requires_explicit_execute": True,
            },
        }
    )

human_gate_tickets = [
    str(item.get("ticket", "TASK"))
    for item in non_dispatch
    if item.get("decision") == "human_gate"
]

technical_ok = not errors
overall = "queue_ready" if technical_ok and items else "queue_empty" if technical_ok else "failed"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-queue.sh",
    "mode": "supervised_queue_read_only",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "daemon": str(daemon_path),
    "source_tick": latest_tick.get("tick_id", ""),
    "source_kernel": str(kernel_path) if latest_tick else "",
    "summary": {
        "queue_items": len(items),
        "review_required": len(items),
        "human_gate_tickets": len(human_gate_tickets),
        "commands_executed": 0,
        "bridge_called": False,
        "runner_called": False,
        "runner_auto_execution_allowed": False,
    },
    "items": items,
    "human_gate_tickets": human_gate_tickets,
    "errors": errors,
    "invariants": [
        "Queue is derived from daemon and kernel evidence.",
        "Queue is review-only and does not execute agents.",
        "Queue does not call the bridge or runner.",
        "Every queue item requires terminal override before bridge execution.",
        "Human Gates remain explicit and non-bypassable.",
    ],
    "next_cut": "TKT-051 - Intake remoto revisavel do ARTEMIS Symphony",
}

(artifact_root / "symphony-queue.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

producer = {
    "adapter": "local_queue",
    "name": "scripts/artemis-symphony-queue.sh",
    "mode": "read_only",
}
events = []
for item in items:
    events.append(
        event(
            event_id=f"evt_{slug(item['ticket'])}_symphony_queue_review_required",
            event_type="runner.readiness_checked",
            generated_at=generated_at,
            producer=producer,
            ticket=item["ticket"],
            title=str(item.get("title", "")),
            exec_pack=str(item.get("exec_pack", "")),
            artifact_root=str(artifact_root),
            state_from="planned",
            state_to="review",
            runner={"kind": "none"},
            gate={
                "kind": "terminal_override",
                "status": "required",
                "reason": "Queue item requires explicit bridge command from terminal.",
            },
            logs=[str(daemon_path), str(kernel_path), str(artifact_root / "symphony-queue.json")],
            payload={
                "reason": "Dispatch item materialized as supervised review queue item.",
                "queue_id": item["queue_id"],
                "commands_executed": 0,
                "bridge_called": False,
                "runner_called": False,
                "runner_auto_execution_allowed": False,
            },
        )
    )
events.append(
    event(
        event_id="evt_task_symphony_queue_completed",
        event_type="validation.completed" if technical_ok else "validation.failed",
        generated_at=generated_at,
        producer=producer,
        ticket="TASK",
        title="ARTEMIS Symphony supervised queue",
        exec_pack="docs/symphony/ARTEMIS_SYMPHONY_QUEUE.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to="done" if technical_ok else "failed",
        runner={"kind": "none"},
        severity="info" if technical_ok else "error",
        logs=[str(artifact_root / "symphony-queue.json")],
        payload={
            "reason": "Supervised queue generated from daemon evidence without execution.",
            "overall": overall,
            "queue_items": len(items),
            "commands_executed": 0,
            "bridge_called": False,
            "runner_called": False,
        },
    )
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-symphony-queue.sh", generated_at=generated_at, events=events),
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"ARTEMIS Symphony queue esta `{overall}`.",
    "",
    "## Fila",
    "",
    f"- Daemon: `{daemon_path}`.",
    f"- Source tick: `{payload['source_tick'] or 'none'}`.",
    f"- Source kernel: `{payload['source_kernel'] or 'none'}`.",
    f"- Queue items: `{len(items)}`.",
    f"- Review required: `{len(items)}`.",
    f"- Human Gate tickets: `{len(human_gate_tickets)}`.",
    f"- Commands executed: `0`.",
    f"- Bridge called: `false`.",
    f"- Runner called: `false`.",
    "",
    "## Invariantes",
    "",
]
status_lines.extend(f"- {item}" for item in payload["invariants"])
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Queue items: `{len(items)}`.",
    f"- Review required: `{len(items)}`.",
    f"- Commands executed: `0`.",
    f"- Bridge called: `false`.",
    f"- Runner called: `false`.",
    f"- Runner auto execution allowed: `false`.",
    "",
    "## Comandos de verificacao",
    "",
    f"- `scripts/artemis-symphony-queue.sh --daemon {daemon_path} --artifact-root {artifact_root} --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
    "- `git diff --check`",
    "",
    "## Erros",
    "",
]
validation_lines.extend(f"- {error}" for error in errors) if errors else validation_lines.append("- Nenhum erro tecnico local.")
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"Fila supervisionada gerada com `{len(items)}` item(ns) e overall `{overall}`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-051 - Intake remoto revisavel do ARTEMIS Symphony`.",
    "- Exigir comando explicito, terminal override e Validation Gate antes de qualquer execucao.",
    "",
    "## Nao fazer",
    "",
    "- Nao executar itens da fila automaticamente.",
    "- Nao inferir comando de execucao sem humano.",
    "- Nao passar Human Gates remotos, destrutivos ou de cleanup.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Queue: {overall}")
    print(
        "summary: "
        f"items={len(items)} "
        "commands_executed=0 "
        "bridge_called=false "
        "runner_called=false"
    )

if not technical_ok:
    raise SystemExit(1)
PY
