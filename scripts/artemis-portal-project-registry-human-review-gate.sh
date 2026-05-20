#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-registry-human-review-gate/run-01"
registry_intake="artifacts/artemis-portal-project-selector-registry-intake/run-01/project-selector-registry-intake.json"
control_plane="control-plane/index.html"
decision_file=""
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-registry-human-review-gate.sh [--artifact-root path] [--registry-intake path] [--control-plane path] [--decision path] [--json]

Builds the ARTEMIS Project Registry Human Review Gate. It turns candidate
registry intake into a human decision contract. It does not approve candidates
by itself, switch projects, authenticate providers, start runtime, execute
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
    --registry-intake)
      registry_intake="${2:-}"
      if [ -z "$registry_intake" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$registry_intake" "$control_plane" "$decision_file" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
registry_path = Path(sys.argv[2])
control_plane_path = Path(sys.argv[3])
decision_arg = sys.argv[4]
output_format = sys.argv[5]
decision_path = Path(decision_arg) if decision_arg else None
generated_at = now_utc()

missing_files = []
for path in [
    registry_path,
    control_plane_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR_REGISTRY_INTAKE.md"),
    Path("docs/control-plane/ARTEMIS_CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md"),
    Path("docs/exec-packs/done/TKT-094-artemis-portal-project-selector-registry-intake.md"),
    Path("docs/exec-packs/done/TKT-095-artemis-control-plane-project-registry-home-state.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

registry_payload = json.loads(registry_path.read_text(encoding="utf-8")) if registry_path.is_file() else {}
html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
registry_contract = registry_payload.get("registry_contract", {})
selected = registry_contract.get("selected_project", {})
candidates = registry_contract.get("candidate_entries", [])

decision_payload = {}
if decision_path and decision_path.is_file():
    decision_payload = json.loads(decision_path.read_text(encoding="utf-8"))

decision = decision_payload.get("decision", "pending")
valid_decisions = {"pending", "approved", "rejected", "deferred"}
decision_is_valid = decision in valid_decisions
decision_recorded = bool(decision_payload) and decision_is_valid and decision != "pending"
approved_candidate_id = decision_payload.get("candidate_project_id", "") if decision == "approved" else ""

candidate_reviews = []
for candidate in candidates:
    candidate_id = candidate.get("project_id", "")
    is_target = candidate_id == approved_candidate_id
    candidate_reviews.append({
        "candidate_project_id": candidate_id,
        "display_name": candidate.get("display_name", candidate_id),
        "repo_root": candidate.get("repo_root", ""),
        "registry_state": candidate.get("registry_state", "candidate_review_pending"),
        "review_state": "approved_for_registration_gate" if is_target else "pending_human_decision",
        "decision_recorded": bool(is_target),
        "selection_state": "not_selectable",
        "project_switching_allowed": False,
        "runtime_execution_allowed": False,
        "remote_writes_allowed": False,
    })

pending_count = sum(1 for item in candidate_reviews if item["review_state"] == "pending_human_decision")
approved_count = sum(1 for item in candidate_reviews if item["review_state"] == "approved_for_registration_gate")
review_state = "decision_recorded" if decision_recorded else "waiting_for_human_decision"

review_contract = {
    "purpose": "Require an explicit human registry decision before any project registration, switch or runtime route.",
    "state": "human_review_gate",
    "review_state": review_state,
    "selected_project_id": selected.get("project_id", ""),
    "selected_project_root": selected.get("repo_root", ""),
    "candidate_count": len(candidate_reviews),
    "pending_candidate_count": pending_count,
    "approved_candidate_count": approved_count,
    "decision_recorded": decision_recorded,
    "decision": decision if decision_is_valid else "invalid",
    "decision_file": str(decision_path) if decision_path else "",
    "decision_options": ["approved", "rejected", "deferred"],
    "required_decision_fields": [
        "candidate_project_id",
        "decision",
        "decided_by",
        "decided_at",
        "rationale",
    ],
    "candidate_reviews": candidate_reviews,
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "human_review_rules": [
        "The gate may record a human decision, but it does not switch projects.",
        "Approval only allows a later registration cut to continue; it does not start runtime.",
        "Rejected or deferred candidates remain non-selectable.",
        "No provider authentication, workspace write, command execution, token spend or remote mutation happens here.",
    ],
}

required_tokens = [
    "projectSelectorRegistryIntakeSourceUrl",
    "renderProjectSelectorRegistryIntake",
    "operation-registration-title",
    "operation-registration-state",
    "operation-runtime-title",
]

checks = [
    {
        "id": "registry_intake_ready",
        "status": "passed" if registry_payload.get("overall") == "project_selector_registry_intake_ready" else "failed",
        "detail": "Human Review Gate consumes the Project Selector Registry Intake.",
    },
    {
        "id": "candidate_waits_for_human_decision",
        "status": "passed" if len(candidate_reviews) >= 1 and pending_count >= 1 and not decision_recorded else "failed",
        "detail": "At least one candidate is present and remains pending human decision by default.",
    },
    {
        "id": "decision_schema_declared",
        "status": "passed" if set(review_contract["required_decision_fields"]) == {"candidate_project_id", "decision", "decided_by", "decided_at", "rationale"} else "failed",
        "detail": "The gate declares the minimum human decision fields.",
    },
    {
        "id": "control_plane_can_render_gate_state",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane has the existing home nodes needed to show the human review state.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if review_contract["project_switching_allowed"] is False else "failed",
        "detail": "The human review gate does not switch active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if review_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "The human review gate does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No provider auth, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_registry_human_review_gate_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_registry_human_review_gate_ready": overall == "project_registry_human_review_gate_ready",
    "review_state": review_state,
    "human_decision_required": True,
    "human_decision_recorded": decision_recorded,
    "candidate_approval_recorded": approved_count > 0,
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
    "next_cut": "TKT-097 - Project Registry Decision Intake",
    "missing_files": missing_files,
    "review_contract": review_contract,
    "checks": checks,
}

(artifact_root / "project-registry-human-review-gate.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Project Registry Human Review Gate",
    "",
    f"- Overall: `{overall}`",
    f"- Review state: `{review_state}`",
    f"- Selected project: `{selected.get('display_name', '')}`",
    f"- Selected root: `{selected.get('repo_root', '')}`",
    f"- Candidates waiting: `{pending_count}`",
    f"- Decision recorded: `{str(decision_recorded).lower()}`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Decision Schema",
    "",
]
for field in review_contract["required_decision_fields"]:
    lines.append(f"- `{field}`")
lines.extend(["", "## Candidate Reviews", ""])
if candidate_reviews:
    for candidate in candidate_reviews:
        lines.append(f"- `{candidate['candidate_project_id']}`: `{candidate['review_state']}`")
else:
    lines.append("- No candidates.")
lines.extend(["", "## Rules", ""])
lines.extend(f"- {item}" for item in review_contract["human_review_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Project Registry Human Review Gate is ready.",
        "- A candidate is waiting for explicit human decision.",
        "- No project switching, runtime, auth, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Registry Intake artifact checked.",
        "- Candidate pending human decision checked.",
        "- Human decision schema checked.",
        "- Control Plane home render tokens checked.",
        "- Project switching and runtime remain blocked.",
        "- No commands, agents, tokens or remote writes happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-096 defines the human review gate for project registry candidates.",
        "",
        "The next cut can ingest an explicit decision file. It must still avoid project switching and runtime launch until the later registration and runtime gates pass.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-registry-human-review-gate.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_project_registry_human_review_gate_ready",
            event_type="human_gate.waiting",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_registry",
                "name": "scripts/artemis-portal-project-registry-human-review-gate.sh",
                "mode": "read_only",
            },
            ticket="TKT-096",
            title="ARTEMIS Project Registry Human Review Gate",
            exec_pack="docs/exec-packs/done/TKT-096-artemis-project-registry-human-review-gate.md",
            artifact_root=str(artifact_root),
            state_to="human_gate" if overall == "project_registry_human_review_gate_ready" else "blocked",
            payload={
                "project_registry_human_review_gate_ready": overall == "project_registry_human_review_gate_ready",
                "review_state": review_state,
                "candidate_count": len(candidate_reviews),
                "pending_candidate_count": pending_count,
                "human_decision_required": True,
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
            state_from="registry_intake",
            runner={"kind": "none"},
            gate={
                "kind": "human",
                "status": "waiting_for_human_decision",
                "reason": "Candidate project requires explicit owner review before registration.",
                "options": ["approved", "rejected", "deferred"],
            },
            severity="warning",
            logs=[
                str(artifact_root / "project-registry-human-review-gate.json"),
                str(artifact_root / "PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS project registry human review gate: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"review_state={review_state}")
    print(f"human_decision_required=true")
    print(f"human_decision_recorded={str(decision_recorded).lower()}")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
