#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

decision="artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json"
checkpoint_root="artifacts/artemis-human-decision-release-checkpoint/run-01"
artifact_root="artifacts/artemis-human-decision-intake/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-human-decision-intake.sh [--decision path] [--checkpoint-root path] [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --decision)
      decision="${2:-}"
      if [ -z "$decision" ]; then usage; exit 2; fi
      shift 2
      ;;
    --checkpoint-root)
      checkpoint_root="${2:-}"
      if [ -z "$checkpoint_root" ]; then usage; exit 2; fi
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

if [ ! -f "$decision" ]; then
  echo "decision file not found: $decision" >&2
  exit 2
fi

if [ ! -d "$checkpoint_root" ]; then
  echo "checkpoint root not found: $checkpoint_root" >&2
  exit 2
fi

mkdir -p "$artifact_root/approval-contract" "$artifact_root/cleanup-dry-run"

scripts/artemis-human-cleanup-approval-contract.sh \
  --decision "$decision" \
  --artifact-root "$artifact_root/approval-contract" \
  --json >"$artifact_root/approval-contract.json"

scripts/artemis-approved-workspace-cleanup.sh \
  --decision "$decision" \
  --artifact-root "$artifact_root/cleanup-dry-run" \
  --json >"$artifact_root/cleanup-dry-run.json"

python3 - "$decision" "$checkpoint_root" "$artifact_root" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

decision_path = Path(sys.argv[1])
checkpoint_root = Path(sys.argv[2])
artifact_root = Path(sys.argv[3])
output_format = sys.argv[4]

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


decision_payload = read_json(decision_path)
checkpoint = read_json(checkpoint_root / "human-decision-release-checkpoint.json")
contract = read_json(artifact_root / "approval-contract.json")
cleanup = read_json(artifact_root / "cleanup-dry-run.json")

contract_results = {item.get("ticket"): item for item in contract.get("results", [])}
cleanup_results = {item.get("ticket"): item for item in cleanup.get("results", [])}

reviews = decision_payload.get("reviews", [])
if not reviews:
    blockers.append("decision file has no reviews")

if checkpoint.get("overall") != "passed":
    blockers.append("release checkpoint is not passed")

if cleanup.get("mode") != "dry_run":
    blockers.append("cleanup check did not run in dry_run mode")

cleanup_summary = cleanup.get("summary", {})
if cleanup_summary.get("executed_commands", 0) != 0:
    blockers.append("cleanup dry-run reports executed commands")

intake_results = []
for review in reviews:
    ticket = review.get("ticket")
    record = review.get("decision_record") or {}
    contract_item = contract_results.get(ticket, {})
    cleanup_item = cleanup_results.get(ticket, {})
    contract_state = contract_item.get("contract_state", "invalid")
    cleanup_status = cleanup_item.get("status", "unknown")
    item_blockers = list(contract_item.get("blockers") or [])
    item_warnings = list(contract_item.get("warnings") or [])

    if contract_state == "approved_ready" and cleanup_status == "ready_to_execute":
        intake_state = "approved_ready"
        next_action = "eligible_for_supervised_cleanup_executor"
    elif contract_state == "deferred":
        intake_state = "deferred"
        next_action = "keep_workspace_and_revisit_later"
    elif contract_state == "rejected":
        intake_state = "rejected"
        next_action = "keep_workspace_and_record_cleanup_refusal"
    elif contract_state == "pending":
        intake_state = "pending"
        next_action = "human_decision_required"
    else:
        intake_state = "invalid"
        next_action = "fix_decision_record_before_any_executor"
        if not item_blockers:
            item_blockers.append("contract state is invalid or cleanup dry-run disagrees")

    intake_results.append({
        "ticket": ticket,
        "title": review.get("title", ""),
        "decision": str(record.get("decision") or "pending").strip(),
        "intake_state": intake_state,
        "contract_state": contract_state,
        "cleanup_status": cleanup_status,
        "execution_allowed_by_contract": bool(contract_item.get("execution_allowed")),
        "cleanup_execute_requested": bool(cleanup_item.get("execute_requested")),
        "cleanup_executed": bool(cleanup_item.get("executed")),
        "approved_commands": list(record.get("approved_commands") or []),
        "expected_commands": list(review.get("commands_after_approval") or []),
        "blockers": item_blockers,
        "warnings": item_warnings,
        "next_action": next_action,
    })

summary = {
    "reviewed": len(intake_results),
    "approved_ready": sum(1 for item in intake_results if item["intake_state"] == "approved_ready"),
    "deferred": sum(1 for item in intake_results if item["intake_state"] == "deferred"),
    "rejected": sum(1 for item in intake_results if item["intake_state"] == "rejected"),
    "pending": sum(1 for item in intake_results if item["intake_state"] == "pending"),
    "invalid": sum(1 for item in intake_results if item["intake_state"] == "invalid"),
    "executed_commands": cleanup_summary.get("executed_commands", 0),
}

if blockers or summary["invalid"]:
    overall = "failed"
elif summary["pending"]:
    overall = "human_gate"
elif summary["approved_ready"]:
    overall = "ready_for_supervised_executor"
else:
    overall = "closed_without_cleanup"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-human-decision-intake.sh",
    "mode": "read_only",
    "decision": str(decision_path),
    "checkpoint_root": str(checkpoint_root),
    "artifact_root": str(artifact_root),
    "overall": overall,
    "cleanup_execution_allowed": False,
    "summary": summary,
    "results": intake_results,
    "subchecks": {
        "release_checkpoint": {
            "overall": checkpoint.get("overall"),
            "cleanup_execution_allowed": checkpoint.get("cleanup_execution_allowed"),
        },
        "approval_contract": {
            "overall": contract.get("overall"),
            "summary": contract.get("summary", {}),
            "artifact_root": str(artifact_root / "approval-contract"),
        },
        "cleanup_dry_run": {
            "overall": cleanup.get("overall"),
            "summary": cleanup_summary,
            "artifact_root": str(artifact_root / "cleanup-dry-run"),
        },
    },
    "blockers": blockers,
    "invariants": [
        "Intake is read-only and never runs --execute.",
        "Decision records remain human-owned.",
        "approved_ready means eligible for a later supervised executor, not executed.",
        "pending, deferred, rejected, and invalid states do not execute cleanup.",
        "Remote writes remain Human Gate.",
    ],
}

(artifact_root / "human-decision-intake.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

status_lines = [
    "# STATUS",
    "",
    "## Resultado",
    "",
    "TKT-036 validou a decisao humana de cleanup em intake read-only.",
    "",
    "## Estado do intake",
    "",
    f"- Overall: `{overall}`.",
    f"- Reviewed: `{summary['reviewed']}`.",
    f"- Approved ready: `{summary['approved_ready']}`.",
    f"- Deferred: `{summary['deferred']}`.",
    f"- Rejected: `{summary['rejected']}`.",
    f"- Pending: `{summary['pending']}`.",
    f"- Invalid: `{summary['invalid']}`.",
    f"- Executed commands: `{summary['executed_commands']}`.",
    f"- Cleanup execution allowed by this intake: `{str(payload['cleanup_execution_allowed']).lower()}`.",
    "",
    "## Resultados por workspace",
    "",
]
for item in intake_results:
    status_lines.extend([
        f"### {item['ticket']} - {item['intake_state']}",
        "",
        f"- Decision: `{item['decision']}`.",
        f"- Contract state: `{item['contract_state']}`.",
        f"- Cleanup dry-run status: `{item['cleanup_status']}`.",
        f"- Next action: `{item['next_action']}`.",
        "",
    ])
    if item["blockers"]:
        status_lines.append("Blockers:")
        for blocker in item["blockers"]:
            status_lines.append(f"- {blocker}")
        status_lines.append("")
    if item["warnings"]:
        status_lines.append("Warnings:")
        for warning in item["warnings"]:
            status_lines.append(f"- {warning}")
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
    f"- Release checkpoint: `overall={checkpoint.get('overall')}`.",
    f"- Approval contract: `overall={contract.get('overall')}`, `pending={contract.get('summary', {}).get('pending')}`, `approved_ready={contract.get('summary', {}).get('approved_ready')}`, `invalid={contract.get('summary', {}).get('invalid')}`.",
    f"- Cleanup dry-run: `overall={cleanup.get('overall')}`, `ready_to_execute={cleanup_summary.get('ready_to_execute')}`, `human_gate={cleanup_summary.get('human_gate')}`, `executed_commands={cleanup_summary.get('executed_commands')}`.",
    "",
    "## Resultado local",
    "",
]
if blockers:
    validation_lines.append("Intake falhou pelos blockers abaixo:")
    validation_lines.append("")
    for blocker in blockers:
        validation_lines.append(f"- {blocker}")
elif summary["invalid"]:
    validation_lines.append("Intake encontrou decisoes invalidas. Corrija `real-cleanup-decision.json` antes de qualquer executor.")
elif summary["pending"]:
    validation_lines.append("Intake parou em Human Gate porque ainda ha decisoes pendentes.")
else:
    validation_lines.append("Intake passou sem blockers tecnicos.")

validation_lines.extend([
    "",
    "## Gaps",
    "",
    "- Nenhum cleanup real foi executado.",
    "- Nenhum comando com `--execute` foi emitido.",
    "- Nenhum push, PR ou configuracao remota foi feita.",
])
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "## Estado",
    "",
    f"TKT-036 concluiu o intake read-only com overall `{overall}`.",
    "",
    "## Interpretacao",
    "",
    "- `approved_ready`: pode seguir para um corte futuro de executor supervisionado, ainda com validacao final.",
    "- `pending`: humano ainda precisa preencher a decisao.",
    "- `deferred`: workspace deve permanecer para revisao futura.",
    "- `rejected`: cleanup foi recusado e deve permanecer registrado.",
    "- `invalid`: decisao precisa ser corrigida antes de qualquer proximo passo.",
    "",
    "## Proximo corte",
    "",
]
if summary["approved_ready"] and not summary["invalid"] and not summary["pending"]:
    handoff_lines.append("TKT-037 deve preparar um preflight de executor supervisionado para decisoes `approved_ready`, ainda sem cleanup automatico.")
else:
    handoff_lines.append("TKT-037 deve registrar o Human Gate de decisao pendente e manter o pacote aguardando preenchimento humano.")

handoff_lines.extend([
    "",
    "## Nao fazer",
    "",
    "- Nao rodar `--execute` neste intake.",
    "- Nao remover worktrees, locks ou branches.",
    "- Nao preencher decisao humana em nome do humano.",
    "- Nao fazer push ou configurar GitHub remoto.",
])
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Human Decision Intake: {overall}")
    print(
        "summary: "
        f"reviewed={summary['reviewed']} "
        f"approved_ready={summary['approved_ready']} "
        f"deferred={summary['deferred']} "
        f"rejected={summary['rejected']} "
        f"pending={summary['pending']} "
        f"invalid={summary['invalid']} "
        f"executed_commands={summary['executed_commands']}"
    )

if blockers or summary["invalid"]:
    sys.exit(1)
PY
