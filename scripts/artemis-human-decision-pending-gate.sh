#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

intake_root="artifacts/artemis-human-decision-intake/run-01"
decision="artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json"
runbook="artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md"
artifact_root="artifacts/artemis-human-decision-pending-gate/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-human-decision-pending-gate.sh [--intake-root path] [--decision path] [--runbook path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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
    --runbook)
      runbook="${2:-}"
      if [ -z "$runbook" ]; then usage; exit 2; fi
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

python3 - "$intake_root" "$decision" "$runbook" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

intake_root = Path(sys.argv[1])
decision_path = Path(sys.argv[2])
runbook_path = Path(sys.argv[3])
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
intake_path = intake_root / "human-decision-intake.json"
require_file(intake_path, "human decision intake JSON", inventory)
require_file(intake_root / "STATUS.md", "human decision intake status", inventory)
require_file(intake_root / "VALIDATION.md", "human decision intake validation", inventory)
require_file(intake_root / "HANDOFF.md", "human decision intake handoff", inventory)
require_file(decision_path, "real cleanup decision file", inventory)
require_file(runbook_path, "assisted human decision runbook", inventory)

intake = read_json(intake_path) if intake_path.is_file() else {}
decision = read_json(decision_path) if decision_path.is_file() else {}

summary = intake.get("summary", {})
results = intake.get("results", [])
reviews = decision.get("reviews", [])

if intake.get("overall") != "human_gate":
    blockers.append("intake is not in human_gate state")
if summary.get("pending", 0) <= 0:
    blockers.append("pending gate requires at least one pending decision")
if summary.get("invalid", 0) != 0:
    blockers.append("pending gate cannot continue with invalid decisions")
if summary.get("executed_commands", 0) != 0:
    blockers.append("pending gate detected executed commands")
if intake.get("cleanup_execution_allowed") is not False:
    blockers.append("intake did not explicitly deny cleanup execution")

review_by_ticket = {item.get("ticket"): item for item in reviews}
pending_items = []
for item in results:
    if item.get("intake_state") != "pending":
        continue
    ticket = item.get("ticket")
    review = review_by_ticket.get(ticket, {})
    record = review.get("decision_record") or {}
    if record.get("decision", "pending") != "pending":
        blockers.append(f"{ticket} intake says pending but decision file is {record.get('decision')}")
    if record.get("approved_commands"):
        blockers.append(f"{ticket} pending decision includes approved_commands")
    pending_items.append({
        "ticket": ticket,
        "title": item.get("title", ""),
        "decision": record.get("decision", "pending"),
        "required_fields_after_human_decision": [
            "decision_record.decision",
            "decision_record.decided_by",
            "decision_record.decided_at",
            "decision_record.reason",
            "decision_record.approved_commands",
        ],
        "valid_decisions": ["approved", "deferred", "rejected"],
        "expected_commands_if_approved": list(item.get("expected_commands") or []),
        "next_action": "human_must_fill_decision_record",
    })

validation_commands = [
    f"scripts/artemis-human-cleanup-approval-contract.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01/approval-contract --json",
    f"scripts/artemis-approved-workspace-cleanup.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01/cleanup-dry-run --json",
    f"scripts/artemis-human-decision-intake.sh --decision {decision_path} --artifact-root artifacts/artemis-human-decision-intake/run-01 --json",
    "scripts/validate-artemis.sh",
]

reentry_steps = [
    f"Open {runbook_path}.",
    f"Edit {decision_path} only as the human decision record.",
    "For approved decisions, copy every expected command exactly and in order.",
    "For partial or uncertain approval, choose deferred with a reason.",
    "Run the validation commands before any executor is considered.",
    "Only after a later intake reports approved_ready should an executor preflight be planned.",
]

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-decision-pending-gate.sh",
    "mode": "read_only",
    "overall": "failed" if blockers else "human_gate",
    "artifact_root": str(artifact_root),
    "intake_root": str(intake_root),
    "decision": str(decision_path),
    "runbook": str(runbook_path),
    "cleanup_execution_allowed": False,
    "summary": {
        "pending": len(pending_items),
        "invalid": summary.get("invalid", 0),
        "executed_commands": summary.get("executed_commands", 0),
        "approved_ready": summary.get("approved_ready", 0),
        "deferred": summary.get("deferred", 0),
        "rejected": summary.get("rejected", 0),
    },
    "pending_items": pending_items,
    "validation_commands_after_fill": validation_commands,
    "reentry_steps": reentry_steps,
    "evidence_inventory": inventory,
    "blockers": blockers,
    "invariants": [
        "Human Gate is not approval.",
        "Agents must not fill real-cleanup-decision.json for the human.",
        "No --execute command is emitted by this gate.",
        "Pending decisions cannot remove worktrees, locks, or branches.",
        "Remote writes remain Human Gate.",
    ],
}

(artifact_root / "human-decision-pending-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "TKT-037 registrou a pausa operacional em Human Gate para decisoes humanas pendentes.",
    "",
    "## Estado do gate",
    "",
    f"- Overall: `{payload['overall']}`.",
    f"- Pending: `{payload['summary']['pending']}`.",
    f"- Invalid: `{payload['summary']['invalid']}`.",
    f"- Approved ready: `{payload['summary']['approved_ready']}`.",
    f"- Executed commands: `{payload['summary']['executed_commands']}`.",
    f"- Cleanup execution allowed: `{str(payload['cleanup_execution_allowed']).lower()}`.",
    "",
    "## Decisoes pendentes",
    "",
]
for item in pending_items:
    status_lines.extend([
        f"### {item['ticket']} - {item['title']}",
        "",
        "- Estado atual: `pending`.",
        "- Acao necessaria: humano preencher `decision_record`.",
        "- Decisoes validas agora: `approved`, `deferred` ou `rejected`.",
        "",
        "Campos obrigatorios:",
    ])
    for field in item["required_fields_after_human_decision"]:
        status_lines.append(f"- `{field}`")
    status_lines.append("")
    status_lines.append("Comandos esperados se aprovado:")
    for command in item["expected_commands_if_approved"]:
        status_lines.append(f"- `{command}`")
    status_lines.append("")

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
    "## Validacoes",
    "",
    f"- Intake: `overall={intake.get('overall')}`, `pending={summary.get('pending')}`, `invalid={summary.get('invalid')}`, `executed_commands={summary.get('executed_commands')}`.",
    f"- Decision file: `{decision_path}`.",
    f"- Runbook: `{runbook_path}`.",
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
    validation_lines.append("Gate falhou pelos blockers abaixo:")
    validation_lines.append("")
    for blocker in blockers:
        validation_lines.append(f"- {blocker}")
else:
    validation_lines.append("Gate registrado como Human Gate sem blockers tecnicos.")

validation_lines.extend([
    "",
    "## Gaps",
    "",
    "- Nenhuma decisao humana real foi preenchida.",
    "- Nenhum cleanup real foi executado.",
    "- Nenhum comando com `--execute` foi emitido.",
])
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-037 esta em `{payload['overall']}` porque `{payload['summary']['pending']}` decisoes humanas continuam pendentes.",
    "",
    "## Reentrada segura",
    "",
]
for step in reentry_steps:
    handoff_lines.append(f"- {step}")

handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao executar cleanup enquanto houver `pending`.",
    "- Nao preencher decisao humana como agente.",
    "- Nao rodar `--execute`.",
    "- Nao remover worktrees, locks ou branches.",
    "- Nao fazer push ou configurar GitHub remoto.",
    "",
    "## Proximo corte",
    "",
    "TKT-038 deve documentar a reentrada apos preenchimento humano ou permanecer bloqueado ate o humano fornecer a decisao real.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Human Decision Pending Gate: {payload['overall']}")
    print(
        "summary: "
        f"pending={payload['summary']['pending']} "
        f"invalid={payload['summary']['invalid']} "
        f"executed_commands={payload['summary']['executed_commands']}"
    )

if blockers:
    sys.exit(1)
PY
