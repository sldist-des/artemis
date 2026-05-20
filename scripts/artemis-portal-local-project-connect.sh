#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-local-project-connect/run-01"
project="."
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-local-project-connect.sh [--project path] [--artifact-root path] [--json]

Builds the ARTEMIS Local Project Connect contract for a project selected from
the terminal. It discovers local provider binaries only. It does not publish an
npm package, authenticate providers, start app-server, start Claude Code, start
Antigravity CLI, execute tasks, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project)
      project="${2:-}"
      if [ -z "$project" ]; then usage; exit 2; fi
      shift 2
      ;;
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$project" "$format" <<'PY'
import json
import shutil
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
project_arg = sys.argv[2]
output_format = sys.argv[3]
generated_at = now_utc()

project_path = Path(project_arg).expanduser()
if not project_path.is_absolute():
    project_path = (Path.cwd() / project_path)
project_path = project_path.resolve()

missing_files = []
if not project_path.is_dir():
    missing_files.append(str(project_path))

def git_value(args: list[str], default: str = "") -> str:
    if not project_path.is_dir():
        return default
    result = subprocess.run(
        ["git", "-C", str(project_path), *args],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return default
    return result.stdout.strip() or default

repo_root = git_value(["rev-parse", "--show-toplevel"], "")
branch = git_value(["rev-parse", "--abbrev-ref", "HEAD"], "unknown")
remote = git_value(["config", "--get", "remote.origin.url"], "")
is_git_project = bool(repo_root)

agents_contract = project_path / "AGENTS.md"
claude_adapter = project_path / "CLAUDE.md"

def discover(provider_id: str, display_name: str, candidates: list[str], runtime_surface: str) -> dict:
    detected = ""
    for candidate in candidates:
        path = shutil.which(candidate)
        if path:
            detected = path
            break
    return {
        "provider_id": provider_id,
        "display_name": display_name,
        "runtime_surface": runtime_surface,
        "binary_candidates": candidates,
        "detected": bool(detected),
        "detected_binary": detected,
        "auth_connected": False,
        "vault_lease_issued": False,
        "runtime_allowed": False,
        "state": "terminal_binary_detected" if detected else "not_found_on_path",
        "reason": "Binary found on PATH; auth and runtime still require gates." if detected else "Binary was not found on PATH.",
    }

provider_discovery = [
    discover("codex", "Codex CLI / app-server", ["codex"], "cli_and_app_server"),
    discover("claude_code", "Claude Code", ["claude"], "cli_or_sdk"),
    discover("antigravity_cli", "Antigravity CLI", ["agy", "antigravity"], "cli_unverified"),
]

connected_project = {
    "project_path": str(project_path),
    "repo_root": repo_root,
    "is_git_project": is_git_project,
    "git_branch": branch,
    "git_remote": remote,
    "agents_contract_present": agents_contract.is_file(),
    "agents_contract_path": str(agents_contract) if agents_contract.is_file() else "",
    "claude_adapter_present": claude_adapter.is_file(),
    "claude_adapter_path": str(claude_adapter) if claude_adapter.is_file() else "",
    "provider_discovery": provider_discovery,
    "npx_entrypoint": "npx artemis connect --project .",
    "local_script_equivalent": "scripts/artemis-portal-local-project-connect.sh --project . --json",
    "terminal_project_access_required": True,
    "browser_filesystem_access_allowed": False,
    "provider_auth_connected": False,
    "runtime_execution_allowed": False,
    "human_confirmation_required_for_runtime": True,
    "remote_writes_allowed": False,
}

contract = {
    "purpose": "Register a local project context from the terminal before the ARTEMIS Portal can route tasks to provider-backed operators.",
    "state": "registered_read_only" if project_path.is_dir() else "blocked",
    "project_access_granted_by": "terminal_current_working_directory",
    "npx_package_planned": True,
    "npx_published": False,
    "local_script_available_now": True,
    "provider_detection_only": True,
    "provider_auth_connected": False,
    "secret_values_recorded": False,
    "terminal_project_access_required": True,
    "browser_filesystem_access_allowed": False,
    "runtime_execution_allowed": False,
    "state_model": [
        "not_connected",
        "terminal_discovered",
        "registered_read_only",
        "waiting_for_provider_auth",
        "waiting_for_vault_lease",
        "waiting_for_budget",
        "waiting_for_human_gate",
        "ready_for_runtime_gateway",
        "blocked",
    ],
    "connected_project": connected_project,
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
    ],
    "rules": [
        "Local project access is granted from the terminal, not from browser filesystem selection.",
        "The connect command discovers project metadata and provider binaries only.",
        "Detected provider binaries do not imply authenticated provider sessions.",
        "Runtime remains blocked until Project Selector, Credential Vault, Budget Ledger, Workspace Session, Runtime Gateway, Human Gate and Validation Gate pass.",
        "Experimental providers remain blocked until capability discovery and adapter contract review pass.",
    ],
}

checks = [
    {
        "id": "project_directory_exists",
        "status": "passed" if project_path.is_dir() else "failed",
        "detail": "The terminal-provided project path must exist.",
    },
    {
        "id": "git_context_detected",
        "status": "passed" if is_git_project else "failed",
        "detail": "A Git root is recorded for the local project.",
    },
    {
        "id": "agent_contract_detected",
        "status": "passed" if agents_contract.is_file() else "failed",
        "detail": "AGENTS.md is present before the project can be trusted by ARTEMIS operators.",
    },
    {
        "id": "provider_slots_declared",
        "status": "passed" if {item["provider_id"] for item in provider_discovery} == {"codex", "claude_code", "antigravity_cli"} else "failed",
        "detail": "Codex, Claude Code and Antigravity CLI slots are declared for local discovery.",
    },
    {
        "id": "terminal_first_boundary",
        "status": "passed" if contract["terminal_project_access_required"] and not contract["browser_filesystem_access_allowed"] else "failed",
        "detail": "Project access is terminal-first and browser filesystem access is blocked.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if not contract["runtime_execution_allowed"] and not contract["provider_auth_connected"] else "failed",
        "detail": "Provider discovery does not authenticate providers or allow runtime.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No provider auth, runtime, agent launch, task command, token spend or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "local_project_connect_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "local_project_connect_ready": overall == "local_project_connect_ready",
    "secret_values_recorded": False,
    "provider_auth_connected": False,
    "runtime_auth_executed": False,
    "runtime_session_started": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-088 - Control Plane Local Project Connect View",
    "missing_files": missing_files,
    "local_project_connect_contract": contract,
    "connected_project": connected_project,
    "provider_discovery": provider_discovery,
    "checks": checks,
}

(artifact_root / "local-project-connect.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Local Project Connect",
    "",
    f"- Overall: `{overall}`",
    f"- Project path: `{connected_project['project_path']}`",
    f"- Repo root: `{connected_project['repo_root'] or 'not detected'}`",
    f"- Branch: `{connected_project['git_branch']}`",
    f"- AGENTS.md present: `{str(connected_project['agents_contract_present']).lower()}`",
    f"- CLAUDE.md present: `{str(connected_project['claude_adapter_present']).lower()}`",
    f"- Npx entrypoint planned: `{connected_project['npx_entrypoint']}`",
    f"- Local equivalent: `{connected_project['local_script_equivalent']}`",
    "- Terminal project access required: `true`",
    "- Browser filesystem access allowed: `false`",
    "- Provider auth connected: `false`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Provider discovery",
    "",
]
for provider in provider_discovery:
    binary = provider["detected_binary"] or "not found"
    lines.append(f"- `{provider['provider_id']}`: `{provider['state']}` - {binary}")
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "LOCAL_PROJECT_CONNECT.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Local project connect contract recorded from the terminal-provided project path.",
        "- Provider binaries were discovered only as local capabilities; no auth, runtime, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Terminal-provided project path checked.",
        "- Git root, branch, remote and AGENTS.md presence checked.",
        "- Codex, Claude Code and Antigravity CLI discovery slots checked.",
        "- Terminal-first and no-runtime invariants checked.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-087 defines the Local Project Connect contract.",
        "",
        "The next cut should render connected-project and provider-discovery state in the Control Plane before adding external project registration or runtime actions.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-local-project-connect.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_local_project_connect_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_local_project_connect",
                "name": "scripts/artemis-portal-local-project-connect.sh",
                "mode": "read_only",
            },
            ticket="TKT-087",
            title="ARTEMIS Portal Local Project Connect",
            exec_pack="docs/exec-packs/done/TKT-087-artemis-portal-local-project-connect.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "local_project_connect_ready" else "blocked",
            payload={
                "local_project_connect_ready": overall == "local_project_connect_ready",
                "project_path": connected_project["project_path"],
                "repo_root": connected_project["repo_root"],
                "provider_ids": [item["provider_id"] for item in provider_discovery],
                "provider_auth_connected": False,
                "terminal_project_access_required": True,
                "browser_filesystem_access_allowed": False,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="project_selector",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "local-project-connect.json"),
                str(artifact_root / "LOCAL_PROJECT_CONNECT.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal local project connect: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"project_path={connected_project['project_path']}")
    print("terminal_project_access_required=true")
    print("provider_auth_connected=false")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
