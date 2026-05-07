#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

remote_intake="artifacts/artemis-symphony-remote-intake/run-01/remote-intake.json"
decision=""
artifact_root="artifacts/artemis-symphony-promotion/run-01"
format="text"

usage() {
  cat >&2 <<'EOF'
usage: scripts/artemis-symphony-remote-promotion.sh [--remote-intake path] [--decision path] [--artifact-root path] [--json]

Promotes a reviewed ARTEMIS Symphony remote intake item into a local executable
task source only when an exact human decision is provided. It never calls queue,
bridge, runner, GitHub, or any remote write surface.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --remote-intake)
      remote_intake="${2:-}"
      if [ -z "$remote_intake" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision)
      decision="${2:-}"
      if [ -z "$decision" ]; then usage; exit 2; fi
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

python3 - "$remote_intake" "$decision" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, write_event_log

remote_intake_path = Path(sys.argv[1])
decision_arg = sys.argv[2]
decision_path = Path(decision_arg) if decision_arg else None
artifact_root = Path(sys.argv[3])
output_format = sys.argv[4]


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_text(path, text):
    path.write_text(text, encoding="utf-8")


def read_json(path, label, errors):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        errors.append(f"missing {label}: {path}")
    except json.JSONDecodeError as exc:
        errors.append(f"invalid {label}: {exc}")
    return {}


def as_bool(value):
    return bool(value) if isinstance(value, bool) else str(value).lower() == "true"


def valid_risk(value):
    return str(value).lower() in {"low", "medium", "high"}


def task_text(value):
    return str(value or "").strip()


generated_at = now_utc()
artifact_root.mkdir(parents=True, exist_ok=True)
errors = []
blockers = []
warnings = []

intake = read_json(remote_intake_path, "remote intake artifact", errors)
decision = read_json(decision_path, "promotion decision", errors) if decision_path else {}

intake_overall = intake.get("overall", "failed")
items = intake.get("items") or []
items_by_ticket = {str(item.get("ticket") or ""): item for item in items}

decision_ticket = task_text(decision.get("ticket"))
decision_value = task_text(decision.get("decision")).lower()
promote_to = task_text(decision.get("promote_to") or decision_ticket)
title = task_text(decision.get("title"))
owner = task_text(decision.get("owner"))
risk = task_text(decision.get("risk")).lower()
exec_pack = task_text(decision.get("exec_pack"))
evidence = task_text(decision.get("evidence"))
command = task_text(decision.get("command"))
validation_gate = task_text(decision.get("validation_gate"))
decided_by = task_text(decision.get("decided_by"))
reason = task_text(decision.get("reason"))

selected_item = items_by_ticket.get(decision_ticket) if decision_ticket else None

if not errors:
    if intake_overall not in {"remote_intake_ready", "remote_intake_human_gate"}:
        blockers.append(f"remote intake is not promotable: {intake_overall}")
    if not decision_path:
        blockers.append("missing exact human promotion decision")
    elif decision_value != "approved":
        blockers.append("promotion decision is not approved")
    if decision_path and not decision_ticket:
        blockers.append("decision missing ticket")
    if decision_path and not selected_item:
        blockers.append(f"decision ticket not found in intake: {decision_ticket or 'missing'}")
    if selected_item and selected_item.get("status") != "review_ready":
        blockers.append(f"intake item is not review_ready: {selected_item.get('status')}")

    required = [
        ("promote_to", promote_to),
        ("title", title),
        ("owner", owner),
        ("risk", risk),
        ("exec_pack", exec_pack),
        ("evidence", evidence),
        ("command", command),
        ("validation_gate", validation_gate),
        ("decided_by", decided_by),
        ("reason", reason),
    ]
    for name, value in required:
        if decision_path and not value:
            blockers.append(f"decision missing {name}")
    if decision_path and not valid_risk(risk):
        blockers.append("decision risk must be low, medium, or high")
    if decision_path and exec_pack and not Path(exec_pack).is_file():
        blockers.append(f"Exec Pack not found: {exec_pack}")
    if decision_path and validation_gate and not Path(validation_gate).is_file():
        blockers.append(f"Validation Gate artifact not found: {validation_gate}")
    if decision_path and not as_bool(decision.get("remote_review_acknowledged")):
        blockers.append("decision must acknowledge the remote intake review")
    if decision_path and not as_bool(decision.get("terminal_command_acknowledged")):
        blockers.append("decision must acknowledge the exact terminal command")
    if decision_path and not as_bool(decision.get("validation_gate_required")):
        blockers.append("decision must require Validation Gate before execution")
    if selected_item and as_bool(selected_item.get("promotion_allowed")):
        warnings.append("intake item unexpectedly marked promotion_allowed=true; decision still overrides authority")

promoted_tasks = []
if not errors and not blockers:
    promoted_tasks.append({
        "id": promote_to.lower(),
        "ticket": promote_to,
        "title": title,
        "state": "ready",
        "owner": owner,
        "risk": risk,
        "summary": "Locally approved ARTEMIS Symphony task. Use the recorded terminal command manually after Validation Gate evidence is checked.",
        "exec_pack": exec_pack,
        "evidence": evidence,
        "tags": ["symphony", "local-promotion", "approved-source"],
        "promotion": {
            "source_ticket": decision_ticket,
            "decision": str(decision_path),
            "decided_by": decided_by,
            "reason": reason,
            "command": command,
            "validation_gate": validation_gate,
        },
    })

summary = {
    "intake_items": len(items),
    "review_ready": sum(1 for item in items if item.get("status") == "review_ready"),
    "promoted": len(promoted_tasks),
    "human_gate": 0 if promoted_tasks else 1,
    "blocked": 1 if errors else 0,
    "promotion_allowed": len(promoted_tasks),
    "direct_dispatch_allowed": False,
    "remote_writes_allowed": False,
    "runner_auto_execution_allowed": False,
    "queue_called": False,
    "bridge_called": False,
    "runner_called": False,
    "commands_executed": 0,
}

if errors:
    overall = "failed"
    final_reason = "; ".join(errors)
elif promoted_tasks:
    overall = "remote_promotion_ready"
    final_reason = "Exact human decision promoted reviewed intake into a local task source."
elif blockers:
    overall = "remote_promotion_human_gate"
    final_reason = "; ".join(blockers)
else:
    overall = "remote_promotion_empty"
    final_reason = "No reviewed intake item was available for local promotion."

promotion_contract = {
    "remote_intake_defines": "review_package",
    "human_decision_defines": "local_promotion_authority",
    "exec_pack_defines": "execution_contract",
    "promoted_source_state": "ready_after_exact_human_decision",
    "terminal_command_required": True,
    "validation_gate_required_before_execute": True,
    "queue_call": "blocked",
    "bridge_call": "blocked",
    "runner_call": "blocked",
    "direct_dispatch": "blocked",
    "remote_writes": "blocked",
    "terminal_first": True,
    "human_gates_preserved": True,
}

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-remote-promotion.sh",
    "mode": "local_promotion_decision_gate",
    "overall": overall,
    "reason": final_reason,
    "artifact_root": str(artifact_root),
    "remote_intake": str(remote_intake_path),
    "decision": str(decision_path) if decision_path else "",
    "summary": summary,
    "contract": promotion_contract,
    "selected_ticket": decision_ticket,
    "promoted_source": str(artifact_root / "promoted-source.json"),
    "blockers": blockers,
    "warnings": warnings,
    "next_cut": "TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony",
}

promoted_source = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-symphony-remote-promotion.sh",
    "mode": "local_promoted_task_source",
    "contract": promotion_contract,
    "tasks": promoted_tasks,
}

write_text(artifact_root / "remote-promotion.json", json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
write_text(artifact_root / "promoted-source.json", json.dumps(promoted_source, ensure_ascii=False, indent=2) + "\n")

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    f"- Overall: `{overall}`.",
    f"- Reason: {final_reason}",
    f"- Intake: `{intake_overall}`.",
    f"- Decision: `{str(decision_path) if decision_path else 'missing'}`.",
    f"- Promoted: `{summary['promoted']}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    "",
    "## Contrato",
    "",
    "- Promocao local exige decisao humana exata.",
    "- A fonte promovida e local e nao chama fila, bridge ou runner.",
    "- O comando terminal fica registrado, mas nao e executado por este corte.",
    "- Validation Gate continua obrigatorio antes de execucao.",
    "- Escritas remotas continuam bloqueadas.",
]
write_text(artifact_root / "STATUS.md", "\n".join(status_lines) + "\n")

decision_lines = [
    "# PROMOTION DECISION",
    "",
    "## Fonte",
    "",
    f"- Remote intake: `{remote_intake_path}`.",
    f"- Decision: `{str(decision_path) if decision_path else 'missing'}`.",
    f"- Selected ticket: `{decision_ticket or 'missing'}`.",
    f"- Promoted ticket: `{promote_to or 'missing'}`.",
    "",
    "## Decisao",
    "",
    f"- Overall: `{overall}`.",
    f"- Approved by: `{decided_by or 'missing'}`.",
    f"- Reason: {reason or 'missing'}",
    f"- Command: `{command or 'missing'}`.",
    f"- Validation Gate: `{validation_gate or 'missing'}`.",
    "",
    "## Blockers",
    "",
]
decision_lines.extend(f"- {blocker}" for blocker in blockers)
if not blockers:
    decision_lines.append("- Nenhum blocker tecnico.")
write_text(artifact_root / "DECISION.md", "\n".join(decision_lines) + "\n")

validation_lines = [
    "# VALIDATION",
    "",
    "## Resultado local",
    "",
    f"- Overall: `{overall}`.",
    f"- Promoted source tasks: `{len(promoted_tasks)}`.",
    f"- Direct dispatch allowed: `{str(summary['direct_dispatch_allowed']).lower()}`.",
    f"- Remote writes allowed: `{str(summary['remote_writes_allowed']).lower()}`.",
    f"- Queue called: `{str(summary['queue_called']).lower()}`.",
    f"- Bridge called: `{str(summary['bridge_called']).lower()}`.",
    f"- Runner called: `{str(summary['runner_called']).lower()}`.",
    f"- Commands executed: `{summary['commands_executed']}`.",
    "",
    "## Comandos",
    "",
    f"- `scripts/artemis-symphony-remote-promotion.sh --remote-intake {remote_intake_path} --decision {str(decision_path) if decision_path else '<decision.json>'} --artifact-root {artifact_root} --json`",
    "- `scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-promotion/run-01/promoted-source.json --json`",
    "- `scripts/validate-artemis.sh`",
    "- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`",
    "- `git diff --check`",
]
write_text(artifact_root / "VALIDATION.md", "\n".join(validation_lines) + "\n")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"Promocao local do intake esta `{overall}`. A fonte local promovida fica em `promoted-source.json` e ainda nao executa nada sozinha.",
    "",
    "## Proximo corte",
    "",
    "- Implementar `TKT-059 - Agent Runtime Dry-Run do ARTEMIS Symphony`.",
    "- Manter comentarios, labels, branches e PRs atras de decisao humana exata.",
    "",
    "## Nao fazer",
    "",
    "- Nao chamar Queue, Bridge ou Runner a partir da promocao.",
    "- Nao escrever em GitHub.",
    "- Nao aceitar decisao generica sem ticket, Exec Pack, evidencia, owner, risco e comando exatos.",
]
write_text(artifact_root / "HANDOFF.md", "\n".join(handoff_lines) + "\n")

state_to = "ready" if promoted_tasks else ("blocked" if errors else "human_gate")
severity = "info" if promoted_tasks else ("error" if errors else "warning")
gate = {"kind": "none", "status": "not_applicable"}
if not promoted_tasks:
    gate = {
        "kind": "human",
        "status": "human_gate",
        "reason": final_reason,
        "options": ["provide exact approval decision", "keep item in review", "continue local-only"],
    }

events = [
    event(
        event_id="evt_tkt-052_symphony_remote_promotion",
        event_type="approval.resolved" if promoted_tasks else "approval.requested",
        generated_at=generated_at,
        producer={"adapter": "symphony_remote_promotion", "name": "scripts/artemis-symphony-remote-promotion.sh", "mode": "supervised"},
        ticket="TKT-052",
        title="Promocao local do intake remoto do ARTEMIS Symphony",
        exec_pack="docs/exec-packs/done/TKT-052-artemis-symphony-remote-promotion.md",
        artifact_root=str(artifact_root),
        state_from="review",
        state_to=state_to,
        runner={"kind": "none", "command": command or ""},
        gate=gate,
        severity=severity,
        payload={
            "overall": overall,
            "reason": final_reason,
            "summary": summary,
            "contract": promotion_contract,
            "next_cut": payload["next_cut"],
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-symphony-remote-promotion.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Symphony Remote Promotion: {overall}")
    print(
        "summary: "
        f"promoted={summary['promoted']} "
        f"human_gate={summary['human_gate']} "
        f"commands_executed={summary['commands_executed']}"
    )

if overall == "failed":
    sys.exit(1)
PY
