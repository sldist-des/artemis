#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-approved-write-fixture/run-01"
approval_package="artifacts/artemis-portal-project-registry-registration-approval-package/run-01/project-registry-registration-approval-package.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh [--artifact-root path] [--approval-package path] [--json]

Builds a controlled approved write fixture for the ARTEMIS Project Registry
registration flow. It proves the positive path through Registration Approval
Intake without writing the registry, registering candidates, switching projects,
authenticating providers, creating worktrees, starting runtime, executing
commands, spending tokens or mutating remote state.
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

python3 - "$artifact_root" "$approval_package" "$format" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
approval_package_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

approval_intake_root = artifact_root / "approval-intake"
fixture_path = artifact_root / "project-registry-registration-approved-write.fixture.json"

missing_files = []
for path in [
    approval_package_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md"),
    Path("docs/exec-packs/done/TKT-108-artemis-project-registry-registration-approved-write-fixture.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

package_payload = json.loads(approval_package_path.read_text(encoding="utf-8")) if approval_package_path.is_file() else {}
approval_package = package_payload.get("approval_package", {})
candidate_id = package_payload.get("candidate_project_id", approval_package.get("candidate_project_id", ""))
template_path = Path(approval_package.get("decision_template", "")) if approval_package.get("decision_template") else None
template_payload = json.loads(template_path.read_text(encoding="utf-8")) if template_path and template_path.is_file() else {}

fixture = dict(template_payload)
fixture.update({
    "schema_version": 1,
    "candidate_project_id": candidate_id,
    "decision": "approved",
    "decided_by": "artemis-fixture-owner",
    "decided_at": generated_at,
    "approval_scope": "project_registry_registration_write",
    "accepted_write_target": "future_project_registry",
    "accepted_registry_write_draft": approval_package.get("registry_write_draft", template_payload.get("accepted_registry_write_draft", "")),
    "accepted_diff_preview": approval_package.get("diff_preview", template_payload.get("accepted_diff_preview", "")),
    "accepted_rollback_plan": approval_package.get("rollback_plan", template_payload.get("accepted_rollback_plan", "")),
    "accepted_validation_commands": template_payload.get("accepted_validation_commands", []),
    "rationale": "Fixture proves the approved write-gate path without registry write side effects.",
    "fixture_only": True,
    "acknowledged_constraints": [
        "fixture_is_not_real_human_approval",
        "approval_allows_future_write_gate_only",
        "approval_does_not_write_registry",
        "approval_does_not_register_candidate",
        "approval_does_not_switch_project",
        "approval_does_not_start_runtime",
        "approval_does_not_authenticate_provider",
        "approval_does_not_write_remote",
    ],
})
fixture_path.write_text(json.dumps(fixture, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

intake_result = subprocess.run(
    [
        "scripts/artemis-portal-project-registry-registration-approval-intake.sh",
        "--artifact-root",
        str(approval_intake_root),
        "--approval-package",
        str(approval_package_path),
        "--decision",
        str(fixture_path),
        "--json",
    ],
    check=True,
    capture_output=True,
    text=True,
)
intake_payload = json.loads(intake_result.stdout)

fixture_contract = {
    "purpose": "Prove the approved registration write path without granting write authority.",
    "state": "approved_write_fixture",
    "candidate_project_id": candidate_id,
    "approval_package": str(approval_package_path),
    "decision_fixture": str(fixture_path),
    "approval_intake_artifact_root": str(approval_intake_root),
    "approval_state": intake_payload.get("approval_state"),
    "human_decision_recorded": intake_payload.get("human_decision_recorded"),
    "approved_for_registry_write_gate": intake_payload.get("approved_for_registry_write_gate"),
    "write_gate_planning_allowed": intake_payload.get("approved_for_registry_write_gate") is True,
    "synthetic_fixture_only": True,
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
    "rules": [
        "The fixture is synthetic evidence, not a real owner approval.",
        "Approved fixture means a later write gate can be designed and tested.",
        "Approved fixture still does not write registry records.",
        "Project switching, runtime, provider auth, command execution, token spend and remote writes remain blocked.",
    ],
}

checks = [
    {
        "id": "approval_package_ready",
        "status": "passed" if package_payload.get("overall") == "project_registry_registration_approval_package_ready" else "failed",
        "detail": "Fixture consumes the registration approval package.",
    },
    {
        "id": "approved_fixture_written",
        "status": "passed" if fixture_path.is_file() and fixture.get("decision") == "approved" else "failed",
        "detail": "Approved write decision fixture was written.",
    },
    {
        "id": "approval_intake_recorded_fixture",
        "status": "passed" if intake_payload.get("approval_state") == "approved_for_registry_write_gate" and intake_payload.get("approved_for_registry_write_gate") is True else "failed",
        "detail": "Approval Intake classified the fixture as approved for a future write gate.",
    },
    {
        "id": "synthetic_fixture_flagged",
        "status": "passed" if fixture.get("fixture_only") is True and fixture_contract["synthetic_fixture_only"] is True else "failed",
        "detail": "Fixture is explicitly marked as synthetic.",
    },
    {
        "id": "registry_write_still_blocked",
        "status": "passed" if intake_payload.get("registry_write_allowed") is False and fixture_contract["registry_write_allowed"] is False else "failed",
        "detail": "The fixture does not write registry records.",
    },
    {
        "id": "candidate_registration_still_blocked",
        "status": "passed" if intake_payload.get("candidate_registration_allowed") is False and fixture_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "The fixture does not register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if intake_payload.get("project_switching_allowed") is False else "failed",
        "detail": "The fixture does not switch projects.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if intake_payload.get("runtime_execution_allowed") is False else "failed",
        "detail": "The fixture does not allow runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if intake_payload.get("commands_executed") == 0 and intake_payload.get("tokens_spent") == 0 else "failed",
        "detail": "No provider auth, worktree, agent command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_approved_write_fixture_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_approved_write_fixture_ready": overall == "project_registry_registration_approved_write_fixture_ready",
    "candidate_project_id": candidate_id,
    "approval_state": intake_payload.get("approval_state"),
    "human_decision_recorded": intake_payload.get("human_decision_recorded"),
    "approved_for_registry_write_gate": intake_payload.get("approved_for_registry_write_gate"),
    "write_gate_planning_allowed": fixture_contract["write_gate_planning_allowed"],
    "synthetic_fixture_only": True,
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
    "next_cut": "TKT-109 - Project Registry Registration Write Gate",
    "missing_files": missing_files,
    "fixture_contract": fixture_contract,
    "approval_intake": intake_payload,
    "checks": checks,
}

(artifact_root / "project-registry-registration-approved-write-fixture.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Approved Write Fixture",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    f"- Approval state: `{payload['approval_state']}`",
    f"- Human decision recorded: `{str(payload['human_decision_recorded']).lower()}`",
    f"- Approved for registry write gate: `{str(payload['approved_for_registry_write_gate']).lower()}`",
    f"- Write gate planning allowed: `{str(payload['write_gate_planning_allowed']).lower()}`",
    "- Synthetic fixture only: `true`",
    "- Registry write allowed: `false`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Fixture",
    "",
    f"- `{fixture_path}`",
    f"- `{approval_intake_root / 'project-registry-registration-approval-intake.json'}`",
    "",
    "## Rules",
    "",
]
lines.extend(f"- {item}" for item in fixture_contract["rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")
(artifact_root / "PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Approval state: `{payload['approval_state']}`",
        f"- Approved for registry write gate: `{str(payload['approved_for_registry_write_gate']).lower()}`",
        "- Fixture is synthetic and cannot authorize a real registry write.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Approval package checked.",
        "- Approved write fixture written.",
        "- Approval Intake accepted the fixture as approved for a future write gate.",
        "- Fixture-only flag checked.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-108 proves the positive registration write approval path with a synthetic approved fixture.",
        "",
        "A later cut may design the actual write gate. This fixture is not real owner approval and does not write registry records, register candidates, switch projects or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_approved_write_fixture_ready",
            event_type="fixture.registration_approved_write_path",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh",
                "mode": "read_only",
            },
            ticket="TKT-108",
            title="ARTEMIS Project Registry Registration Approved Write Fixture",
            exec_pack="docs/exec-packs/done/TKT-108-artemis-project-registry-registration-approved-write-fixture.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "project_registry_registration_approved_write_fixture_ready" else "blocked",
            payload={
                "project_registry_registration_approved_write_fixture_ready": overall == "project_registry_registration_approved_write_fixture_ready",
                "candidate_project_id": candidate_id,
                "approval_state": payload["approval_state"],
                "human_decision_recorded": payload["human_decision_recorded"],
                "approved_for_registry_write_gate": payload["approved_for_registry_write_gate"],
                "write_gate_planning_allowed": payload["write_gate_planning_allowed"],
                "synthetic_fixture_only": True,
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
            state_from="registration_approval_intake",
            runner={"kind": "none"},
            gate={
                "kind": "none",
                "status": "not_applicable",
                "reason": "Synthetic fixture proves the approved path without granting real write authority.",
            },
            severity="info",
            logs=[
                str(artifact_root / "project-registry-registration-approved-write-fixture.json"),
                str(fixture_path),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration approved write fixture: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"approval_state={payload['approval_state']}")
    print(f"approved_for_registry_write_gate={str(payload['approved_for_registry_write_gate']).lower()}")
    print("synthetic_fixture_only=true")
    print("registry_write_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
