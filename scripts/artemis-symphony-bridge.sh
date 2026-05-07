#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
artifact_root="artifacts/artemis-symphony-bridge/run-01"
ticket=""
command=""
max_concurrency="1"
format="text"
execute=0
use_workspace=0

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-bridge.sh --ticket TKT-000 --command "cmd" [--input path] [--artifact-root path] [--max-concurrency n] [--execute] [--use-workspace] [--json]

Default mode is supervised plan-only. The bridge runs the read-only kernel,
selects an eligible dispatch item, and creates a local runner attempt without
executing the command.
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
    --ticket)
      ticket="${2:-}"
      if [ -z "$ticket" ]; then usage; exit 2; fi
      shift 2
      ;;
    --command)
      command="${2:-}"
      if [ -z "$command" ]; then usage; exit 2; fi
      shift 2
      ;;
    --max-concurrency)
      max_concurrency="${2:-}"
      if [ -z "$max_concurrency" ]; then usage; exit 2; fi
      shift 2
      ;;
    --execute)
      execute=1
      shift
      ;;
    --use-workspace)
      use_workspace=1
      shift
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

if [ -z "$ticket" ] || [ -z "$command" ]; then
  usage
  exit 2
fi

case "$max_concurrency" in
  ''|*[!0-9]*)
    echo "--max-concurrency must be a positive integer" >&2
    exit 2
    ;;
esac

if [ "$max_concurrency" -lt 1 ]; then
  echo "--max-concurrency must be greater than zero" >&2
  exit 2
fi

if [ "$use_workspace" -eq 1 ] && [ "$execute" -ne 1 ]; then
  echo "--use-workspace requires --execute" >&2
  exit 2
fi

mkdir -p "$artifact_root"
kernel_root="$artifact_root/kernel"
runner_root="$artifact_root/runner"
rm -rf "$kernel_root" "$runner_root"
rm -f "$artifact_root/selected-dispatch.json" "$artifact_root/selection.stderr" "$artifact_root/runner.stderr"
mkdir -p "$kernel_root" "$runner_root"

kernel_json="$kernel_root/symphony-kernel.json"
scripts/artemis-symphony-kernel.sh \
  --input "$input" \
  --artifact-root "$kernel_root" \
  --max-concurrency "$max_concurrency" \
  --json >/dev/null

runner_status=0
runner_attempt=""

set +e
python3 - "$kernel_json" "$ticket" >"$artifact_root/selected-dispatch.json" 2>"$artifact_root/selection.stderr" <<'PY'
import json
import sys
from pathlib import Path

kernel = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
ticket = sys.argv[2]
item = next((entry for entry in kernel.get("dispatch_plan", []) if entry.get("ticket") == ticket), None)
if not item:
    raise SystemExit(f"ticket not present in dispatch_plan: {ticket}")
print(json.dumps(item, ensure_ascii=False))
PY
selection_status=$?
set -e

if [ "$selection_status" -eq 0 ]; then
  set +e
  if [ "$execute" -eq 1 ] && [ "$use_workspace" -eq 1 ]; then
    runner_attempt=$(scripts/artemis-runner.sh --input "$input" --ticket "$ticket" --command "$command" --artifact-root "$runner_root" --execute --use-workspace 2>"$artifact_root/runner.stderr")
  elif [ "$execute" -eq 1 ]; then
    runner_attempt=$(scripts/artemis-runner.sh --input "$input" --ticket "$ticket" --command "$command" --artifact-root "$runner_root" --execute 2>"$artifact_root/runner.stderr")
  else
    runner_attempt=$(scripts/artemis-runner.sh --input "$input" --ticket "$ticket" --command "$command" --artifact-root "$runner_root" 2>"$artifact_root/runner.stderr")
  fi
  runner_status=$?
  set -e
else
  printf 'ticket not present in dispatch_plan: %s\n' "$ticket" >"$artifact_root/runner.stderr"
  runner_status=3
fi

python3 - "$artifact_root" "$kernel_json" "$input" "$ticket" "$command" "$max_concurrency" "$execute" "$use_workspace" "$runner_status" "$runner_attempt" "$format" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

(
    artifact_root,
    kernel_json,
    input_path,
    ticket,
    command,
    max_concurrency,
    execute,
    use_workspace,
    runner_status,
    runner_attempt,
    output_format,
) = sys.argv[1:12]

artifact_root = Path(artifact_root)
kernel_path = Path(kernel_json)
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
kernel = json.loads(kernel_path.read_text(encoding="utf-8"))
runner_status_code = int(runner_status)
executed = execute == "1"
workspace_requested = use_workspace == "1"
runner_attempt = runner_attempt.strip()


def slug(value):
    text = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(value).lower()).strip("-")
    return text or "task"


selected = next((item for item in kernel.get("dispatch_plan", []) if item.get("ticket") == ticket), None)
runner_attempt_path = runner_attempt.splitlines()[-1] if runner_attempt else ""
runner_events = f"{runner_attempt_path}/events.json" if runner_attempt_path else ""
runner_planned = runner_status_code == 0 and bool(runner_attempt_path)

if selected and runner_planned:
    overall = "runner_plan_ready" if not executed else "runner_executed"
elif selected:
    overall = "runner_failed"
else:
    overall = "not_dispatchable"

summary = {
    "kernel_overall": kernel.get("overall"),
    "kernel_selected_for_dispatch": kernel.get("summary", {}).get("selected_for_dispatch", 0),
    "max_concurrency": int(max_concurrency),
    "selected_ticket": ticket,
    "ticket_in_dispatch_plan": bool(selected),
    "runner_planned": runner_planned,
    "runner_exit_code": runner_status_code,
    "execute_requested": executed,
    "use_workspace": workspace_requested,
    "commands_executed": 1 if executed and runner_status_code == 0 else 0,
    "automatic_daemon": False,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-bridge.sh",
    "mode": "supervised_bridge",
    "overall": overall,
    "task_source": input_path,
    "artifact_root": str(artifact_root),
    "kernel": str(kernel_path),
    "runner_attempt": runner_attempt_path,
    "runner_events": runner_events,
    "summary": summary,
    "selected_dispatch": selected,
    "command": command,
    "invariants": [
        "Bridge is not a daemon.",
        "Bridge runs the kernel before touching the runner.",
        "Bridge only selects tickets present in dispatch_plan.",
        "Default mode is runner plan-only.",
        "Runner execution requires explicit --execute.",
        "Remote, destructive and deployment commands remain blocked by the runner.",
    ],
    "next_cut": "TKT-051 - Intake remoto revisavel do ARTEMIS Symphony",
}

(artifact_root / "symphony-bridge.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

producer = {
    "adapter": "local_runner",
    "name": "scripts/artemis-symphony-bridge.sh",
    "mode": "supervised",
}
events = [
    event(
        event_id=f"evt_{slug(ticket)}_symphony_bridge",
        event_type="runner.attempt_planned" if runner_planned else "human_gate.opened",
        generated_at=generated_at,
        producer=producer,
        ticket=ticket,
        title=str((selected or {}).get("title", "ARTEMIS Symphony bridge")),
        exec_pack=str((selected or {}).get("exec_pack", "docs/symphony/ARTEMIS_SYMPHONY_KERNEL.md")),
        artifact_root=str(artifact_root),
        state_from="ready" if selected else "context",
        state_to="running" if runner_planned else "human_gate",
        runner={"kind": "codex_cli" if runner_planned else "none", "command": command},
        severity="info" if runner_planned else "warning",
        logs=[str(kernel_path), runner_events] if runner_events else [str(kernel_path)],
        payload={
            "reason": (
                "Symphony bridge created a supervised runner attempt."
                if runner_planned
                else "Symphony bridge could not select a dispatchable ticket."
            ),
            "overall": overall,
            "execute_requested": executed,
            "commands_executed": summary["commands_executed"],
            "automatic_daemon": False,
        },
    )
]
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-symphony-bridge.sh", generated_at=generated_at, events=events),
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"ARTEMIS Symphony Bridge esta `{overall}`.",
    "",
    "## Ponte",
    "",
    f"- Task source: `{input_path}`.",
    f"- Ticket: `{ticket}`.",
    f"- Kernel: `{kernel_path}`.",
    f"- Runner attempt: `{runner_attempt_path or 'none'}`.",
    f"- Execute requested: `{str(executed).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Automatic daemon: `false`.",
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
    f"- Ticket in dispatch plan: `{str(bool(selected)).lower()}`.",
    f"- Runner planned: `{str(runner_planned).lower()}`.",
    f"- Execute requested: `{str(executed).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    f"- Automatic daemon: `false`.",
    "",
    "## Comandos de verificacao",
    "",
    f"- `scripts/artemis-symphony-bridge.sh --input {input_path} --ticket {ticket} --command \"{command}\" --artifact-root {artifact_root} --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"Bridge supervisionada concluida com overall `{overall}`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-051 - Intake remoto revisavel do ARTEMIS Symphony`.",
    "- Consumir item revisado da fila com comando explicito e ponte plan-only por padrao.",
    "",
    "## Nao fazer",
    "",
    "- Nao iniciar daemon a partir da ponte.",
    "- Nao executar comandos sem `--execute` explicito.",
    "- Nao passar Human Gates remotos ou destrutivos.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Bridge: {overall}")
    print(
        "summary: "
        f"ticket={ticket} "
        f"runner_planned={str(runner_planned).lower()} "
        f"execute_requested={str(executed).lower()} "
        f"commands_executed={summary['commands_executed']}"
    )

if overall in {"runner_failed", "not_dispatchable"}:
    raise SystemExit(3)
PY
