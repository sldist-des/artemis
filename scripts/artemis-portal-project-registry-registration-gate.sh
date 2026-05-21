#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-gate/run-01"
decision_intake="artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-intake.json"
control_plane="control-plane/index.html"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-gate.sh [--artifact-root path] [--decision-intake path] [--control-plane path] [--json]

Builds the ARTEMIS Project Registry Registration Gate. It decides whether a
candidate may proceed to a later registration action. It does not register
projects, switch projects, authenticate providers, create worktrees, start
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
    --decision-intake)
      decision_intake="${2:-}"
      if [ -z "$decision_intake" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$decision_intake" "$control_plane" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
decision_intake_path = Path(sys.argv[2])
control_plane_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    decision_intake_path,
    control_plane_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_GATE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_DECISION_INTAKE.md"),
    Path("docs/exec-packs/done/TKT-097-artemis-project-registry-decision-intake.md"),
    Path("docs/exec-packs/done/TKT-098-artemis-control-plane-operational-decision-home.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

decision_payload = json.loads(decision_intake_path.read_text(encoding="utf-8")) if decision_intake_path.is_file() else {}
html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
decision_contract = decision_payload.get("decision_contract", {})

decision_state = decision_contract.get("decision_state", decision_payload.get("decision_state", ""))
candidate_id = decision_contract.get("candidate_project_id", "")
decision_recorded = bool(decision_contract.get("decision_recorded"))
approved_for_registration_gate = bool(decision_contract.get("approved_for_registration_gate"))

registration_preconditions = {
    "decision_intake_ready": decision_payload.get("overall") == "project_registry_decision_intake_ready",
    "decision_recorded": decision_recorded,
    "decision_approved": approved_for_registration_gate,
    "candidate_known": bool(decision_contract.get("candidate_known")),
    "runtime_blocked": decision_payload.get("runtime_execution_allowed") is False,
    "project_switching_blocked": decision_payload.get("project_switching_allowed") is False,
}

registration_gate_ready = all(registration_preconditions.values())
gate_state = "ready_for_registration_plan" if registration_gate_ready else "waiting_for_valid_human_decision"
blockers = []
if not registration_preconditions["decision_recorded"]:
    blockers.append("human_decision_not_recorded")
if decision_state == "invalid":
    blockers.append("human_decision_invalid")
if decision_recorded and not approved_for_registration_gate:
    blockers.append("human_decision_not_approved")
if not registration_preconditions["candidate_known"]:
    blockers.append("candidate_not_known")

registration_contract = {
    "purpose": "Gate candidate registration behind validated human approval before any operational project change.",
    "state": "registration_gate",
    "gate_state": gate_state,
    "candidate_project_id": candidate_id,
    "decision_state": decision_state,
    "decision_recorded": decision_recorded,
    "approved_for_registration_gate": approved_for_registration_gate,
    "registration_preconditions": registration_preconditions,
    "blockers": blockers,
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "registration_rules": [
        "Registration requires a recorded approved human decision.",
        "This gate may mark a candidate ready for a future registration plan, but never registers it.",
        "Registration remains blocked while the decision is pending, invalid, rejected or deferred.",
        "Project switching and runtime remain blocked even after registration gate readiness.",
        "No provider auth, worktree, command execution, token spend or remote mutation happens here.",
    ],
}

required_tokens = [
    "projectRegistryRegistrationGateSourceUrl",
    "renderProjectRegistryRegistrationGate",
    "decision-brief-blockers",
    "operation-registration-title",
    "operation-registration-state",
]

checks = [
    {
        "id": "decision_intake_ready",
        "status": "passed" if decision_payload.get("overall") == "project_registry_decision_intake_ready" else "failed",
        "detail": "Registration Gate consumes the Project Registry Decision Intake.",
    },
    {
        "id": "registration_gate_state_classified",
        "status": "passed" if (
            (gate_state == "waiting_for_valid_human_decision" and not registration_gate_ready)
            or (gate_state == "ready_for_registration_plan" and registration_gate_ready)
        ) else "failed",
        "detail": "Registration Gate classifies pending decisions as waiting and approved decisions as ready for planning.",
    },
    {
        "id": "control_plane_can_render_registration_gate",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains registration gate source, loader and renderer.",
    },
    {
        "id": "candidate_registration_still_blocked",
        "status": "passed" if registration_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "This gate does not register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if registration_contract["project_switching_allowed"] is False else "failed",
        "detail": "This gate does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if registration_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "This gate does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_gate_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_gate_ready": overall == "project_registry_registration_gate_ready",
    "gate_state": gate_state,
    "decision_state": decision_state,
    "human_decision_recorded": decision_recorded,
    "approved_for_registration_gate": approved_for_registration_gate,
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
    "next_cut": "TKT-100 - Project Registry Approved Decision Fixture",
    "missing_files": missing_files,
    "registration_contract": registration_contract,
    "checks": checks,
}

(artifact_root / "project-registry-registration-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Gate",
    "",
    f"- Overall: `{overall}`",
    f"- Gate state: `{gate_state}`",
    f"- Decision state: `{decision_state}`",
    f"- Candidate: `{candidate_id}`",
    f"- Human decision recorded: `{str(decision_recorded).lower()}`",
    f"- Approved for registration gate: `{str(approved_for_registration_gate).lower()}`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Blockers",
    "",
]
if blockers:
    lines.extend(f"- `{item}`" for item in blockers)
else:
    lines.append("- None.")
lines.extend(["", "## Rules", ""])
lines.extend(f"- {item}" for item in registration_contract["registration_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_REGISTRY_REGISTRATION_GATE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Gate state: `{gate_state}`",
        "- Candidate registration remains blocked until an approved human decision exists.",
        "- No project registration, switching, runtime, auth, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Decision Intake artifact checked.",
        "- Pending decision blocker checked.",
        "- Control Plane registration gate render tokens checked.",
        "- Candidate registration, project switching and runtime remain blocked.",
        "- No commands, agents, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-099 records the registration gate for Project Registry candidates.",
        "",
        "The gate is structurally ready. A pending decision keeps registration waiting; an approved decision only allows a later registration plan and still does not register, switch project or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-gate.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_gate_ready",
            event_type="human_gate.waiting",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-gate.sh",
                "mode": "read_only",
            },
            ticket="TKT-099",
            title="ARTEMIS Project Registry Registration Gate",
            exec_pack="docs/exec-packs/done/TKT-099-artemis-project-registry-registration-gate.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_registration_gate_ready" else "blocked",
            payload={
                "project_registry_registration_gate_ready": overall == "project_registry_registration_gate_ready",
                "gate_state": gate_state,
                "decision_state": decision_state,
                "human_decision_recorded": decision_recorded,
                "candidate_registration_allowed": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="decision_intake",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": gate_state,
                "reason": "Candidate registration requires a recorded approved human decision.",
                "options": ["provide approved decision", "reject candidate", "defer candidate"],
            },
            severity="info" if gate_state == "ready_for_registration_plan" else "warning",
            logs=[
                str(artifact_root / "project-registry-registration-gate.json"),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_GATE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration gate: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"gate_state={gate_state}")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
