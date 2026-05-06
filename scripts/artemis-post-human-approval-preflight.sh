#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

reentry_root="artifacts/artemis-human-decision-reentry-contract/run-01"
intake_root="artifacts/artemis-human-decision-intake/run-01"
decision="artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json"
artifact_root="artifacts/artemis-post-human-approval-preflight/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-post-human-approval-preflight.sh [--reentry-root path] [--intake-root path] [--decision path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --reentry-root)
      reentry_root="${2:-}"
      if [ -z "$reentry_root" ]; then usage; exit 2; fi
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

python3 - "$reentry_root" "$intake_root" "$decision" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

reentry_root = Path(sys.argv[1])
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
reentry_path = reentry_root / "human-decision-reentry-contract.json"
intake_path = intake_root / "human-decision-intake.json"

require_file(reentry_path, "human decision reentry contract JSON", inventory)
require_file(reentry_root / "STATUS.md", "human decision reentry status", inventory)
require_file(reentry_root / "VALIDATION.md", "human decision reentry validation", inventory)
require_file(reentry_root / "HANDOFF.md", "human decision reentry handoff", inventory)
require_file(intake_path, "human decision intake JSON", inventory)
require_file(decision_path, "real cleanup decision file", inventory)

reentry = read_json(reentry_path) if reentry_path.is_file() else {}
intake = read_json(intake_path) if intake_path.is_file() else {}
decision = read_json(decision_path) if decision_path.is_file() else {}

reentry_summary = reentry.get("summary", {})
intake_summary = intake.get("summary", {})

if reentry.get("mode") != "read_only":
    blockers.append("reentry contract is not read_only")
if intake.get("mode") != "read_only":
    blockers.append("intake is not read_only")
if reentry.get("cleanup_execution_allowed") is not False:
    blockers.append("reentry contract did not explicitly deny cleanup execution")
if intake.get("cleanup_execution_allowed") is not False:
    blockers.append("intake did not explicitly deny cleanup execution")
if reentry_summary.get("executed_commands", 0) != 0:
    blockers.append("reentry contract detected executed commands")
if intake_summary.get("executed_commands", 0) != 0:
    blockers.append("intake detected executed commands")

reviews = decision.get("reviews", [])
if not reviews:
    blockers.append("decision file has no reviews")

state_counts = {
    "approved_ready": reentry_summary.get("approved_ready", 0),
    "pending": reentry_summary.get("pending", 0),
    "deferred": reentry_summary.get("deferred", 0),
    "rejected": reentry_summary.get("rejected", 0),
    "invalid": reentry_summary.get("invalid", 0),
    "executed_commands": reentry_summary.get("executed_commands", 0),
    "reviewed": reentry_summary.get("reviewed", len(reviews)),
}

disallowed_states = [
    state
    for state in ("pending", "deferred", "rejected", "invalid")
    if state_counts[state] > 0
]

reentry_preflight_allowed = reentry.get("preflight_allowed") is True
all_reviewed_are_ready = (
    state_counts["reviewed"] > 0
    and state_counts["approved_ready"] == state_counts["reviewed"]
    and not disallowed_states
)

supervised_preflight_allowed = bool(
    not blockers
    and reentry_preflight_allowed
    and all_reviewed_are_ready
    and state_counts["executed_commands"] == 0
)

cleanup_execution_allowed = False

if blockers:
    overall = "failed"
    next_lane = "fix_preflight_inputs"
elif supervised_preflight_allowed:
    overall = "ready_for_supervised_executor_preflight"
    next_lane = "future_executor_preflight_artifact"
else:
    overall = "human_gate"
    next_lane = "human_must_complete_decision_before_preflight"

preflight_items = []
for item in reentry.get("results", []):
    state = item.get("contract_state") or item.get("intake_state") or "invalid"
    item_ready = supervised_preflight_allowed and state == "approved_ready"
    preflight_items.append({
        "ticket": item.get("ticket"),
        "title": item.get("title", ""),
        "contract_state": state,
        "preflight_status": "ready_for_future_preflight" if item_ready else "not_ready",
        "allows_executor": False,
        "reason": (
            "approved_ready and global preflight gate passed"
            if item_ready
            else f"{state} does not allow preflight in this cut"
        ),
    })

validation_commands = [
    f"scripts/artemis-human-decision-intake.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01 --json",
    f"scripts/artemis-human-decision-reentry-contract.sh --intake-root artifacts/artemis-human-decision-intake/run-01 --decision {decision_path} --artifact-root artifacts/artemis-human-decision-reentry-contract/run-01 --json",
    f"scripts/artemis-post-human-approval-preflight.sh --reentry-root artifacts/artemis-human-decision-reentry-contract/run-01 --intake-root artifacts/artemis-human-decision-intake/run-01 --decision {decision_path} --artifact-root {artifact_root} --json",
    "scripts/validate-artemis.sh",
]

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-post-human-approval-preflight.sh",
    "mode": "read_only",
    "overall": overall,
    "artifact_root": str(artifact_root),
    "reentry_root": str(reentry_root),
    "intake_root": str(intake_root),
    "decision": str(decision_path),
    "reentry_preflight_allowed": reentry_preflight_allowed,
    "supervised_preflight_allowed": supervised_preflight_allowed,
    "cleanup_execution_allowed": cleanup_execution_allowed,
    "summary": {
        **state_counts,
        "disallowed_states": disallowed_states,
        "supervised_preflight_allowed": supervised_preflight_allowed,
        "cleanup_execution_allowed": cleanup_execution_allowed,
    },
    "preflight_items": preflight_items,
    "validation_commands_after_human_fill": validation_commands,
    "evidence_inventory": inventory,
    "blockers": blockers,
    "next_lane": next_lane,
    "invariants": [
        "Post-human approval preflight is read-only and is not an executor.",
        "supervised_preflight_allowed requires reentry preflight_allowed=true.",
        "Any pending, deferred, rejected, or invalid decision stops this preflight.",
        "No command with --execute is emitted by this preflight.",
        "Cleanup execution is always false in this cut.",
        "Remote writes remain Human Gate.",
    ],
}

(artifact_root / "post-human-approval-preflight.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "TKT-039 definiu o preflight read-only pos-aprovacao humana.",
    "",
    "## Estado do preflight",
    "",
    f"- Overall: `{overall}`.",
    f"- Reviewed: `{state_counts['reviewed']}`.",
    f"- Approved ready: `{state_counts['approved_ready']}`.",
    f"- Pending: `{state_counts['pending']}`.",
    f"- Deferred: `{state_counts['deferred']}`.",
    f"- Rejected: `{state_counts['rejected']}`.",
    f"- Invalid: `{state_counts['invalid']}`.",
    f"- Executed commands: `{state_counts['executed_commands']}`.",
    f"- Reentry preflight allowed: `{str(reentry_preflight_allowed).lower()}`.",
    f"- Supervised preflight allowed: `{str(supervised_preflight_allowed).lower()}`.",
    f"- Cleanup execution allowed: `{str(cleanup_execution_allowed).lower()}`.",
    f"- Next lane: `{next_lane}`.",
    "",
    "## Itens de preflight",
    "",
]
for item in preflight_items:
    status_lines.extend([
        f"### {item['ticket']} - {item['preflight_status']}",
        "",
        f"- Contract state: `{item['contract_state']}`.",
        f"- Allows executor: `{str(item['allows_executor']).lower()}`.",
        f"- Reason: {item['reason']}.",
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
    f"- Reentry contract: `{reentry_path}`.",
    f"- Intake: `{intake_path}`.",
    f"- Decision file: `{decision_path}`.",
    "",
    "## Comandos apos preenchimento humano",
    "",
]
for command in validation_commands:
    validation_lines.append(f"- `{command}`")

validation_lines.extend([
    "",
    "## Resultado local",
    "",
])
if blockers:
    validation_lines.append("Preflight falhou pelos blockers abaixo:")
    validation_lines.append("")
    for blocker in blockers:
        validation_lines.append(f"- {blocker}")
else:
    validation_lines.append(
        f"Preflight registrado como `{overall}` com "
        f"`supervised_preflight_allowed={str(supervised_preflight_allowed).lower()}` "
        f"e `cleanup_execution_allowed={str(cleanup_execution_allowed).lower()}`."
    )

validation_lines.extend([
    "",
    "## Gaps",
    "",
    "- Nenhuma decisao humana real foi preenchida por este script.",
    "- Nenhum executor supervisionado foi executado.",
    "- Nenhum cleanup real foi executado.",
    "- Nenhum comando com `--execute` foi emitido.",
])
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-039 terminou em `{overall}` com `next_lane={next_lane}`.",
    "",
    "## Como reentrar",
    "",
    "- O humano deve preencher `real-cleanup-decision.json`.",
    "- Rerode intake, reentry e este preflight na sequencia.",
    "- Siga para qualquer executor somente se `supervised_preflight_allowed=true` em um corte futuro aprovado.",
    "",
    "## Nao fazer",
    "",
    "- Nao transformar preflight em executor.",
    "- Nao rodar `--execute` neste corte.",
    "- Nao remover worktrees, locks ou branches.",
    "- Nao fazer push ou configurar remoto.",
    "",
    "## Fechamento local",
    "",
    "Com este corte, a trilha local de contratos read-only fica completa ate haver decisao humana real.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Post-Human Approval Preflight: {overall}")
    print(
        "summary: "
        f"approved_ready={state_counts['approved_ready']} "
        f"pending={state_counts['pending']} "
        f"supervised_preflight_allowed={str(supervised_preflight_allowed).lower()} "
        f"cleanup_execution_allowed={str(cleanup_execution_allowed).lower()}"
    )

if blockers:
    sys.exit(1)
PY
