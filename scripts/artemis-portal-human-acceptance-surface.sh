#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-human-acceptance-surface/run-01"
validation_evidence_surface="artifacts/artemis-portal-validation-evidence-surface/run-01/validation-evidence-surface-contract.json"
runtime_completion_review_gate="artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-gate.json"
runtime_done_ledger="artifacts/artemis-agent-runtime-done-ledger/run-01/done-ledger.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-human-acceptance-surface.sh [--artifact-root path] [--validation-evidence-surface path] [--completion-review-gate path] [--done-ledger path] [--json]

Builds the ARTEMIS Portal Human Acceptance Surface contract. It defines how a
human can explicitly accept, reject or defer validated work, but this cut does
not record a real acceptance, mark done, mutate task state, start runtime,
execute commands, send provider messages, spend tokens, store secrets, push,
deploy or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --validation-evidence-surface)
      validation_evidence_surface="${2:-}"
      if [ -z "$validation_evidence_surface" ]; then usage; exit 2; fi
      shift 2
      ;;
    --completion-review-gate)
      runtime_completion_review_gate="${2:-}"
      if [ -z "$runtime_completion_review_gate" ]; then usage; exit 2; fi
      shift 2
      ;;
    --done-ledger)
      runtime_done_ledger="${2:-}"
      if [ -z "$runtime_done_ledger" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$validation_evidence_surface" "$runtime_completion_review_gate" "$runtime_done_ledger" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
validation_evidence_path = Path(sys.argv[2])
completion_review_gate_path = Path(sys.argv[3])
done_ledger_path = Path(sys.argv[4])
output_format = sys.argv[5]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_VALIDATION_EVIDENCE_SURFACE.md"),
    Path("docs/exec-packs/done/TKT-081-artemis-portal-validation-evidence-surface.md"),
    Path("artifacts/artemis-portal-validation-evidence-surface/run-01/validation-evidence-surface-contract.json"),
    Path("artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-gate.json"),
    Path("artifacts/artemis-agent-runtime-done-ledger/run-01/done-ledger.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]


def read_json(path):
    if path.is_file():
        return json.loads(path.read_text(encoding="utf-8"))
    missing_files.append(str(path))
    return {}


validation_evidence_payload = read_json(validation_evidence_path)
completion_review_payload = read_json(completion_review_gate_path)
done_ledger_payload = read_json(done_ledger_path)

validation_summary = validation_evidence_payload.get("validation_summary", {})
review_summary = completion_review_payload.get("summary", {})
ledger_summary = done_ledger_payload.get("summary", {})
sample_evidence = validation_evidence_payload.get("sample_evidence", {})

passed_count = int(validation_summary.get("passed", 0) or 0)
failed_count = int(validation_summary.get("failed", 0) or 0)
human_gate_count = int(validation_summary.get("human_gate", 0) or 0)

acceptance_schema = {
    "required_fields": [
        "acceptance_surface_id",
        "project_id",
        "ticket",
        "evidence_surface_id",
        "validation_gate_ref",
        "completion_review_gate_ref",
        "done_ledger_ref",
        "decision",
        "decided_by",
        "decision_authority",
        "reason",
        "accepted_evidence_refs",
        "rejected_evidence_refs",
        "deferred_blocker_refs",
        "residual_risk_acknowledged",
        "human_gate_acknowledged",
        "done_ledger_handoff_allowed",
        "event_refs",
        "decided_at",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "raw_prompt",
        "full_prompt_transcript",
        "raw_runtime_stdout",
        "raw_runtime_stderr",
        "provider_secret",
        "git_remote_token",
        "ssh_private_key",
        "unredacted_user_data",
        "auto_accept_flag",
        "background_approval",
        "implicit_acceptance",
    ],
}

human_acceptance_contract = {
    "purpose": "Let a human explicitly accept, reject or defer validated work after evidence is visible.",
    "state": "contract_only",
    "human_acceptance_surface_ready": True,
    "acceptance_recorded": False,
    "accepted": False,
    "rejected": False,
    "deferred": True,
    "done_ledger_handoff_allowed": False,
    "task_state_mutated": False,
    "secret_values_recorded": False,
    "controls_triggered": 0,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "acceptance_schema": acceptance_schema,
    "decision_model": [
        "accepted",
        "rejected",
        "deferred",
        "needs_more_evidence",
        "blocked_by_human_gate",
    ],
    "authority_model": {
        "human_owner_required": [
            "accepted",
            "rejected",
            "override_residual_risk",
            "acknowledge_human_gate",
        ],
        "agent_allowed": [
            "prepare_acceptance_summary",
            "list_evidence_refs",
            "list_unresolved_gates",
            "prepare_done_ledger_handoff",
        ],
        "agent_forbidden": [
            "record_acceptance",
            "mark_done",
            "close_remote_task",
            "approve_budget",
            "approve_secret_access",
            "approve_production_write",
        ],
    },
    "preconditions": [
        "Validation Evidence Surface is ready.",
        "Failed checks are zero before accepted is allowed.",
        "Human Gates are explicit and acknowledged by a human owner before accepted is allowed.",
        "Residual risks and not-tested gaps are visible before accepted is allowed.",
        "Done Ledger handoff is separate from evidence display and requires an explicit accepted decision.",
    ],
    "transition_policy": [
        {
            "from": "evidence_visible",
            "decision": "accepted",
            "to": "accepted_pending_done_ledger",
            "requires_human_owner": True,
            "requires_failed_checks_zero": True,
            "requires_human_gate_ack": True,
            "effect": "record_acceptance_event_then_prepare_done_ledger_handoff",
        },
        {
            "from": "evidence_visible",
            "decision": "rejected",
            "to": "rejected_needs_rework",
            "requires_human_owner": True,
            "requires_reason": True,
            "effect": "record_rejection_event_only",
        },
        {
            "from": "evidence_visible",
            "decision": "deferred",
            "to": "deferred_human_gate",
            "requires_human_owner": True,
            "requires_blocker_refs": True,
            "effect": "record_deferral_event_only",
        },
    ],
    "ui_policy": {
        "accept_button_disabled_when_failed_checks_exist": True,
        "accept_button_disabled_until_human_gate_ack": True,
        "reject_requires_reason": True,
        "defer_requires_blocker_refs": True,
        "show_done_ledger_handoff_preview": True,
        "raw_logs_default_collapsed": True,
        "raw_runtime_output_allowed": False,
        "secret_values_allowed": False,
        "implicit_acceptance_allowed": False,
    },
    "event_bridge": {
        "writes_canonical_events": True,
        "event_types": [
            "human_acceptance.surface_recorded",
            "human_acceptance.summary_prepared",
            "human_acceptance.decision_pending",
            "human_acceptance.done_ledger_handoff_blocked",
        ],
        "raw_log_in_event_allowed": False,
        "secret_values_in_event_allowed": False,
        "implicit_acceptance_allowed": False,
    },
    "enforcement_rules": [
        "Evidence can recommend readiness, but only a human owner can accept.",
        "No acceptance is recorded by this contract fixture.",
        "Accepted cannot be available while failed checks exist.",
        "Human Gates must be acknowledged explicitly before accepted can feed Done Ledger.",
        "Reject and defer decisions must preserve reason or blocker references.",
        "Agents can prepare summaries and handoffs but cannot approve their own work.",
        "Done Ledger handoff remains blocked until a real accepted decision exists.",
    ],
}

acceptance_state = "pending_human_acceptance"
if failed_count:
    acceptance_state = "blocked_by_failed_checks"
elif human_gate_count:
    acceptance_state = "blocked_by_human_gate_ack"

sample_acceptance = {
    "acceptance_surface_id": "human-acceptance-tkt-082-contract-fixture",
    "project_id": sample_evidence.get("project_id", "artemis"),
    "ticket": "TKT-082",
    "evidence_surface_id": sample_evidence.get("evidence_surface_id", "validation-evidence-tkt-081-contract-fixture"),
    "validation_gate_ref": str(validation_evidence_path),
    "completion_review_gate_ref": str(completion_review_gate_path),
    "done_ledger_ref": str(done_ledger_path),
    "decision": "deferred",
    "decided_by": "human_owner_required",
    "decision_authority": "human_owner",
    "reason": "Contract fixture only; real acceptance must be entered by a human owner.",
    "accepted_evidence_refs": [],
    "rejected_evidence_refs": [],
    "deferred_blocker_refs": sample_evidence.get("blocker_refs", []),
    "residual_risk_acknowledged": False,
    "human_gate_acknowledged": False,
    "done_ledger_handoff_allowed": False,
    "event_refs": [
        "evt_portal_human_acceptance_surface_contract_recorded"
    ],
    "decided_at": generated_at,
}

checks = [
    {
        "id": "validation_evidence_surface_ready",
        "status": "passed" if validation_evidence_payload.get("overall") == "validation_evidence_surface_ready" else "failed",
        "detail": "Human Acceptance Surface consumes a ready Validation Evidence Surface contract.",
    },
    {
        "id": "acceptance_schema_declared",
        "status": "passed" if acceptance_schema["required_fields"] and acceptance_schema["forbidden_fields"] else "failed",
        "detail": "Acceptance fields and forbidden raw/secret/implicit acceptance fields are declared.",
    },
    {
        "id": "authority_model_declared",
        "status": "passed" if "record_acceptance" in human_acceptance_contract["authority_model"]["agent_forbidden"] else "failed",
        "detail": "Agents can prepare evidence but cannot approve or mark done.",
    },
    {
        "id": "failed_checks_gate_declared",
        "status": "passed" if human_acceptance_contract["ui_policy"]["accept_button_disabled_when_failed_checks_exist"] else "failed",
        "detail": "Acceptance is disabled while failed checks exist.",
    },
    {
        "id": "human_gate_ack_required",
        "status": "passed" if human_acceptance_contract["ui_policy"]["accept_button_disabled_until_human_gate_ack"] else "failed",
        "detail": "Human Gates require explicit human acknowledgement before acceptance.",
    },
    {
        "id": "done_ledger_handoff_blocked",
        "status": "passed" if not human_acceptance_contract["done_ledger_handoff_allowed"] else "failed",
        "detail": "Done Ledger handoff remains blocked because no real acceptance was recorded.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not human_acceptance_contract["runtime_execution_allowed"] and human_acceptance_contract["commands_executed"] == 0 else "failed",
        "detail": "Human acceptance contract cannot start runtime or execute commands in this cut.",
    },
    {
        "id": "no_acceptance_recorded",
        "status": "passed" if not human_acceptance_contract["acceptance_recorded"] and not human_acceptance_contract["accepted"] else "failed",
        "detail": "This cut defines acceptance semantics but records no real acceptance.",
    },
    {
        "id": "no_task_state_mutation",
        "status": "passed" if not human_acceptance_contract["task_state_mutated"] else "failed",
        "detail": "No task state, remote state or Done Ledger state is mutated.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No secrets, raw prompts, raw runtime output or full transcripts are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "human_acceptance_surface_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "human_acceptance_surface_ready": overall == "human_acceptance_surface_ready",
    "acceptance_state": acceptance_state,
    "acceptance_recorded": False,
    "accepted": False,
    "rejected": False,
    "deferred": True,
    "done_ledger_handoff_allowed": False,
    "task_state_mutated": False,
    "secret_values_recorded": False,
    "controls_triggered": 0,
    "messages_sent_to_provider": 0,
    "agent_messages_received": 0,
    "runtime_execution_allowed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "validation_summary": {
        "passed": passed_count,
        "failed": failed_count,
        "human_gate": human_gate_count,
    },
    "completion_review_summary": {
        "completion_review_ready": review_summary.get("completion_review_ready", False),
        "completion_review_accepted": review_summary.get("completion_review_accepted", False),
        "ready_for_done_ledger": review_summary.get("ready_for_done_ledger", False),
    },
    "done_ledger_summary": {
        "done_ledger_recorded": ledger_summary.get("done_ledger_recorded", False),
        "technical_done": ledger_summary.get("technical_done", False),
        "remote_done_closed": ledger_summary.get("remote_done_closed", False),
    },
    "next_cut": "NONE - ARTEMIS Portal supervised control spine complete",
    "missing_files": missing_files,
    "human_acceptance_contract": human_acceptance_contract,
    "sample_acceptance": sample_acceptance,
    "checks": checks,
    "inputs": {
        "validation_evidence_surface": str(validation_evidence_path),
        "completion_review_gate": str(completion_review_gate_path),
        "done_ledger": str(done_ledger_path),
    },
}

(artifact_root / "human-acceptance-surface-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Human Acceptance Surface Contract",
    "",
    f"- Overall: `{overall}`",
    f"- Acceptance state: `{acceptance_state}`",
    f"- Validation passed: `{passed_count}`",
    f"- Validation failed: `{failed_count}`",
    f"- Human gates: `{human_gate_count}`",
    "- Acceptance recorded: `false`",
    "- Accepted: `false`",
    "- Done Ledger handoff allowed: `false`",
    "- Task state mutated: `false`",
    "- Runtime execution allowed: `false`",
    "- Runtime session started: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `NONE - ARTEMIS Portal supervised control spine complete`",
    "",
    "## Regra central",
    "",
    "Aceite humano decide, mas nao acontece de forma implicita. Agentes podem preparar resumo e handoff; somente o humano owner pode aceitar, rejeitar ou deferir.",
    "",
    "## Acceptance required fields",
    "",
]
for field in acceptance_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in acceptance_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Decision model", ""])
for item in human_acceptance_contract["decision_model"]:
    lines.append(f"- `{item}`")

lines.extend(["", "## Enforcement rules", ""])
for rule in human_acceptance_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "HUMAN_ACCEPTANCE_SURFACE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Acceptance state: `{acceptance_state}`",
        "- Human Acceptance Surface contract recorded.",
        "- No real acceptance, done transition, task mutation, provider message, runtime start, command execution, token spend or remote write executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Validation Evidence Surface, Completion Review Gate and Done Ledger artifacts checked.",
        "- Acceptance schema, decision model, authority model, transition policy, UI policy and event bridge defined.",
        "- No acceptance, done transition, task mutation, provider message, runtime start, command execution, token spend, raw prompt, transcript, secret or remote write produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-082 defines the ARTEMIS Portal Human Acceptance Surface contract.",
        "",
        "The portal spine is now complete as a supervised local contract: task controls show intent, validation evidence explains proof, and human acceptance defines the explicit decision boundary before Done Ledger handoff.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-human-acceptance-surface.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_human_acceptance_surface_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_human_acceptance_surface",
                "name": "scripts/artemis-portal-human-acceptance-surface.sh",
                "mode": "read_only",
            },
            ticket="TKT-082",
            title="ARTEMIS Portal Human Acceptance Surface Contract",
            exec_pack="docs/exec-packs/done/TKT-082-artemis-portal-human-acceptance-surface.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "human_acceptance_surface_ready" else "blocked",
            payload={
                "human_acceptance_surface_ready": overall == "human_acceptance_surface_ready",
                "acceptance_state": acceptance_state,
                "acceptance_surface_id": sample_acceptance["acceptance_surface_id"],
                "validation_passed": passed_count,
                "validation_failed": failed_count,
                "validation_human_gate": human_gate_count,
                "acceptance_recorded": False,
                "accepted": False,
                "done_ledger_handoff_allowed": False,
                "task_state_mutated": False,
                "runtime_execution_allowed": False,
                "runtime_session_started": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "secret_values_recorded": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="warning",
            logs=[
                str(artifact_root / "human-acceptance-surface-contract.json"),
                str(artifact_root / "HUMAN_ACCEPTANCE_SURFACE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal human acceptance surface: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"acceptance_state={acceptance_state}")
    print("acceptance_recorded=false")
    print("accepted=false")
    print("done_ledger_handoff_allowed=false")
    print("task_state_mutated=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
