#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-plan/run-01"
approved_decision_fixture="artifacts/artemis-portal-project-registry-approved-decision-fixture/run-01/project-registry-approved-decision-fixture.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-plan.sh [--artifact-root path] [--approved-decision-fixture path] [--json]

Builds the ARTEMIS Project Registry Registration Plan. It consumes the approved
decision fixture and prepares a declarative registration plan. It does not
register projects, switch projects, authenticate providers, create worktrees,
start runtime, execute commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --approved-decision-fixture)
      approved_decision_fixture="${2:-}"
      if [ -z "$approved_decision_fixture" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$approved_decision_fixture" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
fixture_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

missing_files = []
for path in [
    fixture_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_PLAN.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_GATE.md"),
    Path("docs/exec-packs/done/TKT-100-artemis-project-registry-approved-decision-fixture.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

fixture_payload = json.loads(fixture_path.read_text(encoding="utf-8")) if fixture_path.is_file() else {}
candidate_id = fixture_payload.get("candidate_project_id", "")
fixture_contract = fixture_payload.get("fixture_contract", {})
registration_gate = fixture_payload.get("registration_gate", {})
registration_contract = registration_gate.get("registration_contract", {})

plan_preconditions = {
    "approved_decision_fixture_ready": fixture_payload.get("overall") == "project_registry_approved_decision_fixture_ready",
    "decision_recorded": fixture_payload.get("decision_state") == "recorded",
    "approved_for_registration_gate": fixture_payload.get("approved_for_registration_gate") is True,
    "registration_gate_ready_for_plan": fixture_payload.get("gate_state") == "ready_for_registration_plan",
    "candidate_known": bool(candidate_id),
    "candidate_registration_still_blocked": fixture_payload.get("candidate_registration_allowed") is False,
    "project_switching_still_blocked": fixture_payload.get("project_switching_allowed") is False,
    "runtime_still_blocked": fixture_payload.get("runtime_execution_allowed") is False,
}

registration_plan_ready = all(plan_preconditions.values())
plan_state = "ready_for_registration_execution_gate" if registration_plan_ready else "blocked"

planned_records = [
    {
        "record": "registry.project",
        "candidate_project_id": candidate_id,
        "write_allowed_in_this_cut": False,
        "required_gate": "real_human_owner_approval",
    },
    {
        "record": "registry.audit",
        "candidate_project_id": candidate_id,
        "write_allowed_in_this_cut": False,
        "required_gate": "registration_execution_gate",
    },
    {
        "record": "selector.entry",
        "candidate_project_id": candidate_id,
        "write_allowed_in_this_cut": False,
        "required_gate": "post_registration_review",
    },
]

plan_steps = [
    {
        "step": "revalidate_source_fixture",
        "description": "Confirm the approved path is evidence-only and still has no side effects.",
        "execution_allowed": False,
    },
    {
        "step": "prepare_registry_record",
        "description": "Prepare a registry record draft for the candidate project.",
        "execution_allowed": False,
    },
    {
        "step": "prepare_audit_record",
        "description": "Prepare an audit entry linking decision, gate and future registration authority.",
        "execution_allowed": False,
    },
    {
        "step": "open_registration_execution_gate",
        "description": "Require a future gate before any write to registry artifacts.",
        "execution_allowed": False,
    },
]

registration_plan_contract = {
    "purpose": "Turn an approved registration gate state into a bounded plan for a future registration execution gate.",
    "state": "registration_plan",
    "plan_state": plan_state,
    "candidate_project_id": candidate_id,
    "approved_decision_fixture": str(fixture_path),
    "source_registration_gate": fixture_contract.get("registration_gate_artifact_root", ""),
    "registration_plan_ready": registration_plan_ready,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "planned_records": planned_records,
    "plan_steps": plan_steps,
    "execution_gate_requirements": [
        "Real human owner approval, not synthetic fixture.",
        "Explicit registry write target.",
        "Diff preview before write.",
        "Rollback plan before write.",
        "Validation command list before write.",
        "Post-write review gate before project selection.",
    ],
    "registration_rules": [
        "A registration plan is not registration.",
        "Synthetic fixtures can prove flow shape but cannot authorize real writes.",
        "Registration execution requires a later explicit gate.",
        "Project switching and runtime remain blocked after planning.",
        "No provider auth, worktree, command execution, token spend or remote mutation happens here.",
    ],
}

checks = [
    {
        "id": "approved_fixture_ready",
        "status": "passed" if plan_preconditions["approved_decision_fixture_ready"] else "failed",
        "detail": "Registration Plan consumes the approved decision fixture.",
    },
    {
        "id": "registration_gate_ready_for_plan",
        "status": "passed" if plan_preconditions["registration_gate_ready_for_plan"] else "failed",
        "detail": "Source gate is ready for registration planning.",
    },
    {
        "id": "candidate_known",
        "status": "passed" if plan_preconditions["candidate_known"] else "failed",
        "detail": "Plan targets a known candidate project id.",
    },
    {
        "id": "planned_records_are_non_writing",
        "status": "passed" if planned_records and all(item["write_allowed_in_this_cut"] is False for item in planned_records) else "failed",
        "detail": "Planned records are declarative only in this cut.",
    },
    {
        "id": "execution_gate_required",
        "status": "passed" if registration_plan_contract["registration_execution_allowed"] is False and len(registration_plan_contract["execution_gate_requirements"]) >= 3 else "failed",
        "detail": "Execution remains behind a later registration execution gate.",
    },
    {
        "id": "candidate_registration_still_blocked",
        "status": "passed" if registration_plan_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "Plan does not register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if registration_plan_contract["project_switching_allowed"] is False else "failed",
        "detail": "Plan does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if registration_plan_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "Plan does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if registration_plan_contract["commands_executed"] == 0 and registration_plan_contract["tokens_spent"] == 0 else "failed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_plan_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_plan_ready": overall == "project_registry_registration_plan_ready",
    "candidate_project_id": candidate_id,
    "plan_state": plan_state,
    "registration_plan_ready": registration_plan_ready,
    "registration_execution_allowed": False,
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
    "next_cut": "TKT-102 - Project Registry Registration Execution Gate",
    "missing_files": missing_files,
    "plan_preconditions": plan_preconditions,
    "registration_contract_source": registration_contract,
    "registration_plan_contract": registration_plan_contract,
    "checks": checks,
}

(artifact_root / "project-registry-registration-plan.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Plan",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    f"- Plan state: `{plan_state}`",
    f"- Registration plan ready: `{str(registration_plan_ready).lower()}`",
    "- Registration execution allowed: `false`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Planned Records",
    "",
]
for item in planned_records:
    lines.append(f"- `{item['record']}` for `{candidate_id}` - write allowed: `false`; gate: `{item['required_gate']}`")
lines.extend(["", "## Execution Gate Requirements", ""])
for item in registration_plan_contract["execution_gate_requirements"]:
    lines.append(f"- {item}")
lines.extend(["", "## Rules", ""])
lines.extend(f"- {item}" for item in registration_plan_contract["registration_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_REGISTRY_REGISTRATION_PLAN.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Plan state: `{plan_state}`",
        "- Registration plan is declarative only.",
        "- Registration execution, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Approved decision fixture checked.",
        "- Registration Gate positive planning state checked.",
        "- Planned records are non-writing drafts.",
        "- Future execution gate requirements declared.",
        "- Candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-101 creates the declarative project-registry registration plan.",
        "",
        "The next cut may define the registration execution gate, but this plan does not write registry records, select projects or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-plan.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_plan_ready",
            event_type="human_gate.registration_plan",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-plan.sh",
                "mode": "read_only",
            },
            ticket="TKT-101",
            title="ARTEMIS Project Registry Registration Plan",
            exec_pack="docs/exec-packs/done/TKT-101-artemis-project-registry-registration-plan.md",
            artifact_root=str(artifact_root),
            state_to="planning_ready" if overall == "project_registry_registration_plan_ready" else "blocked",
            payload={
                "project_registry_registration_plan_ready": overall == "project_registry_registration_plan_ready",
                "candidate_project_id": candidate_id,
                "plan_state": plan_state,
                "registration_plan_ready": registration_plan_ready,
                "registration_execution_allowed": False,
                "candidate_registration_allowed": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="approved_decision_fixture",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": plan_state,
                "reason": "Registration planning is ready, but execution requires a future explicit gate.",
                "options": ["prepare registration execution gate", "keep plan read-only"],
            },
            severity="info" if overall == "project_registry_registration_plan_ready" else "warning",
            logs=[
                str(artifact_root / "project-registry-registration-plan.json"),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_PLAN.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration plan: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"plan_state={plan_state}")
    print(f"registration_plan_ready={str(registration_plan_ready).lower()}")
    print("registration_execution_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
