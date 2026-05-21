#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-write-gate/run-01"
approved_write_fixture="artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01/project-registry-registration-approved-write-fixture.json"
approval_file=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-write-gate.sh [--artifact-root path] [--approved-write-fixture path] [--approval path] [--json]

Builds the ARTEMIS Project Registry Registration Write Gate. It consumes the
synthetic approved write fixture as positive-path evidence, emits a real-human
write approval template and keeps registry writes blocked. It does not write
the registry, register candidates, switch projects, authenticate providers,
create worktrees, start runtime, execute commands, spend tokens or mutate
remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --approved-write-fixture)
      approved_write_fixture="${2:-}"
      if [ -z "$approved_write_fixture" ]; then usage; exit 2; fi
      shift 2
      ;;
    --approval)
      approval_file="${2:-}"
      if [ -z "$approval_file" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$approved_write_fixture" "$approval_file" "$format" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
fixture_path = Path(sys.argv[2])
approval_arg = sys.argv[3]
output_format = sys.argv[4]
real_approval_path = Path(approval_arg) if approval_arg else None
generated_at = now_utc()

missing_files = []
for path in [
    fixture_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md"),
    Path("docs/exec-packs/done/TKT-109-artemis-project-registry-registration-write-gate.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

fixture_payload = json.loads(fixture_path.read_text(encoding="utf-8")) if fixture_path.is_file() else {}
fixture_contract = fixture_payload.get("fixture_contract", {})
approval_intake = fixture_payload.get("approval_intake", {})
intake_contract = approval_intake.get("intake_contract", {})
candidate_id = fixture_payload.get("candidate_project_id", "")

approval_template = {
    "schema_version": 1,
    "candidate_project_id": candidate_id,
    "decision": "pending",
    "approved_by": "",
    "approved_at": "",
    "approval_scope": "project_registry_registration_real_write",
    "accepted_write_target": "future_project_registry",
    "accepted_approved_write_fixture": str(fixture_path),
    "accepted_registry_write_draft": intake_contract.get("accepted_registry_write_draft", ""),
    "accepted_diff_preview": intake_contract.get("accepted_diff_preview", ""),
    "accepted_rollback_plan": intake_contract.get("accepted_rollback_plan", ""),
    "accepted_validation_commands": intake_contract.get("accepted_validation_commands", []),
    "rationale": "",
    "decision_options": ["approved", "rejected", "deferred"],
    "acknowledged_constraints": [
        "synthetic_fixture_is_not_real_approval",
        "approval_allows_write_execution_planning_only",
        "approval_does_not_run_write_command",
        "approval_does_not_switch_project",
        "approval_does_not_start_runtime",
        "approval_does_not_authenticate_provider",
        "approval_does_not_write_remote",
        "post_write_review_required_before_project_selection",
    ],
}
(artifact_root / "project-registry-registration-write-approval-template.json").write_text(
    json.dumps(approval_template, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

approval_payload = approval_template
approval_source = str(artifact_root / "project-registry-registration-write-approval-template.json")
if real_approval_path and real_approval_path.is_file():
    approval_payload = json.loads(real_approval_path.read_text(encoding="utf-8"))
    approval_source = str(real_approval_path)

decision = approval_payload.get("decision", "pending")
valid_decisions = {"approved", "rejected", "deferred", "pending"}
decision_valid = decision in valid_decisions
non_pending = decision in {"approved", "rejected", "deferred"}
approved_at = approval_payload.get("approved_at", "")
timestamp_valid = True
if approved_at:
    try:
        datetime.fromisoformat(approved_at.replace("Z", "+00:00"))
    except ValueError:
        timestamp_valid = False
elif non_pending:
    timestamp_valid = False

required_fields = [
    "candidate_project_id",
    "decision",
    "approved_by",
    "approved_at",
    "approval_scope",
    "accepted_write_target",
    "accepted_approved_write_fixture",
    "accepted_registry_write_draft",
    "accepted_diff_preview",
    "accepted_rollback_plan",
    "accepted_validation_commands",
    "rationale",
]
required_fields_present = True
if non_pending:
    required_fields_present = all(bool(approval_payload.get(field)) for field in required_fields)

candidate_matches = bool(candidate_id) and approval_payload.get("candidate_project_id") == candidate_id
fixture_path_matches = approval_payload.get("accepted_approved_write_fixture") == str(fixture_path)
write_draft_matches = approval_payload.get("accepted_registry_write_draft") == intake_contract.get("accepted_registry_write_draft", "")
diff_preview_matches = approval_payload.get("accepted_diff_preview") == intake_contract.get("accepted_diff_preview", "")
rollback_plan_matches = approval_payload.get("accepted_rollback_plan") == intake_contract.get("accepted_rollback_plan", "")
validation_commands_match = approval_payload.get("accepted_validation_commands", []) == intake_contract.get("accepted_validation_commands", [])
scope_valid = approval_payload.get("approval_scope") == "project_registry_registration_real_write"
target_valid = approval_payload.get("accepted_write_target") == "future_project_registry"
fixture_ready = fixture_payload.get("overall") == "project_registry_registration_approved_write_fixture_ready"
fixture_positive_path = fixture_payload.get("approved_for_registry_write_gate") is True
fixture_is_synthetic = fixture_payload.get("synthetic_fixture_only") is True

real_write_approval_recorded = all([
    decision == "approved",
    decision_valid,
    required_fields_present,
    timestamp_valid,
    candidate_matches,
    fixture_path_matches,
    write_draft_matches,
    diff_preview_matches,
    rollback_plan_matches,
    validation_commands_match,
    scope_valid,
    target_valid,
    not bool(approval_payload.get("fixture_only")),
])
rejected = decision == "rejected" and decision_valid and required_fields_present and timestamp_valid and candidate_matches
deferred = decision == "deferred" and decision_valid and required_fields_present and timestamp_valid and candidate_matches

if real_write_approval_recorded:
    write_gate_state = "ready_for_supervised_write_execution_plan"
elif rejected:
    write_gate_state = "rejected"
elif deferred:
    write_gate_state = "deferred"
elif decision == "pending":
    write_gate_state = "waiting_for_real_human_write_approval"
else:
    write_gate_state = "invalid"

blockers = []
if not real_write_approval_recorded:
    blockers.append("real_human_write_approval_missing")
if fixture_is_synthetic:
    blockers.append("synthetic_fixture_cannot_authorize_write")
if not fixture_ready:
    blockers.append("approved_write_fixture_not_ready")
if non_pending and not required_fields_present:
    blockers.append("required_fields_missing")
if non_pending and not timestamp_valid:
    blockers.append("invalid_timestamp")
if non_pending and not candidate_matches:
    blockers.append("candidate_mismatch")
if non_pending and not fixture_path_matches:
    blockers.append("approved_write_fixture_path_mismatch")
if non_pending and not validation_commands_match:
    blockers.append("validation_commands_mismatch")

write_gate_contract = {
    "purpose": "Separate synthetic approved-path evidence from real registry write authority.",
    "state": "registration_write_gate",
    "write_gate_state": write_gate_state,
    "candidate_project_id": candidate_id,
    "approved_write_fixture": str(fixture_path),
    "approval_source": approval_source,
    "fixture_ready": fixture_ready,
    "fixture_positive_path": fixture_positive_path,
    "fixture_is_synthetic": fixture_is_synthetic,
    "real_write_approval_recorded": real_write_approval_recorded,
    "write_execution_planning_allowed": real_write_approval_recorded,
    "blockers": blockers,
    "required_decision_fields": required_fields,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "registry_write_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "gate_rules": [
        "A synthetic fixture proves the path but never authorizes registry writes.",
        "Real registry write authority needs a separate human approval with scope, paths, rollback and validation commands.",
        "This gate can allow a later supervised write execution plan, but does not run it.",
        "Project switching and runtime remain blocked after this gate.",
        "No provider auth, worktree, command execution, token spend or remote mutation happens here.",
    ],
}

checks = [
    {
        "id": "approved_write_fixture_ready",
        "status": "passed" if fixture_ready and fixture_positive_path else "failed",
        "detail": "Write Gate consumes a ready positive-path fixture.",
    },
    {
        "id": "synthetic_fixture_cannot_authorize_write",
        "status": "passed" if fixture_is_synthetic and write_gate_contract["registry_write_allowed"] is False else "failed",
        "detail": "Synthetic fixture is treated as evidence only.",
    },
    {
        "id": "approval_template_written",
        "status": "passed" if (artifact_root / "project-registry-registration-write-approval-template.json").is_file() else "failed",
        "detail": "A fillable real-human write approval template is available.",
    },
    {
        "id": "write_gate_waits_for_real_human_approval",
        "status": "passed" if write_gate_state == "waiting_for_real_human_write_approval" and "real_human_write_approval_missing" in blockers else "failed",
        "detail": "Default Write Gate state waits for real human approval.",
    },
    {
        "id": "registry_write_still_blocked",
        "status": "passed" if write_gate_contract["registry_write_allowed"] is False and write_gate_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "Write Gate does not write registry records or register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if write_gate_contract["project_switching_allowed"] is False else "failed",
        "detail": "Write Gate does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if write_gate_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "Write Gate does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if write_gate_contract["commands_executed"] == 0 and write_gate_contract["tokens_spent"] == 0 and write_gate_contract["remote_state_mutated"] is False else "failed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_write_gate_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_write_gate_ready": overall == "project_registry_registration_write_gate_ready",
    "candidate_project_id": candidate_id,
    "write_gate_state": write_gate_state,
    "real_write_approval_recorded": real_write_approval_recorded,
    "write_execution_planning_allowed": real_write_approval_recorded,
    "synthetic_fixture_only": fixture_is_synthetic,
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
    "next_cut": "TKT-110 - Project Registry Registration Supervised Write Plan",
    "missing_files": missing_files,
    "write_gate_contract": write_gate_contract,
    "approved_write_fixture": fixture_payload,
    "checks": checks,
}

(artifact_root / "project-registry-registration-write-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Write Gate",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    f"- Write gate state: `{write_gate_state}`",
    f"- Real write approval recorded: `{str(real_write_approval_recorded).lower()}`",
    f"- Synthetic fixture only: `{str(fixture_is_synthetic).lower()}`",
    "- Write execution planning allowed: `false`",
    "- Registry write allowed: `false`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Approval Template",
    "",
    f"- `{artifact_root / 'project-registry-registration-write-approval-template.json'}`",
    "",
    "## Blockers",
    "",
]
lines.extend(f"- `{item}`" for item in blockers)
lines.extend(["", "## Gate Rules", ""])
lines.extend(f"- {item}" for item in write_gate_contract["gate_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")
(artifact_root / "PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Write gate state: `{write_gate_state}`",
        "- Real human write approval is still missing.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Approved write fixture checked.",
        "- Synthetic fixture boundary checked.",
        "- Real-human write approval template written.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-109 creates the Project Registry registration write gate.",
        "",
        "The positive path is proven by a synthetic fixture, but real registry writes remain blocked until a later cut receives separate human write approval and prepares a supervised write execution plan.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-write-gate.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_write_gate_ready",
            event_type="human_gate.registration_write_gate",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-write-gate.sh",
                "mode": "read_only",
            },
            ticket="TKT-109",
            title="ARTEMIS Project Registry Registration Write Gate",
            exec_pack="docs/exec-packs/done/TKT-109-artemis-project-registry-registration-write-gate.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_registration_write_gate_ready" else "blocked",
            payload={
                "project_registry_registration_write_gate_ready": overall == "project_registry_registration_write_gate_ready",
                "candidate_project_id": candidate_id,
                "write_gate_state": write_gate_state,
                "real_write_approval_recorded": real_write_approval_recorded,
                "write_execution_planning_allowed": real_write_approval_recorded,
                "synthetic_fixture_only": fixture_is_synthetic,
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
            state_from="approved_write_fixture",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": write_gate_state,
                "reason": "A real human write approval is required before any supervised registry write plan.",
                "options": ["approved", "rejected", "deferred"],
            },
            severity="warning",
            logs=[
                str(artifact_root / "project-registry-registration-write-gate.json"),
                str(artifact_root / "project-registry-registration-write-approval-template.json"),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration write gate: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"write_gate_state={write_gate_state}")
    print(f"real_write_approval_recorded={str(real_write_approval_recorded).lower()}")
    print("write_execution_planning_allowed=false")
    print("registry_write_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
