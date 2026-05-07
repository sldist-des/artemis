#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
artifact_root="artifacts/artemis-symphony-kernel/run-01"
max_concurrency="1"
format="text"
generated=""

usage() {
  echo "usage: scripts/artemis-symphony-kernel.sh [--input path] [--artifact-root path] [--max-concurrency n] [--json]" >&2
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

if [ "$max_concurrency" -lt 1 ]; then
  echo "--max-concurrency must be greater than zero" >&2
  exit 2
fi

mkdir -p "$artifact_root"

if [ ! -f "$input" ]; then
  generated=$(mktemp "${TMPDIR:-/tmp}/artemis-symphony-kernel.XXXXXX.json")
  scripts/artemis-tasks.sh >"$generated"
  input="$generated"
fi

dry_run_path="$artifact_root/dry-run.json"
scripts/artemis-dry-run.sh --input "$input" --json >"$dry_run_path"

python3 - "$input" "$artifact_root" "$max_concurrency" "$format" "$dry_run_path" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

input_path = sys.argv[1]
artifact_root = Path(sys.argv[2])
max_concurrency = int(sys.argv[3])
output_format = sys.argv[4]
dry_run_path = Path(sys.argv[5])
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

dry_run = json.loads(dry_run_path.read_text(encoding="utf-8"))
decisions = dry_run.get("decisions", [])
if not isinstance(decisions, list):
    raise SystemExit("dry-run JSON must contain a decisions array")


def slug(value):
    text = re.sub(r"[^A-Za-z0-9_.-]+", "-", str(value).lower()).strip("-")
    return text or "task"


eligible = [item for item in decisions if item.get("decision") == "eligible"]
dispatch_slots = min(max_concurrency, len(eligible))
dispatch_plan = []

for index, item in enumerate(eligible, start=1):
    workspace = item.get("workspace", {}).get("workspace", {})
    slot = ((index - 1) % max_concurrency) + 1
    dispatch_plan.append(
        {
            "order": index,
            "slot": slot,
            "ticket": item.get("ticket", "TASK"),
            "title": item.get("title", ""),
            "state": item.get("state", ""),
            "runner": item.get("runner", "none"),
            "exec_pack": item.get("exec_pack", ""),
            "workspace": workspace,
            "decision": "planned_read_only",
            "reason": item.get("reason", ""),
            "runner_execution_allowed": False,
            "commands_executed": 0,
        }
    )

non_dispatch = [
    {
        "ticket": item.get("ticket", "TASK"),
        "title": item.get("title", ""),
        "decision": item.get("decision", ""),
        "runner": item.get("runner", "none"),
        "reason": item.get("reason", ""),
    }
    for item in decisions
    if item.get("decision") != "eligible"
]

dry_summary = dry_run.get("summary", {})
overall = "dispatch_plan_ready" if dispatch_plan else "idle"
summary = {
    "tasks_total": len(decisions),
    "eligible": int(dry_summary.get("eligible", 0)),
    "blocked": int(dry_summary.get("blocked", 0)),
    "human_gate": int(dry_summary.get("human_gate", 0)),
    "done": int(dry_summary.get("done", 0)),
    "selected_for_dispatch": len(dispatch_plan),
    "max_concurrency": max_concurrency,
    "dispatch_slots": dispatch_slots,
    "commands_executed": 0,
    "runner_execution_allowed": False,
}
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-kernel.sh",
    "mode": "read_only",
    "overall": overall,
    "task_source": input_path,
    "artifact_root": str(artifact_root),
    "dry_run": str(dry_run_path),
    "summary": summary,
    "dispatch_plan": dispatch_plan,
    "non_dispatch": non_dispatch,
    "invariants": [
        "Kernel is read-only and does not execute agents.",
        "Kernel does not create worktrees, branches, locks, PRs, pushes, merges or cleanup.",
        "Dry-run remains the eligibility source for dispatch decisions.",
        "Human Gates are copied into the plan and never bypassed.",
        "Terminal override remains required for any future supervised execution.",
    ],
    "next_cut": "TKT-053 - Feedback remoto supervisionado do ARTEMIS Symphony",
}

(artifact_root / "symphony-kernel.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

events = []
producer = {
    "adapter": "local_runner",
    "name": "scripts/artemis-symphony-kernel.sh",
    "mode": "read_only",
}
if dispatch_plan:
    for item in dispatch_plan:
        ticket = str(item["ticket"])
        events.append(
            event(
                event_id=f"evt_{slug(ticket)}_symphony_dispatch_planned",
                event_type="runner.readiness_checked",
                generated_at=generated_at,
                producer=producer,
                ticket=ticket,
                title=str(item.get("title", "")),
                exec_pack=str(item.get("exec_pack", "")),
                artifact_root=str(artifact_root),
                state_from=str(item.get("state", "")) or None,
                state_to="ready",
                runner={"kind": "none"},
                payload={
                    "reason": "Read-only Symphony kernel planned dispatch without execution.",
                    "slot": item["slot"],
                    "order": item["order"],
                    "commands_executed": 0,
                    "runner_execution_allowed": False,
                },
            )
        )
else:
    events.append(
        event(
            event_id="evt_task_symphony_kernel_idle",
            event_type="validation.completed",
            generated_at=generated_at,
            producer=producer,
            ticket="TASK",
            title="ARTEMIS Symphony kernel",
            exec_pack="docs/symphony/ARTEMIS_SYMPHONY_SPEC.md",
            artifact_root=str(artifact_root),
            state_to="done",
            runner={"kind": "none"},
            payload={
                "reason": "Read-only Symphony kernel found no eligible dispatch work.",
                "commands_executed": 0,
                "runner_execution_allowed": False,
            },
        )
    )
write_event_log(
    artifact_root / "events.json",
    event_log(source="scripts/artemis-symphony-kernel.sh", generated_at=generated_at, events=events),
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"ARTEMIS Symphony kernel esta `{overall}` em modo read-only.",
    "",
    "## Dispatch",
    "",
    f"- Task source: `{input_path}`.",
    f"- Dry-run: `{dry_run_path}`.",
    f"- Max concurrency: `{max_concurrency}`.",
    f"- Dispatch slots: `{dispatch_slots}`.",
    f"- Selected for dispatch: `{len(dispatch_plan)}`.",
    f"- Commands executed: `0`.",
    f"- Runner execution allowed: `false`.",
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
    f"- Tasks total: `{len(decisions)}`.",
    f"- Eligible: `{summary['eligible']}`.",
    f"- Selected for dispatch: `{len(dispatch_plan)}`.",
    f"- Max concurrency: `{max_concurrency}`.",
    f"- Commands executed: `0`.",
    f"- Runner execution allowed: `false`.",
    "",
    "## Comandos de verificacao",
    "",
    f"- `scripts/artemis-symphony-kernel.sh --input {input_path} --artifact-root {artifact_root} --max-concurrency {max_concurrency} --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
]
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"Kernel local read-only concluido com overall `{overall}`.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-053 - Feedback remoto supervisionado do ARTEMIS Symphony`.",
    "- Continuar com ponte plan-only por padrao e comando explicito por terminal.",
    "",
    "## Nao fazer",
    "",
    "- Nao executar agentes a partir deste kernel.",
    "- Nao fazer push, PR, merge, cleanup ou configuracao remota.",
    "- Nao transformar Control Plane em fonte canonica.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Kernel: {overall}")
    print(
        "summary: "
        f"tasks={len(decisions)} "
        f"eligible={summary['eligible']} "
        f"selected={len(dispatch_plan)} "
        f"max_concurrency={max_concurrency} "
        "commands_executed=0"
    )
PY

if [ -n "$generated" ]; then
  rm -f "$generated"
fi
