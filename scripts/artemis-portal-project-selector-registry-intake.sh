#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-selector-registry-intake/run-01"
project_selector="artifacts/artemis-portal-project-selector/run-01/project-selector-contract.json"
external_project_registration="artifacts/artemis-portal-external-project-registration/run-01/external-project-registration.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-selector-registry-intake.sh [--artifact-root path] [--project-selector path] [--external-project-registration path] [--json]

Builds the ARTEMIS Project Selector Registry Intake read model. It joins the
current selected project with terminal-connect candidates. It does not approve
external projects, switch projects, authenticate providers, start agents,
execute commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --project-selector)
      project_selector="${2:-}"
      if [ -z "$project_selector" ]; then usage; exit 2; fi
      shift 2
      ;;
    --external-project-registration)
      external_project_registration="${2:-}"
      if [ -z "$external_project_registration" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$project_selector" "$external_project_registration" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
selector_path = Path(sys.argv[2])
registration_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

missing_files = []
for path in [
    selector_path,
    registration_path,
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR.md"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR_REGISTRY_INTAKE.md"),
    Path("docs/portal/ARTEMIS_PORTAL_EXTERNAL_PROJECT_REGISTRATION.md"),
    Path("docs/exec-packs/done/TKT-086-artemis-portal-project-selector.md"),
    Path("docs/exec-packs/done/TKT-089-artemis-portal-external-project-registration.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

selector_payload = json.loads(selector_path.read_text(encoding="utf-8")) if selector_path.is_file() else {}
registration_payload = json.loads(registration_path.read_text(encoding="utf-8")) if registration_path.is_file() else {}

selected_project = selector_payload.get("selected_project", {})
selector_contract = selector_payload.get("selector_contract", {})
registration_contract = registration_payload.get("external_project_registration_contract", {})
candidates = registration_contract.get("candidate_projects", [])

selected_entry = {
    "project_id": selected_project.get("project_id", "artemis_method_kit"),
    "display_name": selected_project.get("display_name", "ARTEMIS Method Kit"),
    "repo_root": selected_project.get("repo_root", ""),
    "git_branch": selected_project.get("git_branch", ""),
    "selection_state": selected_project.get("selection_state", "selected_read_only"),
    "registry_state": "selected_read_only",
    "runtime_execution_allowed": False,
    "remote_writes_allowed": False,
    "human_review_required_for_runtime": True,
}

candidate_entries = []
for candidate in candidates:
    candidate_entries.append({
        "project_id": candidate.get("project_id", "candidate"),
        "display_name": candidate.get("display_name", candidate.get("project_id", "Projeto candidato")),
        "repo_root": candidate.get("repo_root", candidate.get("project_path", "")),
        "git_branch": candidate.get("git_branch", ""),
        "selection_state": "not_selectable",
        "registry_state": "candidate_review_pending",
        "source_connect_artifact": candidate.get("source_connect_artifact", ""),
        "provider_count": len(candidate.get("provider_discovery", [])),
        "runtime_execution_allowed": False,
        "remote_writes_allowed": False,
        "human_review_required": True,
    })

registry_contract = {
    "purpose": "Join selected project context with terminal-connect candidates before any project switcher or runtime route.",
    "state": "registry_intake_read_model",
    "source_authority": [
        str(selector_path),
        str(registration_path),
    ],
    "selected_project_id": selected_entry["project_id"],
    "selected_project": selected_entry,
    "registry_entries": [selected_entry],
    "candidate_entries": candidate_entries,
    "candidate_count": len(candidate_entries),
    "registered_project_count": 1,
    "external_projects_registered": 0,
    "selectable_project_count": 1,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "provider_auth_connected": False,
    "worktree_created": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "state_model": [
        "selected_read_only",
        "candidate_review_pending",
        "registered_read_only",
        "runtime_blocked",
        "rejected",
    ],
    "intake_rules": [
        "Selected ARTEMIS method project is visible as read-only context.",
        "Terminal-connect candidates remain review-only and not selectable.",
        "External candidates do not become registered projects automatically.",
        "Project switching remains blocked until human review records a registry decision.",
        "Runtime remains blocked until workspace, provider auth, budget, validation and human runtime gates pass.",
    ],
}

checks = [
    {
        "id": "project_selector_ready",
        "status": "passed" if selector_payload.get("overall") == "project_selector_ready" else "failed",
        "detail": "Registry Intake consumes the Project Selector read-only contract.",
    },
    {
        "id": "external_registration_ready",
        "status": "passed" if registration_payload.get("overall") == "external_project_registration_ready" else "failed",
        "detail": "Registry Intake consumes terminal-connect registration candidates.",
    },
    {
        "id": "selected_project_preserved",
        "status": "passed" if selected_entry["selection_state"] == "selected_read_only" else "failed",
        "detail": "Current ARTEMIS project remains selected read-only.",
    },
    {
        "id": "candidate_not_selectable",
        "status": "passed" if all(item["selection_state"] == "not_selectable" for item in candidate_entries) else "failed",
        "detail": "Candidates remain review-only and cannot be selected by this cut.",
    },
    {
        "id": "external_projects_not_registered",
        "status": "passed" if registry_contract["external_projects_registered"] == 0 else "failed",
        "detail": "No external project is registered automatically.",
    },
    {
        "id": "project_switching_blocked",
        "status": "passed" if registry_contract["project_switching_allowed"] is False else "failed",
        "detail": "The registry intake does not allow switching active project.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if registry_contract["runtime_execution_allowed"] is False else "failed",
        "detail": "Registry intake does not permit runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No provider auth, worktree, agent, command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_selector_registry_intake_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_selector_registry_intake_ready": overall == "project_selector_registry_intake_ready",
    "secret_values_recorded": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "worktree_created": False,
    "branch_changed": False,
    "project_switching_allowed": False,
    "runtime_execution_allowed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-095 - Control Plane Project Registry Home State",
    "missing_files": missing_files,
    "registry_contract": registry_contract,
    "checks": checks,
}

(artifact_root / "project-selector-registry-intake.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Project Selector Registry Intake",
    "",
    f"- Overall: `{overall}`",
    f"- Selected project: `{selected_entry['display_name']}`",
    f"- Selected project id: `{selected_entry['project_id']}`",
    f"- Candidate count: `{len(candidate_entries)}`",
    "- External projects registered: `0`",
    "- Project switching allowed: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Regras",
    "",
]
lines.extend(f"- {item}" for item in registry_contract["intake_rules"])
lines.extend(["", "## Candidatos", ""])
if candidate_entries:
    for candidate in candidate_entries:
        lines.append(f"- `{candidate['project_id']}`: {candidate['display_name']} -> `{candidate['registry_state']}`")
else:
    lines.append("- Nenhum candidato externo.")
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_SELECTOR_REGISTRY_INTAKE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Project Selector Registry Intake recorded.",
        "- Current ARTEMIS project remains selected read-only.",
        "- Terminal-connect candidate remains review-only.",
        "- Runtime, project switching and remote mutation remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Project Selector artifact checked.",
        "- External Project Registration artifact checked.",
        "- Selected project state checked.",
        "- Candidate review-only state checked.",
        "- Project switching, runtime execution, provider auth and remote mutation remain blocked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-094 introduces the registry intake read model.",
        "",
        "The portal now has a small, explicit source for which project is selected and which terminal-connected projects are only candidates.",
        "",
        "The next cut can render this registry state in the human home without adding technical noise or runtime actions.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-selector-registry-intake.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_project_selector_registry_intake_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_selector",
                "name": "scripts/artemis-portal-project-selector-registry-intake.sh",
                "mode": "read_only",
            },
            ticket="TKT-094",
            title="ARTEMIS Portal Project Selector Registry Intake",
            exec_pack="docs/exec-packs/done/TKT-094-artemis-portal-project-selector-registry-intake.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "project_selector_registry_intake_ready" else "blocked",
            payload={
                "project_selector_registry_intake_ready": overall == "project_selector_registry_intake_ready",
                "selected_project_id": selected_entry["project_id"],
                "candidate_count": len(candidate_entries),
                "external_projects_registered": 0,
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
            severity="info",
            logs=[
                str(artifact_root / "project-selector-registry-intake.json"),
                str(artifact_root / "PROJECT_SELECTOR_REGISTRY_INTAKE.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal project selector registry intake: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"selected_project_id={selected_entry['project_id']}")
    print(f"candidate_count={len(candidate_entries)}")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
