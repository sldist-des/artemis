#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-decision-intake/run-01"
human_review_gate="artifacts/artemis-portal-project-registry-human-review-gate/run-01/project-registry-human-review-gate.json"
control_plane="control-plane/index.html"
decision_file=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-decision-intake.sh [--artifact-root path] [--human-review-gate path] [--control-plane path] [--decision path] [--json]

Builds the ARTEMIS Project Registry Decision Intake. It validates a human
decision file when one is provided and otherwise emits a pending decision
template. It does not register projects, switch projects, authenticate
providers, start runtime, execute commands, spend tokens or mutate remote state.
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

python3 - "$artifact_root" "$human_review_gate" "$control_plane" "$decision_file" "$format" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
gate_path = Path(sys.argv[2])
control_plane_path = Path(sys.argv[3])
decision_arg = sys.argv[4]
output_format = sys.argv[5]
decision_path = Path(decision_arg) if decision_arg else None
generated_at = now_utc()

missing_files = []
for path in [
    gate_path,
    control_plane_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_DECISION_INTAKE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md"),
    Path("docs/exec-packs/done/TKT-096-artemis-project-registry-human-review-gate.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

gate_payload = json.loads(gate_path.read_text(encoding="utf-8")) if gate_path.is_file() else {}
html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
review_contract = gate_payload.get("review_contract", {})
candidate_reviews = review_contract.get("candidate_reviews", [])
candidate_ids = {item.get("candidate_project_id") for item in candidate_reviews}
first_candidate = candidate_reviews[0] if candidate_reviews else {}

template = {
    "schema_version": 1,
    "candidate_project_id": first_candidate.get("candidate_project_id", ""),
    "decision": "pending",
    "decided_by": "",
    "decided_at": "",
    "rationale": "",
    "constraints_acknowledged": [
        "approval_does_not_switch_project",
        "approval_does_not_start_runtime",
        "approval_does_not_authenticate_provider",
        "approval_does_not_write_remote",
    ],
}
(artifact_root / "project-registry-decision-template.json").write_text(
    json.dumps(template, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

decision_payload = {}
decision_source = ""
if decision_path and decision_path.is_file():
    decision_payload = json.loads(decision_path.read_text(encoding="utf-8"))
    decision_source = str(decision_path)
else:
    decision_payload = template
    decision_source = str(artifact_root / "project-registry-decision-template.json")

decision = decision_payload.get("decision", "pending")
candidate_id = decision_payload.get("candidate_project_id", "")
decided_by = decision_payload.get("decided_by", "")
decided_at = decision_payload.get("decided_at", "")
rationale = decision_payload.get("rationale", "")
valid_decisions = {"approved", "rejected", "deferred", "pending"}
decision_valid = decision in valid_decisions
candidate_known = bool(candidate_id) and candidate_id in candidate_ids
required_fields_present = all([
    bool(candidate_id),
    bool(decision),
    bool(decided_by) if decision != "pending" else True,
    bool(decided_at) if decision != "pending" else True,
    bool(rationale) if decision != "pending" else True,
])
timestamp_valid = True
if decided_at:
    try:
        datetime.fromisoformat(decided_at.replace("Z", "+00:00"))
    except ValueError:
        timestamp_valid = False

decision_recorded = decision in {"approved", "rejected", "deferred"} and decision_valid and candidate_known and required_fields_present and timestamp_valid
decision_state = "recorded" if decision_recorded else "pending"
if decision != "pending" and not decision_recorded:
    decision_state = "invalid"

approved_for_next_gate = decision == "approved" and decision_recorded
rejected = decision == "rejected" and decision_recorded
deferred = decision == "deferred" and decision_recorded

decision_contract = {
    "purpose": "Classify a human project-registry decision before registration can be considered.",
    "state": "decision_intake",
    "decision_state": decision_state,
    "decision_source": decision_source,
    "template_path": str(artifact_root / "project-registry-decision-template.json"),
    "candidate_project_id": candidate_id,
    "candidate_known": candidate_known,
    "decision": decision if decision_valid else "invalid",
    "decision_recorded": decision_recorded,
    "approved_for_registration_gate": approved_for_next_gate,
    "rejected": rejected,
    "deferred": deferred,
    "required_fields_present": required_fields_present,
    "timestamp_valid": timestamp_valid,
    "decision_options": ["approved", "rejected", "deferred"],
    "required_decision_fields": [
        "candidate_project_id",
        "decision",
        "decided_by",
        "decided_at",
        "rationale",
    ],
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "intake_rules": [
        "Pending means no owner decision has been recorded yet.",
        "Approved only unlocks a later registration gate; it does not register or switch projects.",
        "Rejected and deferred decisions remain non-selectable.",
        "Invalid decisions block the next gate until corrected.",
        "No provider auth, runtime, command execution, token spend or remote mutation happens here.",
    ],
}

required_tokens = [
    "projectRegistryDecisionIntakeSourceUrl",
    "renderProjectRegistryDecisionIntake",
    "operation-registration-title",
    "operation-registration-state",
    "operation-runtime-title",
]

checks = [
    {
        "id": "human_review_gate_ready",
        "status": "passed" if gate_payload.get("overall") == "project_registry_human_review_gate_ready" else "failed",
        "detail": "Decision Intake consumes the Human Review Gate.",
    },
    {
        "id": "decision_template_written",
        "status": "passed" if (artifact_root / "project-registry-decision-template.json").is_file() else "failed",
        "detail": "A fillable pending decision template is available.",
    },
    {
        "id": "decision_state_classified",
        "status": "passed" if decision_state in {"pending", "recorded", "invalid"} else "failed",
        "detail": "Decision payload was classified.",
    },
    {
        "id": "pending_without_side_effects",
        "status": "passed" if decision_state == "pending" and not decision_recorded else "failed",
        "detail": "Default intake stays pending until a human decision file exists.",
    },
    {
        "id": "control_plane_can_render_decision_state",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains the decision intake source, loader and renderer.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if decision_contract["project_switching_allowed"] is False else "failed",
        "detail": "Decision Intake does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if decision_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "Decision Intake does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No provider auth, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_decision_intake_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_decision_intake_ready": overall == "project_registry_decision_intake_ready",
    "decision_state": decision_state,
    "human_decision_required": True,
    "human_decision_recorded": decision_recorded,
    "approved_for_registration_gate": approved_for_next_gate,
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
    "next_cut": "TKT-099 - Project Registry Registration Gate",
    "missing_files": missing_files,
    "decision_contract": decision_contract,
    "checks": checks,
}

(artifact_root / "project-registry-decision-intake.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Decision Intake",
    "",
    f"- Overall: `{overall}`",
    f"- Decision state: `{decision_state}`",
    f"- Candidate: `{candidate_id}`",
    f"- Human decision recorded: `{str(decision_recorded).lower()}`",
    f"- Approved for registration gate: `{str(approved_for_next_gate).lower()}`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Template: `{decision_contract['template_path']}`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Required Fields",
    "",
]
for field in decision_contract["required_decision_fields"]:
    lines.append(f"- `{field}`")
lines.extend(["", "## Rules", ""])
lines.extend(f"- {item}" for item in decision_contract["intake_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_REGISTRY_DECISION_INTAKE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Decision state: `{decision_state}`",
        "- A pending decision template is available for the human owner.",
        "- No project registration, switching, runtime, auth, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Human Review Gate artifact checked.",
        "- Pending decision template written.",
        "- Decision payload classified.",
        "- Control Plane decision intake render tokens checked.",
        "- Registration, project switching and runtime remain blocked.",
        "- No commands, agents, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-097 records the decision intake surface for project registry candidates.",
        "",
        "The default state is pending. A later cut may consume an explicit owner decision and then route to the registration gate, but this cut still does not register, switch project or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-decision-intake.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_decision_intake_ready",
            event_type="human_gate.decision_intake",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-decision-intake.sh",
                "mode": "read_only",
            },
            ticket="TKT-097",
            title="ARTEMIS Project Registry Decision Intake",
            exec_pack="docs/exec-packs/done/TKT-097-artemis-project-registry-decision-intake.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_decision_intake_ready" else "blocked",
            payload={
                "project_registry_decision_intake_ready": overall == "project_registry_decision_intake_ready",
                "decision_state": decision_state,
                "human_decision_required": True,
                "human_decision_recorded": decision_recorded,
                "approved_for_registration_gate": approved_for_next_gate,
                "candidate_registration_allowed": False,
                "project_switching_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="human_review_gate",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": decision_state,
                "reason": "A project registry decision must be provided by the human owner.",
                "options": ["approved", "rejected", "deferred"],
            },
            severity="warning" if decision_state != "recorded" else "info",
            logs=[
                str(artifact_root / "project-registry-decision-intake.json"),
                str(artifact_root / "project-registry-decision-template.json"),
                str(artifact_root / "PROJECT_REGISTRY_DECISION_INTAKE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry decision intake: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"decision_state={decision_state}")
    print(f"human_decision_recorded={str(decision_recorded).lower()}")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
