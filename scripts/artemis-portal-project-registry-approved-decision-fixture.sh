#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01"
human_review_gate="artifacts/artemis-portal-project-registry-human-review-gate/run-01/project-registry-human-review-gate.json"
control_plane="control-plane/index.html"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-approved-decision-fixture.sh [--artifact-root path] [--human-review-gate path] [--control-plane path] [--json]

Builds a controlled approved human decision fixture for the ARTEMIS Project
Registry flow. It proves the positive path through Decision Intake and
Registration Gate without registering projects, switching projects,
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
    --human-review-gate)
      human_review_gate="${2:-}"
      if [ -z "$human_review_gate" ]; then usage; exit 2; fi
      shift 2
      ;;
    --control-plane)
      control_plane="${2:-}"
      if [ -z "$control_plane" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$human_review_gate" "$control_plane" "$format" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
human_review_gate_path = Path(sys.argv[2])
control_plane_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

decision_intake_root = artifact_root / "decision-intake"
registration_gate_root = artifact_root / "registration-gate"
fixture_path = artifact_root / "project-registry-approved-decision.fixture.json"

missing_files = []
for path in [
    human_review_gate_path,
    control_plane_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_DECISION_INTAKE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_GATE.md"),
    Path("docs/exec-packs/done/TKT-099-artemis-project-registry-registration-gate.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

human_review_payload = json.loads(human_review_gate_path.read_text(encoding="utf-8")) if human_review_gate_path.is_file() else {}
review_contract = human_review_payload.get("review_contract", {})
candidate_reviews = review_contract.get("candidate_reviews", [])
candidate = candidate_reviews[0] if candidate_reviews else {}
candidate_id = candidate.get("candidate_project_id", "")

fixture = {
    "schema_version": 1,
    "candidate_project_id": candidate_id,
    "decision": "approved",
    "decided_by": "artemis-fixture-owner",
    "decided_at": generated_at,
    "rationale": "Fixture proves the approved decision path without operational side effects.",
    "constraints_acknowledged": [
        "approval_does_not_register_project",
        "approval_does_not_switch_project",
        "approval_does_not_start_runtime",
        "approval_does_not_authenticate_provider",
        "approval_does_not_write_remote",
    ],
    "fixture_only": True,
}
fixture_path.write_text(json.dumps(fixture, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

decision_result = subprocess.run(
    [
        "scripts/artemis-portal-project-registry-decision-intake.sh",
        "--artifact-root",
        str(decision_intake_root),
        "--human-review-gate",
        str(human_review_gate_path),
        "--control-plane",
        str(control_plane_path),
        "--decision",
        str(fixture_path),
        "--json",
    ],
    check=True,
    capture_output=True,
    text=True,
)
decision_payload = json.loads(decision_result.stdout)
decision_json_path = decision_intake_root / "project-registry-decision-intake.json"

registration_result = subprocess.run(
    [
        "scripts/artemis-portal-project-registry-registration-gate.sh",
        "--artifact-root",
        str(registration_gate_root),
        "--decision-intake",
        str(decision_json_path),
        "--control-plane",
        str(control_plane_path),
        "--json",
    ],
    check=True,
    capture_output=True,
    text=True,
)
registration_payload = json.loads(registration_result.stdout)

fixture_contract = {
    "purpose": "Prove the approved decision path without registering or switching projects.",
    "state": "approved_decision_fixture",
    "candidate_project_id": candidate_id,
    "decision_fixture": str(fixture_path),
    "decision_intake_artifact_root": str(decision_intake_root),
    "registration_gate_artifact_root": str(registration_gate_root),
    "decision_state": decision_payload.get("decision_state"),
    "gate_state": registration_payload.get("gate_state"),
    "registration_plan_allowed": registration_payload.get("gate_state") == "ready_for_registration_plan",
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "rules": [
        "The fixture is synthetic evidence, not a real owner approval.",
        "Approved decision means a later registration plan may be prepared.",
        "Approved decision still does not register the project.",
        "Project switching, runtime, provider auth, command execution, token spend and remote writes remain blocked.",
    ],
}

checks = [
    {
        "id": "candidate_available",
        "status": "passed" if bool(candidate_id) else "failed",
        "detail": "Fixture uses a candidate from the Human Review Gate.",
    },
    {
        "id": "approved_fixture_written",
        "status": "passed" if fixture_path.is_file() and fixture.get("decision") == "approved" else "failed",
        "detail": "Approved decision fixture was written.",
    },
    {
        "id": "decision_intake_recorded_approval",
        "status": "passed" if decision_payload.get("decision_state") == "recorded" and decision_payload.get("approved_for_registration_gate") is True else "failed",
        "detail": "Decision Intake classified the fixture as recorded and approved.",
    },
    {
        "id": "registration_gate_positive_path_ready",
        "status": "passed" if registration_payload.get("gate_state") == "ready_for_registration_plan" else "failed",
        "detail": "Registration Gate reached the positive planning state.",
    },
    {
        "id": "candidate_registration_still_blocked",
        "status": "passed" if registration_payload.get("candidate_registration_allowed") is False else "failed",
        "detail": "The fixture does not register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if registration_payload.get("project_switching_allowed") is False else "failed",
        "detail": "The fixture does not switch projects.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if registration_payload.get("runtime_execution_allowed") is False else "failed",
        "detail": "The fixture does not allow runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if registration_payload.get("commands_executed") == 0 and registration_payload.get("tokens_spent") == 0 else "failed",
        "detail": "No provider auth, worktree, agent command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_approved_decision_fixture_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_approved_decision_fixture_ready": overall == "project_registry_approved_decision_fixture_ready",
    "candidate_project_id": candidate_id,
    "decision_state": decision_payload.get("decision_state"),
    "human_decision_recorded": decision_payload.get("human_decision_recorded"),
    "approved_for_registration_gate": decision_payload.get("approved_for_registration_gate"),
    "gate_state": registration_payload.get("gate_state"),
    "registration_plan_allowed": fixture_contract["registration_plan_allowed"],
    "candidate_registration_allowed": False,
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
    "next_cut": "TKT-101 - Project Registry Registration Plan",
    "missing_files": missing_files,
    "fixture_contract": fixture_contract,
    "decision_intake": decision_payload,
    "registration_gate": registration_payload,
    "checks": checks,
}

(artifact_root / "project-registry-approved-decision-fixture.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Approved Decision Fixture",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    f"- Decision state: `{payload['decision_state']}`",
    f"- Approved for registration gate: `{str(payload['approved_for_registration_gate']).lower()}`",
    f"- Gate state: `{payload['gate_state']}`",
    f"- Registration plan allowed: `{str(payload['registration_plan_allowed']).lower()}`",
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
    f"- `{decision_json_path}`",
    f"- `{registration_gate_root / 'project-registry-registration-gate.json'}`",
    "",
    "## Rules",
    "",
]
lines.extend(f"- {item}" for item in fixture_contract["rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Decision state: `{payload['decision_state']}`",
        f"- Gate state: `{payload['gate_state']}`",
        f"- Registration plan allowed: `{str(payload['registration_plan_allowed']).lower()}`",
        "- Registration, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Human Review Gate candidate checked.",
        "- Approved decision fixture written.",
        "- Decision Intake accepted the approved fixture.",
        "- Registration Gate reached `ready_for_registration_plan`.",
        "- Candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-100 proves the positive project-registry decision path with a synthetic approved fixture.",
        "",
        "The next cut may design a registration plan, but this fixture is not a real owner approval and does not register, switch project or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-approved-decision-fixture.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_approved_decision_fixture_ready",
            event_type="human_gate.fixture_validated",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-approved-decision-fixture.sh",
                "mode": "read_only",
            },
            ticket="TKT-100",
            title="ARTEMIS Project Registry Approved Decision Fixture",
            exec_pack="docs/exec-packs/done/TKT-100-artemis-project-registry-approved-decision-fixture.md",
            artifact_root=str(artifact_root),
            state_to="validation_passed" if overall == "project_registry_approved_decision_fixture_ready" else "blocked",
            payload={
                "project_registry_approved_decision_fixture_ready": overall == "project_registry_approved_decision_fixture_ready",
                "candidate_project_id": candidate_id,
                "decision_state": payload["decision_state"],
                "gate_state": payload["gate_state"],
                "registration_plan_allowed": payload["registration_plan_allowed"],
                "candidate_registration_allowed": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="registration_gate",
            runner={"kind": "none"},
            gate={
                "kind": "validation",
                "status": payload["gate_state"] or "unknown",
                "reason": "Synthetic approved fixture proves the next registration planning state without execution.",
                "options": ["prepare registration plan", "keep pending default state"],
            },
            severity="info" if overall == "project_registry_approved_decision_fixture_ready" else "warning",
            logs=[
                str(artifact_root / "project-registry-approved-decision-fixture.json"),
                str(artifact_root / "PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md"),
                str(fixture_path),
                str(decision_json_path),
                str(registration_gate_root / "project-registry-registration-gate.json"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry approved decision fixture: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"decision_state={payload['decision_state']}")
    print(f"gate_state={payload['gate_state']}")
    print(f"registration_plan_allowed={str(payload['registration_plan_allowed']).lower()}")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
