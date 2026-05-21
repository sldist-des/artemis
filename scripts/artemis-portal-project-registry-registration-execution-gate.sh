#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-registration-execution-gate/run-01"
registration_plan="artifacts/artemis-portal-project-registry-registration-plan/run-01/project-registry-registration-plan.json"
approval_file=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-registration-execution-gate.sh [--artifact-root path] [--registration-plan path] [--approval path] [--json]

Builds the ARTEMIS Project Registry Registration Execution Gate. It consumes a
registration plan and blocks real registry writes until explicit real-human
approval and execution evidence exist. It does not register projects, switch
projects, authenticate providers, create worktrees, start runtime, execute
commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --registration-plan)
      registration_plan="${2:-}"
      if [ -z "$registration_plan" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$registration_plan" "$approval_file" "$format" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
registration_plan_path = Path(sys.argv[2])
approval_arg = sys.argv[3]
output_format = sys.argv[4]
approval_path = Path(approval_arg) if approval_arg else None
generated_at = now_utc()

missing_files = []
for path in [
    registration_plan_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_PLAN.md"),
    Path("docs/exec-packs/done/TKT-101-artemis-project-registry-registration-plan.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

plan_payload = json.loads(registration_plan_path.read_text(encoding="utf-8")) if registration_plan_path.is_file() else {}
plan_contract = plan_payload.get("registration_plan_contract", {})
candidate_id = plan_payload.get("candidate_project_id", "")

approval_template = {
    "schema_version": 1,
    "candidate_project_id": candidate_id,
    "decision": "pending",
    "approved_by": "",
    "approved_at": "",
    "approval_scope": "project_registry_registration_execution",
    "write_target": "",
    "diff_preview_path": "",
    "rollback_plan_path": "",
    "validation_commands": [],
    "rationale": "",
    "acknowledged_constraints": [
        "approval_writes_registry_only_after_explicit_gate",
        "approval_does_not_switch_project",
        "approval_does_not_start_runtime",
        "approval_does_not_authenticate_provider",
        "approval_does_not_write_remote",
    ],
}
(artifact_root / "project-registry-registration-execution-approval-template.json").write_text(
    json.dumps(approval_template, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

approval_payload = {}
approval_source = str(artifact_root / "project-registry-registration-execution-approval-template.json")
if approval_path and approval_path.is_file():
    approval_payload = json.loads(approval_path.read_text(encoding="utf-8"))
    approval_source = str(approval_path)
else:
    approval_payload = approval_template

decision = approval_payload.get("decision", "pending")
valid_decisions = {"approved", "rejected", "deferred", "pending"}
decision_valid = decision in valid_decisions
approved_at = approval_payload.get("approved_at", "")
timestamp_valid = True
if approved_at:
    try:
        datetime.fromisoformat(approved_at.replace("Z", "+00:00"))
    except ValueError:
        timestamp_valid = False

real_human_approval_recorded = all([
    decision == "approved",
    decision_valid,
    bool(approval_payload.get("approved_by")),
    bool(approved_at),
    timestamp_valid,
    approval_payload.get("candidate_project_id") == candidate_id,
    approval_payload.get("approval_scope") == "project_registry_registration_execution",
    bool(approval_payload.get("write_target")),
    bool(approval_payload.get("diff_preview_path")),
    bool(approval_payload.get("rollback_plan_path")),
    bool(approval_payload.get("validation_commands")),
    bool(approval_payload.get("rationale")),
])

execution_preconditions = {
    "registration_plan_ready": plan_payload.get("overall") == "project_registry_registration_plan_ready",
    "plan_state_ready": plan_payload.get("plan_state") == "ready_for_registration_execution_gate",
    "candidate_known": bool(candidate_id),
    "real_human_approval_recorded": real_human_approval_recorded,
    "write_target_declared": bool(approval_payload.get("write_target")),
    "diff_preview_declared": bool(approval_payload.get("diff_preview_path")),
    "rollback_plan_declared": bool(approval_payload.get("rollback_plan_path")),
    "validation_commands_declared": bool(approval_payload.get("validation_commands")),
    "project_switching_blocked": plan_payload.get("project_switching_allowed") is False,
    "runtime_blocked": plan_payload.get("runtime_execution_allowed") is False,
}

execution_gate_open = all(execution_preconditions.values())
gate_state = "ready_for_registry_write_dry_run" if execution_gate_open else "waiting_for_real_human_execution_approval"

blockers = []
if not execution_preconditions["real_human_approval_recorded"]:
    blockers.append("real_human_execution_approval_missing")
if not execution_preconditions["write_target_declared"]:
    blockers.append("write_target_missing")
if not execution_preconditions["diff_preview_declared"]:
    blockers.append("diff_preview_missing")
if not execution_preconditions["rollback_plan_declared"]:
    blockers.append("rollback_plan_missing")
if not execution_preconditions["validation_commands_declared"]:
    blockers.append("validation_commands_missing")

execution_gate_contract = {
    "purpose": "Require real human authority and execution evidence before any project registry write.",
    "state": "registration_execution_gate",
    "gate_state": gate_state,
    "candidate_project_id": candidate_id,
    "registration_plan": str(registration_plan_path),
    "approval_source": approval_source,
    "real_human_approval_recorded": real_human_approval_recorded,
    "execution_preconditions": execution_preconditions,
    "blockers": blockers,
    "registration_execution_allowed": False,
    "candidate_registration_allowed": False,
    "registry_write_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "planned_records": plan_contract.get("planned_records", []),
    "gate_rules": [
        "A synthetic fixture can never authorize registry writes.",
        "Registry write execution needs real human approval with scope, target, diff preview, rollback plan and validations.",
        "This gate may prepare a future dry-run, but it does not write the registry.",
        "Project switching and runtime remain blocked even after this execution gate is satisfied.",
        "No provider auth, worktree, command execution, token spend or remote mutation happens here.",
    ],
}

checks = [
    {
        "id": "registration_plan_ready",
        "status": "passed" if execution_preconditions["registration_plan_ready"] else "failed",
        "detail": "Execution Gate consumes the Registration Plan.",
    },
    {
        "id": "execution_waits_for_real_human_approval",
        "status": "passed" if not real_human_approval_recorded and "real_human_execution_approval_missing" in blockers else "failed",
        "detail": "Execution remains blocked without real human approval.",
    },
    {
        "id": "approval_template_written",
        "status": "passed" if (artifact_root / "project-registry-registration-execution-approval-template.json").is_file() else "failed",
        "detail": "A fillable approval template is available.",
    },
    {
        "id": "registry_write_still_blocked",
        "status": "passed" if execution_gate_contract["registry_write_allowed"] is False else "failed",
        "detail": "The gate does not write registry records.",
    },
    {
        "id": "candidate_registration_still_blocked",
        "status": "passed" if execution_gate_contract["candidate_registration_allowed"] is False else "failed",
        "detail": "The gate does not register the candidate.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if execution_gate_contract["project_switching_allowed"] is False else "failed",
        "detail": "The gate does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if execution_gate_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "The gate does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if execution_gate_contract["commands_executed"] == 0 and execution_gate_contract["tokens_spent"] == 0 else "failed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_registration_execution_gate_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_registration_execution_gate_ready": overall == "project_registry_registration_execution_gate_ready",
    "candidate_project_id": candidate_id,
    "gate_state": gate_state,
    "real_human_approval_recorded": real_human_approval_recorded,
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
    "next_cut": "TKT-103 - Project Registry Registration Dry Run",
    "missing_files": missing_files,
    "execution_gate_contract": execution_gate_contract,
    "checks": checks,
}

(artifact_root / "project-registry-registration-execution-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Registration Execution Gate",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate: `{candidate_id}`",
    f"- Gate state: `{gate_state}`",
    f"- Real human approval recorded: `{str(real_human_approval_recorded).lower()}`",
    "- Registration execution allowed: `false`",
    "- Registry write allowed: `false`",
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
lines.extend(["", "## Approval Template", "", f"- `{artifact_root / 'project-registry-registration-execution-approval-template.json'}`"])
lines.extend(["", "## Gate Rules", ""])
lines.extend(f"- {item}" for item in execution_gate_contract["gate_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Gate state: `{gate_state}`",
        "- Real human approval is still missing.",
        "- Registry write, project switching and runtime remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Registration Plan checked.",
        "- Real human execution approval requirement checked.",
        "- Approval template written.",
        "- Registry write, candidate registration, project switching and runtime remain blocked.",
        "- No provider auth, worktree, commands, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-102 creates the registration execution gate for the Project Registry.",
        "",
        "The next cut may build a dry-run of registry writes after real approval is recorded. This gate still does not write registry records, select projects or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-registration-execution-gate.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_registration_execution_gate_ready",
            event_type="human_gate.registration_execution_gate",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-registration-execution-gate.sh",
                "mode": "read_only",
            },
            ticket="TKT-102",
            title="ARTEMIS Project Registry Registration Execution Gate",
            exec_pack="docs/exec-packs/done/TKT-102-artemis-project-registry-registration-execution-gate.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_registration_execution_gate_ready" else "blocked",
            payload={
                "project_registry_registration_execution_gate_ready": overall == "project_registry_registration_execution_gate_ready",
                "candidate_project_id": candidate_id,
                "gate_state": gate_state,
                "real_human_approval_recorded": real_human_approval_recorded,
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
            state_from="registration_plan",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": gate_state,
                "reason": "Registry write execution requires real human approval and execution evidence.",
                "options": ["provide real approval package", "keep registration blocked"],
            },
            severity="warning",
            logs=[
                str(artifact_root / "project-registry-registration-execution-gate.json"),
                str(artifact_root / "PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md"),
                str(artifact_root / "project-registry-registration-execution-approval-template.json"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry registration execution gate: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"gate_state={gate_state}")
    print(f"real_human_approval_recorded={str(real_human_approval_recorded).lower()}")
    print("registration_execution_allowed=false")
    print("registry_write_allowed=false")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
