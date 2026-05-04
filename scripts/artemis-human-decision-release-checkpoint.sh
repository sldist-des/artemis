#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

decision_root="artifacts/artemis-real-cleanup-decision-package/run-01"
runbook_root="artifacts/artemis-assisted-human-decision-runbook/run-01"
consistency_root="artifacts/artemis-human-decision-runbook-consistency/run-01"
control_plane_root="artifacts/artemis-control-plane-real-cleanup-human-gate/run-01"
validation_gate_root="artifacts/artemis-validation-gate/run-01"
control_plane_file="control-plane/index.html"
artifact_root="artifacts/artemis-human-decision-release-checkpoint/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-human-decision-release-checkpoint.sh [--decision-root path] [--runbook-root path] [--consistency-root path] [--control-plane-root path] [--validation-gate-root path] [--control-plane-file path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --decision-root)
      decision_root="${2:-}"
      if [ -z "$decision_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --runbook-root)
      runbook_root="${2:-}"
      if [ -z "$runbook_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --consistency-root)
      consistency_root="${2:-}"
      if [ -z "$consistency_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --control-plane-root)
      control_plane_root="${2:-}"
      if [ -z "$control_plane_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --validation-gate-root)
      validation_gate_root="${2:-}"
      if [ -z "$validation_gate_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --control-plane-file)
      control_plane_file="${2:-}"
      if [ -z "$control_plane_file" ]; then usage; exit 2; fi
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

python3 - "$decision_root" "$runbook_root" "$consistency_root" "$control_plane_root" "$validation_gate_root" "$control_plane_file" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

decision_root = Path(sys.argv[1])
runbook_root = Path(sys.argv[2])
consistency_root = Path(sys.argv[3])
control_plane_root = Path(sys.argv[4])
validation_gate_root = Path(sys.argv[5])
control_plane_file = Path(sys.argv[6])
artifact_root = Path(sys.argv[7])
output_format = sys.argv[8]

generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
blockers = []
warnings = []


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        blockers.append(f"missing required JSON: {path}")
    except json.JSONDecodeError as exc:
        blockers.append(f"invalid JSON at {path}: {exc}")
    return {}


def require_file(path, label, inventory):
    exists = path.is_file()
    inventory.append({"label": label, "path": str(path), "exists": exists})
    if not exists:
        blockers.append(f"missing {label}: {path}")
    return exists


inventory = []

decision_path = decision_root / "real-cleanup-decision.json"
decision_package_path = decision_root / "real-cleanup-decision-package.json"
require_file(decision_path, "real cleanup decision file", inventory)
require_file(decision_root / "REAL_CLEANUP_DECISION_PACKAGE.md", "real cleanup decision package guide", inventory)
require_file(decision_root / "REAL_CLEANUP_DECISION_TEMPLATE.md", "real cleanup decision template", inventory)
require_file(decision_root / "REAL_CLEANUP_DECISION_CHECKLIST.md", "real cleanup decision checklist", inventory)
require_file(decision_root / "VALIDATION.md", "real cleanup decision validation", inventory)

require_file(runbook_root / "RUNBOOK.md", "assisted human decision runbook", inventory)
require_file(runbook_root / "DECISION_CRITERIA.md", "assisted human decision criteria", inventory)
require_file(runbook_root / "HUMAN_DECISION_EXAMPLES.md", "assisted human decision examples", inventory)
require_file(runbook_root / "VALIDATION.md", "assisted human decision validation", inventory)

consistency_json_path = consistency_root / "runbook-consistency.json"
require_file(consistency_json_path, "runbook consistency JSON", inventory)
require_file(consistency_root / "RUNBOOK_CONSISTENCY.md", "runbook consistency report", inventory)
require_file(consistency_root / "VALIDATION.md", "runbook consistency validation", inventory)

require_file(control_plane_root / "STATUS.md", "Control Plane Human Gate status", inventory)
require_file(control_plane_root / "VALIDATION.md", "Control Plane Human Gate validation", inventory)
require_file(control_plane_root / "HANDOFF.md", "Control Plane Human Gate handoff", inventory)
require_file(control_plane_file, "Control Plane UI file", inventory)

validation_json_path = validation_gate_root / "validation-gate.json"
require_file(validation_json_path, "Validation Gate JSON", inventory)
require_file(validation_gate_root / "VALIDATION_GATE.md", "Validation Gate report", inventory)
require_file(validation_gate_root / "VALIDATION.md", "Validation Gate validation summary", inventory)

decision = read_json(decision_path) if decision_path.is_file() else {}
decision_package = read_json(decision_package_path) if decision_package_path.is_file() else {}
consistency = read_json(consistency_json_path) if consistency_json_path.is_file() else {}
validation = read_json(validation_json_path) if validation_json_path.is_file() else {}

decisions = decision.get("decisions") or decision.get("reviews", [])
pending_decisions = [item for item in decisions if item.get("decision_record", {}).get("decision") == "pending"]
approved_decisions = [item for item in decisions if item.get("decision_record", {}).get("decision") == "approved"]
approved_commands = [
    command
    for item in decisions
    for command in item.get("decision_record", {}).get("approved_commands", [])
    if command
]

if len(decisions) != 3:
    blockers.append(f"expected 3 real cleanup decisions, found {len(decisions)}")
if len(pending_decisions) != len(decisions):
    blockers.append("real cleanup decision package is no longer fully pending")
if approved_decisions:
    blockers.append("real cleanup decision package contains approved decisions")
if approved_commands:
    blockers.append("real cleanup decision package contains approved commands")
decision_package_summary = decision_package.get("summary", {})
execute_allowed = decision_package.get("execute_allowed", decision_package_summary.get("execute_allowed", 0))
if execute_allowed != 0:
    blockers.append("real cleanup decision package reports execute_allowed different from 0")

consistency_summary = consistency.get("summary", {})
commands_checked = consistency.get("commands_checked", consistency_summary.get("commands_checked"))
evidence_checked = consistency.get("evidence_checked", consistency_summary.get("evidence_checked"))
consistency_blockers = consistency.get("blockers", consistency_summary.get("blockers", []))

if consistency.get("overall") != "passed":
    blockers.append("runbook consistency is not passed")
if commands_checked != 9:
    blockers.append(f"runbook consistency expected 9 commands, found {commands_checked}")
if evidence_checked != 18:
    blockers.append(f"runbook consistency expected 18 evidence entries, found {evidence_checked}")
if consistency_blockers not in (0, []):
    blockers.append("runbook consistency reports blockers")

validation_summary = validation.get("summary", {})
if validation_summary.get("failed") != 0:
    blockers.append("Validation Gate has technical failures")
if validation_summary.get("human_gate", 0) < 1:
    blockers.append("Validation Gate no longer reports Human Gate checks")

if control_plane_file.is_file():
    control_plane_text = control_plane_file.read_text(encoding="utf-8")
    for marker in ["realCleanupGate", "decisionFile", "pending", "executeAllowed"]:
        if marker not in control_plane_text:
            blockers.append(f"Control Plane UI is missing marker: {marker}")

residual_risks = [
    {
        "risk": "real_cleanup_requires_human_decision",
        "severity": "medium",
        "status": "open",
        "mitigation": "Keep real-cleanup-decision.json pending until a human fills identity, timestamp, rationale, and exact commands.",
    },
    {
        "risk": "remote_writes_remain_blocked",
        "severity": "medium",
        "status": "open",
        "mitigation": "Authenticate gh and configure CODEOWNERS before push, PR, branch protection, or remote automation.",
    },
    {
        "risk": "workspace_cleanup_not_executed",
        "severity": "low",
        "status": "accepted",
        "mitigation": "Preserve worktrees until a later supervised intake validates a human-filled decision.",
    },
]

next_cuts = [
    {
        "ticket": "TKT-036",
        "title": "Intake supervisionado da decisao humana preenchida",
        "reason": "Before any cleanup executor, the project needs a read-only intake that validates a human-filled decision package and stages evidence for review.",
    }
]

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-decision-release-checkpoint.sh",
    "overall": "failed" if blockers else "passed",
    "artifact_root": str(artifact_root),
    "release_scope": "local_read_only_checkpoint",
    "cleanup_execution_allowed": False,
    "release_ready_for_supervised_human_decision": not blockers,
    "human_gate": {
        "real_cleanup_decisions": len(decisions),
        "pending": len(pending_decisions),
        "approved": len(approved_decisions),
        "approved_commands": len(approved_commands),
        "execute_allowed": execute_allowed,
    },
    "consistency": {
        "overall": consistency.get("overall"),
        "commands_checked": commands_checked,
        "evidence_checked": evidence_checked,
        "blockers": consistency_blockers,
    },
    "validation_gate": {
        "overall": validation.get("overall"),
        "passed": validation_summary.get("passed"),
        "failed": validation_summary.get("failed"),
        "human_gate": validation_summary.get("human_gate"),
    },
    "evidence_inventory": inventory,
    "residual_risks": residual_risks,
    "next_cuts": next_cuts,
    "warnings": warnings,
    "blockers": blockers,
}

(artifact_root / "human-decision-release-checkpoint.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "TKT-035 consolidou o pacote de decisao humana de cleanup em um checkpoint local read-only.",
    "",
    "## Estado do checkpoint",
    "",
    f"- Overall: `{payload['overall']}`.",
    f"- Release local pronta para uso supervisionado: `{str(payload['release_ready_for_supervised_human_decision']).lower()}`.",
    f"- Cleanup execution allowed: `{str(payload['cleanup_execution_allowed']).lower()}`.",
    f"- Decisoes reais pendentes: `{len(pending_decisions)}` de `{len(decisions)}`.",
    f"- Comandos aprovados: `{len(approved_commands)}`.",
    "",
    "## Evidencias consolidadas",
    "",
]
for item in inventory:
    marker = "ok" if item["exists"] else "missing"
    status_lines.append(f"- `{marker}` {item['label']}: `{item['path']}`")

status_lines.extend([
    "",
    "## Invariantes preservados",
    "",
    "- Checkpoint local nao e autorizacao de cleanup.",
    "- Decisao humana real continua pendente.",
    "- Nenhum comando de cleanup foi executado.",
    "- Remote writes continuam Human Gate.",
])
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# VALIDATION",
    "",
    "## Validacoes consolidadas",
    "",
    f"- Pacote real: `{len(pending_decisions)}` decisoes pendentes, `execute_allowed={execute_allowed}`.",
    f"- Runbook consistency: `overall={consistency.get('overall')}`, `commands_checked={commands_checked}`, `evidence_checked={evidence_checked}`.",
    f"- Validation Gate: `overall={validation.get('overall')}`, `passed={validation_summary.get('passed')}`, `failed={validation_summary.get('failed')}`, `human_gate={validation_summary.get('human_gate')}`.",
    f"- Control Plane: `{control_plane_file}` contem Human Gate visual para cleanup real.",
    "",
    "## Resultado local",
    "",
]
if blockers:
    validation_lines.append("Checkpoint falhou pelos blockers abaixo:")
    validation_lines.append("")
    for blocker in blockers:
        validation_lines.append(f"- {blocker}")
else:
    validation_lines.append("Checkpoint passou sem blockers.")

validation_lines.extend([
    "",
    "## Gaps",
    "",
    "- Nenhuma decisao humana real foi preenchida.",
    "- Nenhum cleanup real foi executado.",
    "- Nenhum push, PR ou configuracao remota foi feita.",
])
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    "TKT-035 esta concluido como checkpoint local read-only do pacote de decisao humana.",
    "",
    "## Usar este pacote para",
    "",
    "- Revisar as evidencias antes de preencher `real-cleanup-decision.json`.",
    "- Confirmar que runbook, consistencia, Control Plane e Validation Gate estao alinhados.",
    "- Decidir, manualmente, se cada workspace deve ser `approved`, `deferred` ou `rejected` em etapa futura.",
    "",
    "## Nao usar este pacote para",
    "",
    "- Autorizar cleanup.",
    "- Rodar `--execute`.",
    "- Remover worktrees, branches ou locks.",
    "- Fazer push ou configurar GitHub remoto.",
    "",
    "## Proximo corte",
    "",
    "TKT-036 deve criar o intake supervisionado da decisao humana preenchida, ainda read-only, antes de qualquer executor de cleanup.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

report_lines = [
    "# HUMAN DECISION RELEASE CHECKPOINT",
    "",
    f"- Overall: `{payload['overall']}`",
    f"- Artifact root: `{artifact_root}`",
    f"- Cleanup execution allowed: `{str(payload['cleanup_execution_allowed']).lower()}`",
    f"- Release ready for supervised human decision: `{str(payload['release_ready_for_supervised_human_decision']).lower()}`",
    "",
    "## Evidence Inventory",
    "",
]
for item in inventory:
    report_lines.append(f"- {'ok' if item['exists'] else 'missing'}: `{item['path']}`")
report_lines.extend([
    "",
    "## Residual Risks",
    "",
])
for risk in residual_risks:
    report_lines.append(f"- `{risk['risk']}` ({risk['severity']}, {risk['status']}): {risk['mitigation']}")
report_lines.extend([
    "",
    "## Next Cuts",
    "",
])
for cut in next_cuts:
    report_lines.append(f"- `{cut['ticket']}` - {cut['title']}: {cut['reason']}")
(artifact_root / "RELEASE_CHECKPOINT.md").write_text("\n".join(report_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Human Decision Release Checkpoint: {payload['overall']}")
    print(f"pending={len(pending_decisions)}")
    print(f"approved_commands={len(approved_commands)}")
    print(f"cleanup_execution_allowed={str(payload['cleanup_execution_allowed']).lower()}")
    print(f"blockers={len(blockers)}")

if blockers:
    sys.exit(1)
PY
