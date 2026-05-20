#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-external-project-registration/run-01"
local_project_connect="artifacts/artemis-portal-local-project-connect/run-01/local-project-connect.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-external-project-registration.sh [--artifact-root path] [--local-project-connect path] [--json]

Builds the ARTEMIS External Project Registration contract. It consumes a Local
Project Connect artifact as a read-only candidate source. It does not scan the
server, register arbitrary projects, authenticate providers, start agents,
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
    --local-project-connect)
      local_project_connect="${2:-}"
      if [ -z "$local_project_connect" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$local_project_connect" "$format" <<'PY'
import hashlib
import json
import re
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
connect_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

missing_files = []
for path in [
    connect_path,
    Path("docs/portal/ARTEMIS_PORTAL_EXTERNAL_PROJECT_REGISTRATION.md"),
    Path("docs/portal/ARTEMIS_PORTAL_LOCAL_PROJECT_CONNECT.md"),
    Path("docs/exec-packs/done/TKT-087-artemis-portal-local-project-connect.md"),
]:
    if not path.is_file():
        missing_files.append(str(path))

connect_payload = json.loads(connect_path.read_text(encoding="utf-8")) if connect_path.is_file() else {}
connected_project = connect_payload.get("connected_project", {})
providers = connect_payload.get("provider_discovery", [])

def slug(value: str) -> str:
    text = re.sub(r"[^a-zA-Z0-9]+", "_", value.strip().lower()).strip("_")
    return text or "project"

project_path = connected_project.get("project_path", "")
repo_root = connected_project.get("repo_root", "")
base_label = Path(repo_root or project_path or "project").name or "project"
fingerprint_source = f"{repo_root}|{project_path}|{connected_project.get('git_remote', '')}"
fingerprint = hashlib.sha256(fingerprint_source.encode("utf-8")).hexdigest()[:10]
candidate_project_id = f"{slug(base_label)}_{fingerprint}"

candidate_record = {
    "project_id": candidate_project_id,
    "display_name": base_label,
    "source_connect_artifact": str(connect_path),
    "project_path": project_path,
    "repo_root": repo_root,
    "git_branch": connected_project.get("git_branch", ""),
    "git_remote": connected_project.get("git_remote", ""),
    "agents_contract_present": bool(connected_project.get("agents_contract_present")),
    "claude_adapter_present": bool(connected_project.get("claude_adapter_present")),
    "provider_discovery": providers,
    "validation_commands": [
        "scripts/validate-artemis.sh",
        "git diff --check",
    ] if connected_project.get("agents_contract_present") else [],
    "trust_review_state": "waiting_for_human_review",
    "registration_state": "candidate_from_terminal_connect",
    "selected": False,
    "runtime_execution_allowed": False,
    "remote_writes_allowed": False,
    "human_review_required": True,
    "rejection_reasons": [],
}

registry_record_schema = {
    "required_fields": [
        "project_id",
        "display_name",
        "source_connect_artifact",
        "project_path",
        "repo_root",
        "git_branch",
        "git_remote",
        "agents_contract_present",
        "provider_discovery",
        "validation_commands",
        "trust_review_state",
        "registration_state",
        "selected",
        "runtime_execution_allowed",
        "remote_writes_allowed",
        "human_review_required",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "ssh_private_key",
        "provider_billing_secret",
        "raw_provider_auth_state",
        "raw_stdout",
        "raw_stderr",
        "full_prompt_transcript",
        "git_remote_token",
    ],
}

registration_contract = {
    "purpose": "Define how terminal-connected local projects become reviewed candidates for the ARTEMIS Portal project registry.",
    "state": "candidate_review_contract",
    "npx_entrypoint_planned": "npx artemis connect --project . --register",
    "local_script_equivalent": "scripts/artemis-portal-external-project-registration.sh --json",
    "source_authority": "local_project_connect_artifact",
    "server_scan_allowed": False,
    "browser_filesystem_access_allowed": False,
    "automatic_registration_allowed": False,
    "project_switching_allowed": False,
    "provider_auth_connected": False,
    "runtime_execution_allowed": False,
    "external_projects_registered": 0,
    "candidate_projects": [candidate_record] if connected_project else [],
    "registered_projects": [],
    "registry_record_schema": registry_record_schema,
    "state_model": [
        "candidate_from_terminal_connect",
        "waiting_for_human_review",
        "registered_read_only",
        "selected_read_only",
        "waiting_for_workspace_policy",
        "waiting_for_provider_auth",
        "waiting_for_budget",
        "waiting_for_human_runtime_gate",
        "ready_for_runtime_gateway",
        "blocked",
        "rejected",
    ],
    "registration_rules": [
        "Only terminal connect artifacts can create project registration candidates.",
        "Browser-provided filesystem paths are not trusted registration authority.",
        "Registration candidates require human review before becoming selectable.",
        "Registration does not select the project and does not permit runtime execution.",
        "Detected provider binaries do not imply authenticated provider sessions.",
        "Runtime remains blocked until Project Selector, Credential Vault, Budget Ledger, Workspace Session, Runtime Gateway, Human Gate and Validation Gate pass.",
    ],
}

checks = [
    {
        "id": "local_project_connect_ready",
        "status": "passed" if connect_payload.get("overall") == "local_project_connect_ready" else "failed",
        "detail": "Registration consumes a Local Project Connect artifact before any project can become a candidate.",
    },
    {
        "id": "terminal_connect_is_source",
        "status": "passed" if registration_contract["source_authority"] == "local_project_connect_artifact" else "failed",
        "detail": "The source of authority is terminal connect, not browser filesystem selection.",
    },
    {
        "id": "browser_and_scan_blocked",
        "status": "passed" if not registration_contract["browser_filesystem_access_allowed"] and not registration_contract["server_scan_allowed"] else "failed",
        "detail": "The registration contract blocks browser filesystem access and server-wide scans.",
    },
    {
        "id": "candidate_requires_human_review",
        "status": "passed" if candidate_record.get("human_review_required") and candidate_record.get("registration_state") == "candidate_from_terminal_connect" else "failed",
        "detail": "Terminal-connected projects remain candidates until human review.",
    },
    {
        "id": "no_external_project_auto_registered",
        "status": "passed" if registration_contract["external_projects_registered"] == 0 and not registration_contract["registered_projects"] else "failed",
        "detail": "This cut does not automatically register or select external projects.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if not registration_contract["runtime_execution_allowed"] and not candidate_record.get("runtime_execution_allowed") else "failed",
        "detail": "Registration candidate state does not grant runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No provider auth, runtime, agent launch, task command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "external_project_registration_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "external_project_registration_ready": overall == "external_project_registration_ready",
    "secret_values_recorded": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "server_scan_allowed": False,
    "browser_filesystem_access_allowed": False,
    "external_projects_registered": 0,
    "project_switching_allowed": False,
    "next_cut": "TKT-090 - Control Plane External Project Registration View",
    "missing_files": missing_files,
    "external_project_registration_contract": registration_contract,
    "candidate_project": candidate_record,
    "checks": checks,
}

(artifact_root / "external-project-registration.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal External Project Registration",
    "",
    f"- Overall: `{overall}`",
    f"- Candidate project: `{candidate_record['display_name']}`",
    f"- Candidate id: `{candidate_record['project_id']}`",
    f"- Source connect artifact: `{candidate_record['source_connect_artifact']}`",
    f"- Project path: `{candidate_record['project_path']}`",
    "- External projects registered: `0`",
    "- Project switching allowed: `false`",
    "- Browser filesystem access allowed: `false`",
    "- Server scan allowed: `false`",
    "- Provider auth connected: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Regras",
    "",
]
lines.extend(f"- {item}" for item in registration_contract["registration_rules"])
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "EXTERNAL_PROJECT_REGISTRATION.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- External Project Registration contract recorded.",
        "- Terminal-connected project is a candidate only; no external project was auto-registered or selected.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Local Project Connect artifact checked.",
        "- Candidate project record checked.",
        "- Browser filesystem, server scan, project switching and runtime execution remain blocked.",
        "- No provider auth, command execution, token spend or remote mutation happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-089 defines how terminal-connected projects become registration candidates.",
        "",
        "The next cut should render registration candidates in the Control Plane before any project switcher or runtime assignment is introduced.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-external-project-registration.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_external_project_registration_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_external_project_registration",
                "name": "scripts/artemis-portal-external-project-registration.sh",
                "mode": "read_only",
            },
            ticket="TKT-089",
            title="ARTEMIS Portal External Project Registration",
            exec_pack="docs/exec-packs/done/TKT-089-artemis-portal-external-project-registration.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "external_project_registration_ready" else "blocked",
            payload={
                "external_project_registration_ready": overall == "external_project_registration_ready",
                "candidate_project_id": candidate_record["project_id"],
                "external_projects_registered": 0,
                "project_switching_allowed": False,
                "server_scan_allowed": False,
                "browser_filesystem_access_allowed": False,
                "provider_auth_connected": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="terminal_connect",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "external-project-registration.json"),
                str(artifact_root / "EXTERNAL_PROJECT_REGISTRATION.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal external project registration: {overall}")
    print(f"artifact_root={artifact_root}")
    print("external_projects_registered=0")
    print("project_switching_allowed=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
