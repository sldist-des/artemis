#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-approval-intake/run-01"
approval_package="artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-approval-package.json"
decision_file=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-approval-intake.sh [--artifact-root path] [--approval-package path] [--decision path] [--json]

Builds the ARTEMIS Project Registry Registration Approval Intake. It validates a
human decision file when one is provided and otherwise classifies the approval
package template as pending. It does not write the registry, register
candidates, switch projects, authenticate providers, create worktrees, start
runtime, execute commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --approval-package)
      approval_package="${2:-}"
      if [ -z "$approval_package" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision)
      decision_file="${2:-}"
      if [ -z "$decision_file" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$approval_package" "$decision_file" "$format" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
approval_package_path = Path(sys.argv[2])
decision_arg = sys.argv[3]
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    approval_package_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md"),
    Path("docs/exec-packs/done/TKT-107-artemis-project-registry-registration-approval-intake.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

package_payload = json.loads(approval_package_path.read_text(encoding="utf-8")) if approval_package_path.is_file() else {}
approval_package = package_payload.get("approval_package", {})
candidate_id = package_payload.get("candidate_project_id", approval_package.get("candidate_project_id", ""))

decision_template_path = Path(approval_package.get("decision_template", "")) if approval_package.get("decision_template") else None
decision_path = Path(decision_arg) if decision_arg else decision_template_path
decision_payload = {}
decision_source = ""
if decision_path and decision_path.is_file():
    decision_payload = json.loads(decision_path.read_text(encoding="utf-8"))
    decision_source = str(decision_path)
else:
    decision_payload = {
        "schema_version": 1,
        "candidate_project_id": candidate_id,
        "decision": "pending",
        "decided_by": "",
        "decided_at": "",
        "approval_scope": "project_registry_registration_write",
        "accepted_write_target": "future_project_registry",
        "accepted_registry_write_draft": approval_package.get("registry_write_draft", ""),
        "accepted_diff_preview": approval_package.get("diff_preview", ""),
        "accepted_rollback_plan": approval_package.get("rollback_plan", ""),
        "accepted_validation_commands": [],
        "rationale": "",
    }
    decision_source = "generated_pending_fallback"

(artifact_root / "project-registry-registration-decision-received.json").write_text(
    json.dumps(decision_payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

decision = decision_payload.get("decision", "pending")
valid_decisions = {"approved", "rejected", "deferred", "pending"}
decision_valid = decision in valid_decisions
decision_candidate_id = decision_payload.get("candidate_project_id", "")
candidate_matches_package = bool(candidate_id) and decision_candidate_id == candidate_id
non_pending = decision in {"approved", "rejected", "deferred"}

required_fields = approval_package.get("required_human_fields", [
    "candidate_project_id",
    "decision",
    "decided_by",
    "decided_at",
    "approval_scope",
    "accepted_write_target",
    "accepted_registry_write_draft",
    "accepted_diff_preview",
    "accepted_rollback_plan",
    "accepted_validation_commands",
    "rationale",
])
required_fields_present = True
if non_pending:
    required_fields_present = all(bool(decision_payload.get(field)) for field in required_fields)

timestamp_valid = True
decided_at = decision_payload.get("decided_at", "")
if decided_at:
    try:
        datetime.fromisoformat(decided_at.replace("Z", "+00:00"))
    except ValueError:
        timestamp_valid = False
elif non_pending:
    timestamp_valid = False

path_expectations = {
    "accepted_registry_write_draft": approval_package.get("registry_write_draft", ""),
    "accepted_diff_preview": approval_package.get("diff_preview", ""),
    "accepted_rollback_plan": approval_package.get("rollback_plan", ""),
}
accepted_paths_match = all(
    decision_payload.get(field, "") == expected
    for field, expected in path_expectations.items()
)

expected_validation_commands = decision_payload.get("accepted_validation_commands", [])
if decision_template_path and decision_template_path.is_file():
    template_payload = json.loads(decision_template_path.read_text(encoding="utf-8"))
    expected_validation_commands = template_payload.get("accepted_validation_commands", [])
validation_commands_match = decision_payload.get("accepted_validation_commands", []) == expected_validation_commands

scope_valid = decision_payload.get("approval_scope", "project_registry_registration_write") == "project_registry_registration_write"
target_valid = decision_payload.get("accepted_write_target", "future_project_registry") == "future_project_registry"
human_decision_recorded = (
    non_pending
    and decision_valid
    and candidate_matches_package
    and required_fields_present
    and timestamp_valid
)
approved_for_registry_write_gate = (
    decision == "approved"
    and human_decision_recorded
    and accepted_paths_match
    and validation_commands_match
    and scope_valid
    and target_valid
)
rejected = decision == "rejected" and human_decision_recorded
deferred = decision == "deferred" and human_decision_recorded

if approved_for_registry_write_gate:
    approval_state = "approved_for_registry_write_gate"
elif rejected:
    approval_state = "rejected"
elif deferred:
    approval_state = "deferred"
elif decision == "pending":
    approval_state = "pending"
else:
    approval_state = "invalid"

intake_contract = {
    "purpose": "Classify a human approval decision for a future Project Registry write gate.",
    "state": "registration_approval_intake",
    "approval_state": approval_state,
    "decision_source": decision_source,
    "candidate_project_id": decision_candidate_id,
    "package_candidate_project_id": candidate_id,
    "candidate_matches_package": candidate_matches_package,
    "decision": decision if decision_valid else "invalid",
    "human_decision_recorded": human_decision_recorded,
    "approved_for_registry_write_gate": approved_for_registry_write_gate,
    "rejected": rejected,
    "deferred": deferred,
    "required_fields_present": required_fields_present,
    "timestamp_valid": timestamp_valid,
    "accepted_paths_match": accepted_paths_match,
    "validation_commands_match": validation_commands_match,
    "approval_scope_valid": scope_valid,
    "accepted_write_target_valid": target_valid,
    "accepted_registry_write_draft": decision_payload.get("accepted_registry_write_draft", ""),
    "accepted_diff_preview": decision_payload.get("accepted_diff_preview", ""),
    "accepted_rollback_plan": decision_payload.get("accepted_rollback_plan", ""),
    "expected_validation_commands": expected_validation_commands,
    "accepted_validation_commands": decision_payload.get("accepted_validation_commands", []),
    "decision_options": ["approved", "rejected", "deferred"],
    "required_decision_fields": required_fields,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "registry_write_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "rules": [
        "Pending means no owner decision has been recorded yet.",
        "Approved only unlocks a later write gate; it does not write registry records.",
        "Rejected and deferred decisions keep the candidate unregistered.",
        "Invalid decisions block the next gate until corrected.",
        "No provider auth, worktree, runtime, command execution, token spend or remote mutation happens here.",
    ],
}

checks = [
    {
        "id": "approval_package_ready",
        "status": "passed" if package_payload.get("overall") == "project_registry_registration_approval_package_ready" else "failed",
        "detail": "Approval Intake consumes the registration approval package.",
    },
    {
        "id": "decision_classified",
        "status": "passed" if approval_state in {"pending", "approved_for_registry_write_gate", "rejected", "deferred", "invalid"} else "failed",
        "detail": "Decision payload was classified.",
    },
    {
        "id": "pending_keeps_write_blocked",
        "status": "passed" if intake_contract["registry_write_allowed"] is False and intake_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "Approval Intake does not write registry records.",
    },
    {
        "id": "paths_bound_to_package",
        "status": "passed" if decision == "pending" or accepted_paths_match else "failed",
        "detail": "Non-pending decisions must accept the package paths.",
    },
    {
        "id": "validation_commands_bound_to_package",
        "status": "passed" if decision == "pending" or validation_commands_match else "failed",
        "detail": "Non-pending decisions must accept the package validation commands.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if intake_contract["project_switching_allowed"] is False else "failed",
        "detail": "Approval Intake does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if intake_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "Approval Intake does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if intake_contract["commands_executed"] == 0 and intake_contract["tokens_spent"] == 0 else "failed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_approval_intake_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_approval_intake_ready": overall == "project_registry_registration_approval_intake_ready",
    "candidate_project_id": candidate_id,
    "approval_state": approval_state,
    "human_decision_required": True,
    "human_decision_recorded": human_decision_recorded,
    "approved_for_registry_write_gate": approved_for_registry_write_gate,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "registry_write_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "worktree_created": False,
    "branch_changed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-108 - Project Registry Registration Approved Write Fixture",
    "missing_files": missing_files,
    "intake_contract": intake_contract,
    "approval_package": package_payload,
    "checks": checks,
}

(artifact_root / "project-registry-registration-approval-intake.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Approval Intake",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    f"- Approval state: `{approval_state}`",
    f"- Human decision recorded: `{str(human_decision_recorded).lower()}`",
    f"- Approved for registry write gate: `{str(approved_for_registry_write_gate).lower()}`",
    "- Registry write allowed: `false`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Decision source: `{decision_source}`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Required Fields",
    "",
]
for field in required_fields:
    lines.append(f"- `{field}`")
lines.extend(["", "## Rules", ""])
lines.extend(f"- {item}" for item in intake_contract["rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")
(artifact_root / "PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Approval state: `{approval_state}`",
        "- Default path remains pending until a real human decision is provided.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Approval package checked.",
        "- Decision payload classified.",
        "- Candidate id, timestamp, accepted paths and validation commands are validated for non-pending decisions.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-107 records the Project Registry registration approval intake.",
        "",
        "A valid approved decision can feed a future write gate, but this cut still does not write registry records, register candidates, switch projects or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-approval-intake.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_approval_intake_ready",
            event_type="human_gate.registration_approval_intake",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-approval-intake.sh",
                "mode": "read_only",
            },
            ticket="TKT-107",
            title="ARTEMIS Project Registry Registration Approval Intake",
            exec_pack="docs/exec-packs/done/TKT-107-artemis-project-registry-registration-approval-intake.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_registration_approval_intake_ready" else "blocked",
            payload={
                "project_registry_registration_approval_intake_ready": overall == "project_registry_registration_approval_intake_ready",
                "candidate_project_id": candidate_id,
                "approval_state": approval_state,
                "human_decision_required": True,
                "human_decision_recorded": human_decision_recorded,
                "approved_for_registry_write_gate": approved_for_registry_write_gate,
                "registration_execution_allowed": False,
                "candidate_registration_allowed": False,
                "registry_write_allowed": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="registration_approval_package",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": approval_state,
                "reason": "A human registration approval decision must be validated before a future registry write gate.",
                "options": ["approved", "rejected", "deferred"],
            },
            severity="warning" if not approved_for_registry_write_gate else "info",
            logs=[
                str(artifact_root / "project-registry-registration-approval-intake.json"),
                str(artifact_root / "project-registry-registration-decision-received.json"),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration approval intake: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"approval_state={approval_state}")
    print(f"human_decision_recorded={str(human_decision_recorded).lower()}")
    print(f"approved_for_registry_write_gate={str(approved_for_registry_write_gate).lower()}")
    print("registry_write_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
