#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

pending_gate_root="artifacts/artemis-human-decision-pending-gate/run-01"
intake_root="artifacts/artemis-human-decision-intake/run-01"
decision="artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json"
artifact_root="artifacts/artemis-human-decision-reentry-contract/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-human-decision-reentry-contract.sh [--pending-gate-root path] [--intake-root path] [--decision path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --pending-gate-root)
      pending_gate_root="${2:-}"
      if [ -z "$pending_gate_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --intake-root)
      intake_root="${2:-}"
      if [ -z "$intake_root" ]; then usage; exit 2; fi
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

python3 - "$pending_gate_root" "$intake_root" "$decision" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

pending_gate_root = Path(sys.argv[1])
intake_root = Path(sys.argv[2])
decision_path = Path(sys.argv[3])
artifact_root = Path(sys.argv[4])
output_format = sys.argv[5]

generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
blockers = []


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        blockers.append(f"missing JSON: {path}")
    except json.JSONDecodeError as exc:
        blockers.append(f"invalid JSON at {path}: {exc}")
    return {}


def require_file(path, label, inventory):
    exists = path.is_file()
    inventory.append({"label": label, "path": str(path), "exists": exists})
    if not exists:
        blockers.append(f"missing {label}: {path}")


inventory = []
pending_gate_path = pending_gate_root / "human-decision-pending-gate.json"
intake_path = intake_root / "human-decision-intake.json"

require_file(pending_gate_path, "human decision pending gate JSON", inventory)
require_file(pending_gate_root / "STATUS.md", "human decision pending gate status", inventory)
require_file(pending_gate_root / "VALIDATION.md", "human decision pending gate validation", inventory)
require_file(pending_gate_root / "HANDOFF.md", "human decision pending gate handoff", inventory)
require_file(intake_path, "human decision intake JSON", inventory)
require_file(intake_root / "STATUS.md", "human decision intake status", inventory)
require_file(intake_root / "VALIDATION.md", "human decision intake validation", inventory)
require_file(intake_root / "HANDOFF.md", "human decision intake handoff", inventory)
require_file(decision_path, "real cleanup decision file", inventory)

pending_gate = read_json(pending_gate_path) if pending_gate_path.is_file() else {}
intake = read_json(intake_path) if intake_path.is_file() else {}
decision = read_json(decision_path) if decision_path.is_file() else {}

summary = intake.get("summary", {})
pending_summary = pending_gate.get("summary", {})
results = intake.get("results", [])

if pending_gate.get("mode") != "read_only":
    blockers.append("pending gate is not read_only")
if intake.get("mode") != "read_only":
    blockers.append("intake is not read_only")
if pending_summary.get("executed_commands", 0) != 0:
    blockers.append("pending gate detected executed commands")
if summary.get("executed_commands", 0) != 0:
    blockers.append("intake detected executed commands")
if pending_gate.get("cleanup_execution_allowed") is not False:
    blockers.append("pending gate did not explicitly deny cleanup execution")
if intake.get("cleanup_execution_allowed") is not False:
    blockers.append("intake did not explicitly deny cleanup execution")
decision_summary = decision.get("summary", {})
reviews = decision.get("reviews", [])
if decision_summary.get("execute_allowed", 0) != 0:
    blockers.append("decision package summary allowed execution")
if any(review.get("cleanup_allowed_by_script") is not False for review in reviews):
    blockers.append("one or more decision reviews did not preserve script cleanup gate")

state_counts = {
    "approved_ready": summary.get("approved_ready", 0),
    "pending": summary.get("pending", 0),
    "deferred": summary.get("deferred", 0),
    "rejected": summary.get("rejected", 0),
    "invalid": summary.get("invalid", 0),
    "executed_commands": summary.get("executed_commands", 0),
}

if state_counts["invalid"]:
    reentry_state = "invalid_decision_record"
    next_lane = "fix_decision_before_any_preflight"
elif state_counts["pending"]:
    reentry_state = "human_gate"
    next_lane = "human_must_fill_decision_record"
elif state_counts["deferred"] or state_counts["rejected"]:
    reentry_state = "closed_without_cleanup"
    next_lane = "record_no_cleanup_and_keep_workspace"
elif state_counts["approved_ready"]:
    reentry_state = "ready_for_supervised_preflight"
    next_lane = "future_preflight_only"
else:
    reentry_state = "no_reentry_target"
    next_lane = "review_decision_inventory"

preflight_allowed = (
    not blockers
    and reentry_state == "ready_for_supervised_preflight"
    and state_counts["approved_ready"] > 0
    and state_counts["pending"] == 0
    and state_counts["deferred"] == 0
    and state_counts["rejected"] == 0
    and state_counts["invalid"] == 0
    and state_counts["executed_commands"] == 0
)

cleanup_execution_allowed = False
overall = "failed" if blockers else reentry_state

contracts = {
    "approved_ready": {
        "meaning": "Decision record and dry-run agree that a workspace can enter a future supervised preflight.",
        "allows_preflight": True,
        "allows_executor": False,
        "required_next_step": "Create or run a later preflight artifact; do not execute cleanup from this contract.",
    },
    "pending": {
        "meaning": "Human decision fields are still incomplete.",
        "allows_preflight": False,
        "allows_executor": False,
        "required_next_step": "Human fills decision_record and reruns intake plus this reentry contract.",
    },
    "deferred": {
        "meaning": "Human chose to revisit later.",
        "allows_preflight": False,
        "allows_executor": False,
        "required_next_step": "Keep workspace state and record the deferral.",
    },
    "rejected": {
        "meaning": "Human declined cleanup for that workspace.",
        "allows_preflight": False,
        "allows_executor": False,
        "required_next_step": "Record refusal and keep workspace state.",
    },
    "invalid": {
        "meaning": "Decision metadata or command list is inconsistent.",
        "allows_preflight": False,
        "allows_executor": False,
        "required_next_step": "Fix the decision record before any next lane.",
    },
}

validation_commands_after_human_fill = [
    f"scripts/artemis-human-cleanup-approval-contract.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01/approval-contract --json",
    f"scripts/artemis-approved-workspace-cleanup.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01/cleanup-dry-run --json",
    f"scripts/artemis-human-decision-intake.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01 --json",
    f"scripts/artemis-human-decision-pending-gate.sh --intake-root artifacts/artemis-human-decision-intake/run-01 --decision {decision_path} --artifact-root artifacts/artemis-human-decision-pending-gate/run-01 --json",
    f"scripts/artemis-human-decision-reentry-contract.sh --pending-gate-root artifacts/artemis-human-decision-pending-gate/run-01 --intake-root artifacts/artemis-human-decision-intake/run-01 --decision {decision_path} --artifact-root {artifact_root} --json",
    "scripts/validate-artemis.sh",
]

reentry_results = []
for item in results:
    intake_state = item.get("intake_state", "invalid")
    state_contract = contracts.get(intake_state, contracts["invalid"])
    reentry_results.append({
        "ticket": item.get("ticket"),
        "title": item.get("title", ""),
        "intake_state": intake_state,
        "contract_state": intake_state if intake_state in contracts else "invalid",
        "allows_preflight": bool(state_contract["allows_preflight"]) and preflight_allowed,
        "allows_executor": False,
        "required_next_step": state_contract["required_next_step"],
        "next_action_from_intake": item.get("next_action", ""),
    })

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-decision-reentry-contract.sh",
    "mode": "read_only",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "pending_gate_root": str(pending_gate_root),
    "intake_root": str(intake_root),
    "decision": str(decision_path),
    "preflight_allowed": preflight_allowed,
    "cleanup_execution_allowed": cleanup_execution_allowed,
    "summary": {
        **state_counts,
        "reviewed": summary.get("reviewed", len(results)),
        "preflight_allowed": preflight_allowed,
        "cleanup_execution_allowed": cleanup_execution_allowed,
    },
    "state_contracts": contracts,
    "results": reentry_results,
    "validation_commands_after_human_fill": validation_commands_after_human_fill,
    "evidence_inventory": inventory,
    "blockers": blockers,
    "next_lane": next_lane,
    "invariants": [
        "Reentry is read-only and is not an executor.",
        "approved_ready permits only a future supervised preflight.",
        "approved_ready does not execute cleanup by itself.",
        "pending, deferred, rejected, and invalid do not enter an executor.",
        "No command with --execute is emitted by this contract.",
        "Remote writes remain Human Gate.",
    ],
}

(artifact_root / "human-decision-reentry-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "TKT-038 definiu o contrato read-only de reentrada apos decisao humana.",
    "",
    "## Estado da reentrada",
    "",
    f"- Overall: `{overall}`.",
    f"- Reviewed: `{payload['summary']['reviewed']}`.",
    f"- Approved ready: `{state_counts['approved_ready']}`.",
    f"- Pending: `{state_counts['pending']}`.",
    f"- Deferred: `{state_counts['deferred']}`.",
    f"- Rejected: `{state_counts['rejected']}`.",
    f"- Invalid: `{state_counts['invalid']}`.",
    f"- Executed commands: `{state_counts['executed_commands']}`.",
    f"- Preflight allowed: `{str(preflight_allowed).lower()}`.",
    f"- Cleanup execution allowed: `{str(cleanup_execution_allowed).lower()}`.",
    f"- Next lane: `{next_lane}`.",
    "",
    "## Contrato por estado",
    "",
]
for state, contract in contracts.items():
    status_lines.extend([
        f"### {state}",
        "",
        f"- Meaning: {contract['meaning']}",
        f"- Allows preflight: `{str(contract['allows_preflight']).lower()}`.",
        f"- Allows executor: `{str(contract['allows_executor']).lower()}`.",
        f"- Required next step: {contract['required_next_step']}",
        "",
    ])

status_lines.extend([
    "## Invariantes preservados",
    "",
])
for invariant in payload["invariants"]:
    status_lines.append(f"- {invariant}")
(artifact_root / "STATUS.md").write_text("\n".join(status_lines).rstrip() + "\n", encoding="utf-8")

validation_lines = [
    "# VALIDATION",
    "",
    "## Entradas validadas",
    "",
    f"- Pending gate: `{pending_gate_path}`.",
    f"- Intake: `{intake_path}`.",
    f"- Decision file: `{decision_path}`.",
    "",
    "## Comandos apos preenchimento humano",
    "",
]
for command in validation_commands_after_human_fill:
    validation_lines.append(f"- `{command}`")

validation_lines.extend([
    "",
    "## Resultado local",
    "",
])
if blockers:
    validation_lines.append("Contrato falhou pelos blockers abaixo:")
    validation_lines.append("")
    for blocker in blockers:
        validation_lines.append(f"- {blocker}")
else:
    validation_lines.append(
        f"Contrato registrado como `{overall}` com `preflight_allowed={str(preflight_allowed).lower()}` "
        f"e `cleanup_execution_allowed={str(cleanup_execution_allowed).lower()}`."
    )

validation_lines.extend([
    "",
    "## Gaps",
    "",
    "- Nenhuma decisao humana real foi preenchida por este script.",
    "- Nenhum preflight supervisionado foi executado.",
    "- Nenhum cleanup real foi executado.",
    "- Nenhum comando com `--execute` foi emitido.",
])
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-038 terminou em `{overall}` com `next_lane={next_lane}`.",
    "",
    "## Reentrada segura",
    "",
    "- Rerode o intake depois que o humano alterar `real-cleanup-decision.json`.",
    "- Rerode este contrato para materializar o estado de reentrada.",
    "- Siga para preflight futuro somente se `preflight_allowed=true`.",
    "- Trate qualquer `pending`, `deferred`, `rejected` ou `invalid` como sem executor.",
    "",
    "## Nao fazer",
    "",
    "- Nao transformar este contrato em executor.",
    "- Nao inferir aprovacao a partir de `approved_ready` sem preflight futuro.",
    "- Nao rodar `--execute` neste corte.",
    "- Nao remover worktrees, locks ou branches.",
    "- Nao fazer push ou configurar remoto.",
    "",
    "## Proximo corte",
    "",
    "TKT-039 deve definir um preflight supervisionado pos-aprovacao que so rode quando este contrato declarar `preflight_allowed=true`.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Human Decision Reentry Contract: {overall}")
    print(
        "summary: "
        f"approved_ready={state_counts['approved_ready']} "
        f"pending={state_counts['pending']} "
        f"preflight_allowed={str(preflight_allowed).lower()} "
        f"cleanup_execution_allowed={str(cleanup_execution_allowed).lower()}"
    )

if blockers:
    sys.exit(1)
PY
