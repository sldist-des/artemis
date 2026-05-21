#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-control-plane-operational-decision-home/run-01"
control_plane="control-plane/index.html"
decision_intake="artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-intake.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-control-plane-operational-decision-home.sh [--artifact-root path] [--control-plane path] [--decision-intake path] [--json]

Validates that the Control Plane home exposes useful operational next-action
state from Project Registry Decision Intake without enabling project
registration, project switching, runtime, provider auth, commands, token spend
or remote mutation.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --control-plane)
      control_plane="${2:-}"
      if [ -z "$control_plane" ]; then usage; exit 2; fi
      shift 2
      ;;
    --decision-intake)
      decision_intake="${2:-}"
      if [ -z "$decision_intake" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$control_plane" "$decision_intake" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
control_plane_path = Path(sys.argv[2])
decision_intake_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    control_plane_path,
    decision_intake_path,
    Path("docs/control-plane/ARTEMIS_CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_DECISION_INTAKE.md"),
    Path("docs/exec-packs/done/TKT-097-artemis-project-registry-decision-intake.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

html = control_plane_path.read_text(encoding="utf-8") if control_plane_path.is_file() else ""
decision_payload = json.loads(decision_intake_path.read_text(encoding="utf-8")) if decision_intake_path.is_file() else {}
contract = decision_payload.get("decision_contract", {})

required_tokens = [
    "decision-brief",
    "decision-brief-action",
    "decision-brief-file",
    "decision-brief-blockers",
    "projectRegistryDecisionIntakeSourceUrl",
    "renderProjectRegistryDecisionIntake",
    "Preencher decisao humana",
    "project-registry-decision-template.json",
    "registro, troca e runtime bloqueados",
]

decision_state = contract.get("decision_state", decision_payload.get("decision_state", ""))
template_path = contract.get("template_path", "")
template_exists = Path(template_path).is_file() if template_path else False

checks = [
    {
        "id": "decision_intake_ready",
        "status": "passed" if decision_payload.get("overall") == "project_registry_decision_intake_ready" else "failed",
        "detail": "Operational home consumes Project Registry Decision Intake.",
    },
    {
        "id": "decision_pending_visible",
        "status": "passed" if decision_state == "pending" and "Decisao pendente" in html else "failed",
        "detail": "Home can show pending decision state.",
    },
    {
        "id": "next_action_visible",
        "status": "passed" if "Preencher decisao humana" in html else "failed",
        "detail": "Home exposes the immediate operational next action.",
    },
    {
        "id": "decision_template_linked",
        "status": "passed" if "project-registry-decision-template.json" in html and template_exists else "failed",
        "detail": "Home links to the fillable decision template artifact.",
    },
    {
        "id": "blockers_visible",
        "status": "passed" if "registro, troca e runtime bloqueados" in html else "failed",
        "detail": "Home exposes the blocking operational constraints.",
    },
    {
        "id": "control_plane_tokens_present",
        "status": "passed" if all(token in html for token in required_tokens) else "failed",
        "detail": "Control Plane contains operational decision home tokens.",
    },
    {
        "id": "project_switching_still_blocked",
        "status": "passed" if decision_payload.get("project_switching_allowed") is False else "failed",
        "detail": "Operational home does not allow project switching.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if decision_payload.get("runtime_execution_allowed") is False else "failed",
        "detail": "Operational home does not allow runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed" if decision_payload.get("agents_started") is False and int(decision_payload.get("commands_executed", 1)) == 0 and int(decision_payload.get("tokens_spent", 1)) == 0 else "failed",
        "detail": "No agents, commands or tokens are produced by the operational home.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "control_plane_operational_decision_home_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "control_plane_operational_decision_home_ready": overall == "control_plane_operational_decision_home_ready",
    "decision_state": decision_state,
    "next_action": "fill_human_decision_template",
    "decision_template": template_path,
    "human_decision_recorded": False,
    "candidate_registration_allowed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-099 - Project Registry Registration Gate",
    "missing_files": missing_files,
    "home_contract": {
        "control_plane": str(control_plane_path),
        "decision_intake": str(decision_intake_path),
        "surface": "operational_decision_home",
        "primary_state": "Decisao pendente",
        "primary_action": "Preencher decisao humana",
        "primary_artifact": template_path,
        "visible_blockers": ["registro", "troca de projeto", "runtime"],
    },
    "checks": checks,
}

(artifact_root / "control-plane-operational-decision-home.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Control Plane Operational Decision Home",
    "",
    f"- Overall: `{overall}`",
    "- Surface: `operational_decision_home`",
    "- Primary state: `Decisao pendente`",
    "- Primary action: `Preencher decisao humana`",
    f"- Decision template: `{template_path}`",
    "- Candidate registration allowed: `false`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Checks",
    "",
]
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Control Plane home now exposes the next operational decision.",
        "- The home remains read-only and does not register, switch project or start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Decision Intake artifact checked.",
        "- Pending decision state checked.",
        "- Next action checked.",
        "- Decision template link checked.",
        "- Visible blockers checked.",
        "- Runtime, project switching, commands and tokens remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-098 makes the Control Plane home operational: it shows what decision is pending, which artifact to fill, and which capabilities remain blocked.",
        "",
        "The next cut can define the registration gate after a valid human decision exists.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-control-plane-operational-decision-home.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_control_plane_operational_decision_home_ready",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "control_plane",
                "name": "scripts/artemis-control-plane-operational-decision-home.sh",
                "mode": "read_only",
            },
            ticket="TKT-098",
            title="ARTEMIS Control Plane Operational Decision Home",
            exec_pack="docs/exec-packs/done/TKT-098-artemis-control-plane-operational-decision-home.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "control_plane_operational_decision_home_ready" else "blocked",
            payload={
                "control_plane_operational_decision_home_ready": overall == "control_plane_operational_decision_home_ready",
                "decision_state": decision_state,
                "next_action": payload["next_action"],
                "human_decision_recorded": False,
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
            severity="info",
            logs=[
                str(artifact_root / "control-plane-operational-decision-home.json"),
                str(artifact_root / "CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS control plane operational decision home: {overall}")
    print(f"artifact_root={artifact_root}")
    print("next_action=fill_human_decision_template")
    print("candidate_registration_allowed=false")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("commands_executed=0")
PY
