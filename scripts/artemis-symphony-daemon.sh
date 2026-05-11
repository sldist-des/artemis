#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
artifact_root="artifacts/artemis-symphony-daemon/run-01"
max_concurrency="1"
ticks="1"
interval="0"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-daemon.sh [--input path] [--artifact-root path] [--max-concurrency n] [--ticks n] [--interval seconds] [--json]

Runs a finite read-only ARTEMIS Symphony daemon dry-run. It polls the task source,
calls the read-only kernel, writes heartbeat evidence, and never starts a runner.
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

mkdir -p "$artifact_root"

python3 - "$input" "$artifact_root" "$max_concurrency" "$ticks" "$interval" "$format" <<'PY'
import json
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

input_path = sys.argv[1]
artifact_root = Path(sys.argv[2])
max_concurrency = int(sys.argv[3])
ticks_requested = int(sys.argv[4])
interval_seconds = int(sys.argv[5])
output_format = sys.argv[6]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


artifact_root.mkdir(parents=True, exist_ok=True)
ticks_root = artifact_root / "ticks"
ticks_root.mkdir(parents=True, exist_ok=True)
heartbeat_log = artifact_root / "heartbeat.jsonl"
heartbeat_log.write_text("", encoding="utf-8")

ticks = []
events = []
errors = []
started_at = now_utc()
producer = {
    "adapter": "local_daemon",
    "name": "scripts/artemis-symphony-daemon.sh",
    "mode": "read_only_dry_run",
}

for number in range(1, ticks_requested + 1):
    tick_id = f"tick-{number:03d}"
    tick_root = ticks_root / tick_id
    kernel_root = tick_root / "kernel"
    tick_root.mkdir(parents=True, exist_ok=True)
    generated_at = now_utc()

    command = [
        "scripts/artemis-symphony-kernel.sh",
        "--input",
        input_path,
        "--artifact-root",
        str(kernel_root),
        "--max-concurrency",
        str(max_concurrency),
        "--json",
    ]
    result = subprocess.run(command, cwd=Path.cwd(), text=True, capture_output=True, check=False)
    (tick_root / "kernel.stdout.json").write_text(result.stdout, encoding="utf-8")
    (tick_root / "kernel.stderr.txt").write_text(result.stderr, encoding="utf-8")

    kernel_payload = {}
    if result.returncode == 0:
        try:
            kernel_payload = json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            errors.append(f"{tick_id}: kernel emitted invalid JSON: {exc}")
    else:
        errors.append(f"{tick_id}: kernel exited with {result.returncode}")

    summary = kernel_payload.get("summary", {})
    dispatch_plan = kernel_payload.get("dispatch_plan", [])
    non_dispatch = kernel_payload.get("non_dispatch", [])
    human_gate_count = int(summary.get("human_gate", 0) or 0)
    tick = {
        "tick": number,
        "tick_id": tick_id,
        "generated_at": generated_at,
        "kernel_exit_code": result.returncode,
        "kernel": str(kernel_root / "symphony-kernel.json"),
        "kernel_overall": kernel_payload.get("overall", "failed" if result.returncode else "unknown"),
        "summary": {
            "tasks_total": int(summary.get("tasks_total", 0) or 0),
            "eligible": int(summary.get("eligible", 0) or 0),
            "blocked": int(summary.get("blocked", 0) or 0),
            "human_gate": human_gate_count,
            "done": int(summary.get("done", 0) or 0),
            "selected_for_dispatch": int(summary.get("selected_for_dispatch", len(dispatch_plan)) or 0),
            "commands_executed": 0,
            "runner_auto_execution_allowed": False,
        },
        "dispatch_tickets": [str(item.get("ticket", "TASK")) for item in dispatch_plan],
        "human_gate_tickets": [
            str(item.get("ticket", "TASK"))
            for item in non_dispatch
            if item.get("decision") == "human_gate"
        ],
    }
    ticks.append(tick)
    with heartbeat_log.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(tick, ensure_ascii=False) + "\n")
    (artifact_root / "heartbeat.json").write_text(
        json.dumps(tick, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    events.append(
        event(
            event_id=f"evt_task_symphony_daemon_{tick_id}",
            event_type="runner.readiness_checked",
            generated_at=generated_at,
            producer=producer,
            ticket="TASK",
            title="ARTEMIS Symphony daemon dry-run",
            exec_pack="docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md",
            artifact_root=str(artifact_root),
            state_from="context" if number == 1 else "planned",
            state_to="planned",
            runner={"kind": "none"},
            gate={
                "kind": "human" if human_gate_count else "none",
                "status": "human_gate" if human_gate_count else "not_applicable",
                "reason": "Kernel reported Human Gate tasks." if human_gate_count else "",
            },
            severity="warning" if human_gate_count else "info",
            logs=[str(kernel_root / "symphony-kernel.json"), str(heartbeat_log)],
            payload={
                "reason": "Daemon dry-run heartbeat recorded without runner execution.",
                "tick": number,
                "kernel_overall": tick["kernel_overall"],
                "selected_for_dispatch": tick["summary"]["selected_for_dispatch"],
                "commands_executed": 0,
                "runner_auto_execution_allowed": False,
            },
        )
    )

    if number < ticks_requested and interval_seconds > 0:
        time.sleep(interval_seconds)

completed_at = now_utc()
technical_ok = not errors
last_tick = ticks[-1] if ticks else {}
overall = "heartbeat_ready" if technical_ok else "failed"
payload = {
    "schema_version": 1,
    "generated_at": completed_at,
    "source": "scripts/artemis-symphony-daemon.sh",
    "mode": "read_only_daemon_dry_run",
    "overall": overall,
    "task_source": input_path,
    "artifact_root": str(artifact_root),
    "started_at": started_at,
    "completed_at": completed_at,
    "ticks_requested": ticks_requested,
    "ticks_completed": len(ticks),
    "interval_seconds": interval_seconds,
    "max_concurrency": max_concurrency,
    "heartbeat": str(artifact_root / "heartbeat.json"),
    "heartbeat_log": str(heartbeat_log),
    "summary": {
        "last_kernel_overall": last_tick.get("kernel_overall", ""),
        "last_selected_for_dispatch": last_tick.get("summary", {}).get("selected_for_dispatch", 0),
        "last_human_gate": last_tick.get("summary", {}).get("human_gate", 0),
        "commands_executed": 0,
        "runner_auto_execution_allowed": False,
        "bridge_called": False,
        "long_running_process_started": False,
    },
    "ticks": ticks,
    "errors": errors,
    "invariants": [
        "Daemon dry-run is finite unless the human reruns it.",
        "Daemon dry-run only calls the read-only kernel.",
        "Daemon dry-run never calls the bridge or runner.",
        "Human Gates are observed and reported, never bypassed.",
        "Terminal override remains required for supervised bridge execution.",
    ],
    "next_cut": "TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony",
}

(artifact_root / "symphony-daemon.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

events.append(
    event(
        event_id="evt_task_symphony_daemon_completed",
        event_type="validation.completed" if technical_ok else "validation.failed",
        generated_at=completed_at,
        producer=producer,
        ticket="TASK",
        title="ARTEMIS Symphony daemon dry-run",
        exec_pack="docs/symphony/ARTEMIS_SYMPHONY_DAEMON.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to="done" if technical_ok else "failed",
        runner={"kind": "none"},
        severity="info" if technical_ok else "error",
        logs=[str(artifact_root / "symphony-daemon.json"), str(heartbeat_log)],
        payload={
            "reason": "Daemon dry-run completed without runner execution.",
            "overall": overall,
            "ticks_completed": len(ticks),
            "commands_executed": 0,
            "runner_auto_execution_allowed": False,
            "long_running_process_started": False,
        },
    )
)
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-symphony-daemon.sh", generated_at=completed_at, events=events),
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"ARTEMIS Symphony daemon dry-run esta `{overall}`.",
    "",
    "## Heartbeat",
    "",
    f"- Task source: `{input_path}`.",
    f"- Ticks requested: `{ticks_requested}`.",
    f"- Ticks completed: `{len(ticks)}`.",
    f"- Interval seconds: `{interval_seconds}`.",
    f"- Max concurrency: `{max_concurrency}`.",
    f"- Last kernel overall: `{payload['summary']['last_kernel_overall']}`.",
    f"- Last selected for dispatch: `{payload['summary']['last_selected_for_dispatch']}`.",
    f"- Last Human Gate count: `{payload['summary']['last_human_gate']}`.",
    f"- Commands executed: `0`.",
    f"- Runner auto execution allowed: `false`.",
    f"- Long-running process started: `false`.",
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
    f"- Ticks completed: `{len(ticks)}`.",
    f"- Heartbeat: `{artifact_root / 'heartbeat.json'}`.",
    f"- Heartbeat log: `{heartbeat_log}`.",
    "- Commands executed: `0`.",
    "- Runner auto execution allowed: `false`.",
    "- Bridge called: `false`.",
    "- Long-running process started: `false`.",
    "",
    "## Comandos de verificacao",
    "",
    f"- `scripts/artemis-symphony-daemon.sh --input {input_path} --artifact-root {artifact_root} --ticks {ticks_requested} --interval {interval_seconds} --max-concurrency {max_concurrency} --json`",
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
    f"Daemon dry-run concluido com `{len(ticks)}` heartbeat(s) e overall `{overall}`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony`.",
    "- Consumir item revisado da fila com comando explicito e ponte plan-only por padrao.",
    "",
    "## Nao fazer",
    "",
    "- Nao manter processo persistente sem supervisor explicito.",
    "- Nao chamar bridge ou runner automaticamente.",
    "- Nao passar Human Gates remotos, destrutivos ou de cleanup.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Daemon dry-run: {overall}")
    print(
        "summary: "
        f"ticks={len(ticks)}/{ticks_requested} "
        f"last_selected={payload['summary']['last_selected_for_dispatch']} "
        "commands_executed=0 "
        "runner_auto_execution_allowed=false"
    )

if not technical_ok:
    raise SystemExit(1)
PY
