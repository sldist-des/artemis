#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
artifact_root="artifacts/artemis-symphony-service/run-01"
max_concurrency="1"
ticks="1"
interval="0"
ticket=""
queue_id=""
command=""
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-service.sh [--input path] [--artifact-root path] [--max-concurrency n] [--ticks n] [--interval seconds] [--ticket TKT-000|--queue-id queue-000 --command "cmd"] [--json]

Runs a finite supervised ARTEMIS Symphony service cycle. It composes the local
daemon dry-run, supervised queue, and optionally the queue bridge in plan-only
mode when the terminal provides an explicit ticket/queue-id plus command.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      input="${2:-}"
      if [ -z "$input" ]; then usage; exit 2; fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --max-concurrency)
      max_concurrency="${2:-}"
      if [ -z "$max_concurrency" ]; then usage; exit 2; fi
      shift 2
      ;;
    --ticks)
      ticks="${2:-}"
      if [ -z "$ticks" ]; then usage; exit 2; fi
      shift 2
      ;;
    --interval)
      interval="${2:-}"
      if [ -z "$interval" ]; then usage; exit 2; fi
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

case "$max_concurrency" in
  ''|*[!0-9]*)
    echo "--max-concurrency must be a positive integer" >&2
    exit 2
    ;;
esac
case "$ticks" in
  ''|*[!0-9]*)
    echo "--ticks must be a positive integer" >&2
    exit 2
    ;;
esac
case "$interval" in
  ''|*[!0-9]*)
    echo "--interval must be a non-negative integer" >&2
    exit 2
    ;;
esac

if [ "$max_concurrency" -lt 1 ]; then
  echo "--max-concurrency must be greater than zero" >&2
  exit 2
fi
if [ "$ticks" -lt 1 ]; then
  echo "--ticks must be greater than zero" >&2
  exit 2
fi
if [ -n "$ticket" ] && [ -n "$queue_id" ]; then
  echo "use either --ticket or --queue-id, not both" >&2
  exit 2
fi
if { [ -n "$ticket" ] || [ -n "$queue_id" ]; } && [ -z "$command" ]; then
  echo "--command is required when --ticket or --queue-id is provided" >&2
  exit 2
fi
if [ -n "$command" ] && [ -z "$ticket" ] && [ -z "$queue_id" ]; then
  echo "--ticket or --queue-id is required when --command is provided" >&2
  exit 2
fi

mkdir -p "$artifact_root"

python3 - "$input" "$artifact_root" "$max_concurrency" "$ticks" "$interval" "$ticket" "$queue_id" "$command" "$format" <<'PY'
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

input_path = sys.argv[1]
artifact_root = Path(sys.argv[2])
max_concurrency = int(sys.argv[3])
ticks = int(sys.argv[4])
interval = int(sys.argv[5])
ticket = sys.argv[6]
queue_id = sys.argv[7]
command = sys.argv[8]
output_format = sys.argv[9]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def run(command_args, stdout_path, stderr_path):
    result = subprocess.run(command_args, cwd=Path.cwd(), text=True, capture_output=True, check=False)
    stdout_path.write_text(result.stdout, encoding="utf-8")
    stderr_path.write_text(result.stderr, encoding="utf-8")
    payload = {}
    if result.stdout.strip():
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError:
            payload = {}
    return result, payload


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


artifact_root.mkdir(parents=True, exist_ok=True)
generated_at = now_utc()
errors = []

daemon_root = artifact_root / "daemon"
queue_root = artifact_root / "queue"
bridge_root = artifact_root / "queue-bridge"
daemon_root.mkdir(parents=True, exist_ok=True)
queue_root.mkdir(parents=True, exist_ok=True)

daemon_result, daemon_payload = run(
    [
        "scripts/artemis-symphony-daemon.sh",
        "--input",
        input_path,
        "--artifact-root",
        str(daemon_root),
        "--ticks",
        str(ticks),
        "--interval",
        str(interval),
        "--max-concurrency",
        str(max_concurrency),
        "--json",
    ],
    artifact_root / "daemon.stdout.json",
    artifact_root / "daemon.stderr.txt",
)
if daemon_result.returncode != 0:
    errors.append(f"daemon exited with status {daemon_result.returncode}")
elif not daemon_payload:
    errors.append("daemon emitted invalid JSON")

queue_payload = {}
queue_result = None
if not errors:
    queue_result, queue_payload = run(
        [
            "scripts/artemis-symphony-queue.sh",
            "--daemon",
            str(daemon_root / "symphony-daemon.json"),
            "--artifact-root",
            str(queue_root),
            "--json",
        ],
        artifact_root / "queue.stdout.json",
        artifact_root / "queue.stderr.txt",
    )
    if queue_result.returncode != 0:
        errors.append(f"queue exited with status {queue_result.returncode}")
    elif not queue_payload:
        errors.append("queue emitted invalid JSON")

bridge_payload = {}
bridge_result = None
bridge_requested = bool(command)
bridge_called = False
if not errors and bridge_requested:
    bridge_root.mkdir(parents=True, exist_ok=True)
    bridge_cmd = [
        "scripts/artemis-symphony-queue-bridge.sh",
        "--queue",
        str(queue_root / "symphony-queue.json"),
        "--command",
        command,
        "--artifact-root",
        str(bridge_root),
        "--json",
    ]
    if ticket:
        bridge_cmd.extend(["--ticket", ticket])
    else:
        bridge_cmd.extend(["--queue-id", queue_id])
    bridge_called = True
    bridge_result, bridge_payload = run(
        bridge_cmd,
        artifact_root / "queue-bridge.stdout.json",
        artifact_root / "queue-bridge.stderr.txt",
    )
    if bridge_result.returncode != 0:
        errors.append(f"queue bridge exited with status {bridge_result.returncode}")
    elif not bridge_payload:
        errors.append("queue bridge emitted invalid JSON")

daemon_summary = daemon_payload.get("summary", {})
queue_summary = queue_payload.get("summary", {})
bridge_summary = bridge_payload.get("summary", {})
commands_executed = int(bridge_summary.get("commands_executed", 0) or 0)
bridge_plan_ready = bridge_payload.get("overall") == "bridge_plan_ready"

if errors:
    overall = "failed"
elif bridge_requested and bridge_plan_ready:
    overall = "service_bridge_plan_ready"
elif bridge_requested:
    overall = "human_gate"
elif queue_payload.get("overall") == "queue_ready":
    overall = "service_queue_ready"
else:
    overall = "service_idle"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-service.sh",
    "mode": "finite_supervised_service",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "task_source": input_path,
    "daemon": str(daemon_root / "symphony-daemon.json"),
    "queue": str(queue_root / "symphony-queue.json"),
    "queue_bridge": str(bridge_root / "queue-bridge.json") if bridge_called else "",
    "ticket": ticket,
    "queue_id": queue_id,
    "command": command,
    "summary": {
        "ticks_requested": ticks,
        "ticks_completed": int(daemon_payload.get("ticks_completed", 0) or 0),
        "max_concurrency": max_concurrency,
        "queue_items": int(queue_summary.get("queue_items", 0) or 0),
        "review_required": int(queue_summary.get("review_required", 0) or 0),
        "daemon_overall": daemon_payload.get("overall", ""),
        "queue_overall": queue_payload.get("overall", ""),
        "queue_bridge_requested": bridge_requested,
        "queue_bridge_called": bridge_called,
        "queue_bridge_overall": bridge_payload.get("overall", ""),
        "queue_bridge_plan_ready": bridge_plan_ready,
        "commands_executed": commands_executed,
        "runner_executed": bool(bridge_summary.get("runner_executed") is True),
        "execute_supported_by_service": False,
        "execute_requested": False,
        "validation_gate_required_before_execute": True,
        "runner_auto_execution_allowed": False,
        "long_running_process_started": False,
    },
    "errors": errors,
    "invariants": [
        "Service is finite and exits after the requested cycle.",
        "Service composes daemon, queue, and optional queue bridge evidence.",
        "Service never passes --execute to the queue bridge.",
        "Service never infers a command; terminal input is required.",
        "Service preserves terminal override and Human Gates.",
        "Real execution remains owned by queue bridge --execute plus Validation Gate and exact approval.",
    ],
    "next_cut": "TKT-051 - Intake remoto revisavel do ARTEMIS Symphony",
}

write_text(artifact_root / "symphony-service.json", json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

producer = {
    "adapter": "local_symphony_service",
    "name": "scripts/artemis-symphony-service.sh",
    "mode": "finite_supervised",
}
events = [
    event(
        event_id="evt_task_symphony_service_completed",
        event_type="validation.completed" if not errors else "validation.failed",
        generated_at=generated_at,
        producer=producer,
        ticket=ticket or "TASK",
        title="ARTEMIS Symphony finite supervised service",
        exec_pack="docs/symphony/ARTEMIS_SYMPHONY_SERVICE.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to="review" if bridge_plan_ready else "done" if not errors else "failed",
        runner={"kind": "codex_cli" if bridge_plan_ready else "none", "command": command} if bridge_requested else {"kind": "none"},
        gate={
            "kind": "terminal_override" if bridge_requested else "none",
            "status": "used" if bridge_plan_ready else "not_applicable",
            "reason": "Terminal provided an explicit queue bridge command." if bridge_plan_ready else "",
        },
        severity="info" if not errors else "error",
        logs=[
            str(artifact_root / "symphony-service.json"),
            str(daemon_root / "symphony-daemon.json"),
            str(queue_root / "symphony-queue.json"),
        ],
        payload={
            "reason": "Finite supervised service cycle completed.",
            "overall": overall,
            "queue_items": payload["summary"]["queue_items"],
            "queue_bridge_requested": bridge_requested,
            "queue_bridge_plan_ready": bridge_plan_ready,
            "commands_executed": commands_executed,
            "execute_supported_by_service": False,
            "runner_auto_execution_allowed": False,
        },
    )
]
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-symphony-service.sh", generated_at=generated_at, events=events),
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"ARTEMIS Symphony service esta `{overall}`.",
    "",
    "## Ciclo supervisionado",
    "",
    f"- Task source: `{input_path}`.",
    f"- Daemon: `{daemon_root / 'symphony-daemon.json'}`.",
    f"- Queue: `{queue_root / 'symphony-queue.json'}`.",
    f"- Queue bridge: `{str(bridge_root / 'queue-bridge.json') if bridge_called else 'not_requested'}`.",
    f"- Ticks completed: `{payload['summary']['ticks_completed']}`.",
    f"- Queue items: `{payload['summary']['queue_items']}`.",
    f"- Queue bridge requested: `{str(bridge_requested).lower()}`.",
    f"- Queue bridge plan ready: `{str(bridge_plan_ready).lower()}`.",
    f"- Commands executed: `{commands_executed}`.",
    "- Execute supported by service: `false`.",
    "- Runner auto execution allowed: `false`.",
    "- Long-running process started: `false`.",
    "",
    "## Invariantes",
    "",
]
status_lines.extend(f"- {item}" for item in payload["invariants"])
if errors:
    status_lines.extend(["", "## Erros", ""])
    status_lines.extend(f"- {item}" for item in errors)
write_text(artifact_root / "STATUS.md", "\n".join(status_lines) + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Daemon overall: `{payload['summary']['daemon_overall']}`.",
    f"- Queue overall: `{payload['summary']['queue_overall']}`.",
    f"- Queue bridge overall: `{payload['summary']['queue_bridge_overall'] or 'not_requested'}`.",
    f"- Commands executed: `{commands_executed}`.",
    "- Execute requested: `false`.",
    "- Execute supported by service: `false`.",
    "- Runner auto execution allowed: `false`.",
    "",
    "## Comandos de verificacao",
    "",
    f"- `scripts/artemis-symphony-service.sh --input {input_path} --artifact-root {artifact_root} --ticks {ticks} --interval {interval} --max-concurrency {max_concurrency}{' --ticket ' + ticket if ticket else ' --queue-id ' + queue_id if queue_id else ''}{' --command \"' + command + '\"' if command else ''} --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
    "- `git diff --check`",
    "",
    "## Erros",
    "",
]
validation_lines.extend(f"- {item}" for item in errors) if errors else validation_lines.append("- Nenhum erro tecnico local.")
write_text(artifact_root / "VALIDATION.md", "\n".join(validation_lines) + "\n")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"- Service: `{overall}`.",
    f"- Queue items: `{payload['summary']['queue_items']}`.",
    f"- Queue bridge requested: `{str(bridge_requested).lower()}`.",
    f"- Commands executed: `{commands_executed}`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-051 - Intake remoto revisavel do ARTEMIS Symphony`.",
    "- Manter execucao real fora do service; usar Queue Bridge `--execute` apenas com Validation Gate e decisao exata.",
    "",
    "## Nao fazer",
    "",
    "- Nao transformar o service em processo persistente sem supervisor externo.",
    "- Nao inferir comandos a partir da fila.",
    "- Nao automatizar push, PR, merge, deploy ou cleanup.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Service: {overall}")
    print(
        "summary: "
        f"queue_items={payload['summary']['queue_items']} "
        f"queue_bridge_requested={str(bridge_requested).lower()} "
        f"commands_executed={commands_executed} "
        "execute_supported_by_service=false"
    )

if errors:
    raise SystemExit(1)
if bridge_requested and not bridge_plan_ready:
    raise SystemExit(3)
PY
