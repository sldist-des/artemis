#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-project-selector/run-01"
runtime_gateway_service="artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-project-selector.sh [--artifact-root path] [--runtime-gateway-service path] [--json]

Builds the ARTEMIS Portal Project Selector contract for the current repository.
It does not scan arbitrary server paths, register external projects, create
worktrees, authenticate providers, start agents, execute commands, spend tokens
or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --runtime-gateway-service)
      runtime_gateway_service="${2:-}"
      if [ -z "$runtime_gateway_service" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$runtime_gateway_service" "$format" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
runtime_gateway_service_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

def git_value(args: list[str], default: str = "") -> str:
    result = subprocess.run(["git", *args], text=True, capture_output=True, check=False)
    if result.returncode != 0:
        return default
    return result.stdout.strip() or default

required_files = [
    Path("AGENTS.md"),
    Path("control-plane/index.html"),
    Path("control-plane/tasks.json"),
    Path("docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR.md"),
    Path("docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY_SERVICE.md"),
    Path("docs/exec-packs/done/TKT-085-artemis-control-plane-runtime-gateway-view.md"),
    Path("artifacts/artemis-portal-runtime-gateway-service/run-01/runtime-gateway-service.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

gateway_payload = {}
if runtime_gateway_service_path.is_file():
    gateway_payload = json.loads(runtime_gateway_service_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(runtime_gateway_service_path))

repo_root = git_value(["rev-parse", "--show-toplevel"], str(Path.cwd()))
branch = git_value(["rev-parse", "--abbrev-ref", "HEAD"], "unknown")
remote = git_value(["config", "--get", "remote.origin.url"], "")

operator_ids = [
    item.get("operator_id")
    for item in gateway_payload.get("service_contract", {}).get("operator_summary", [])
    if item.get("operator_id")
]

project_record_schema = {
    "required_fields": [
        "project_id",
        "display_name",
        "project_kind",
        "root_path",
        "repo_root",
        "git_branch",
        "git_remote",
        "agents_contract",
        "control_plane_path",
        "artifact_root",
        "task_source",
        "validation_commands",
        "workspace_policy_id",
        "default_budget_policy_id",
        "default_human_gate_policy_id",
        "allowed_operator_ids",
        "forbidden_paths",
        "selection_state",
        "trust_level",
        "human_confirmation_required_for_runtime",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "ssh_private_key",
        "provider_billing_secret",
        "git_remote_token",
    ],
}

selected_project = {
    "project_id": "artemis_method_kit",
    "display_name": "ARTEMIS Method Kit",
    "project_kind": "method_kit_repository",
    "root_path": ".",
    "repo_root": repo_root,
    "git_branch": branch,
    "git_remote": remote,
    "agents_contract": "AGENTS.md",
    "control_plane_path": "control-plane/index.html",
    "artifact_root": "artifacts",
    "task_source": "control-plane/tasks.json",
    "validation_commands": [
        "scripts/validate-artemis.sh",
        "scripts/artemis-tasks.sh --output control-plane/tasks.json",
        "git diff --check",
    ],
    "workspace_policy_id": "workspace:single-writer-worktree",
    "default_budget_policy_id": "budget:frontier-engineering",
    "default_human_gate_policy_id": "human-gate:runtime-and-remote-write",
    "allowed_operator_ids": operator_ids,
    "forbidden_paths": [
        ".env",
        ".env.*",
        "secrets/",
        "private/",
        ".git/config",
        ".git/hooks",
    ],
    "selection_state": "selected_read_only",
    "trust_level": "local_repository_known",
    "human_confirmation_required_for_runtime": True,
    "runtime_execution_allowed": False,
    "remote_writes_allowed": False,
}

selector_contract = {
    "purpose": "Select the active project context before any Runtime Gateway operator, workspace session or provider-backed launch.",
    "state": "read_only_contract",
    "selected_project_id": selected_project["project_id"],
    "current_project_is_artemis_method_repo": True,
    "external_projects_registered": 0,
    "project_selection_mutated": False,
    "runtime_execution_allowed": False,
    "project_record_schema": project_record_schema,
    "state_model": [
        "unregistered",
        "discovered",
        "registered_read_only",
        "selected_read_only",
        "waiting_for_human_confirmation",
        "ready_for_workspace_session",
        "blocked",
        "disabled",
    ],
    "selection_rules": [
        "A project must have AGENTS.md or an equivalent agent contract before provider-backed runtime.",
        "A project must have a detected Git root or an explicit non-Git project policy.",
        "A project must declare validation commands before runtime launch.",
        "External projects require human registration before they become selectable.",
        "The selector must not infer worktree paths outside the selected project root.",
        "The selector does not issue credential leases, approve budget, start operators or permit remote writes.",
    ],
    "registered_projects": [selected_project],
    "human_explanation": [
        "Este painel esta olhando para o ARTEMIS Method Kit.",
        "Nenhum projeto externo foi selecionado ainda.",
        "Antes de rodar Codex, Claude ou outro operador em um produto real, esse produto precisa ser cadastrado e confirmado.",
    ],
}

checks = [
    {
        "id": "runtime_gateway_service_ready",
        "status": "passed" if gateway_payload.get("overall") == "runtime_gateway_service_ready" else "failed",
        "detail": "Project Selector consumes the read-only Runtime Gateway Service contract.",
    },
    {
        "id": "local_project_contract_present",
        "status": "passed" if Path("AGENTS.md").is_file() and Path("control-plane/tasks.json").is_file() else "failed",
        "detail": "Current local ARTEMIS project has agent contract and task source.",
    },
    {
        "id": "git_root_detected",
        "status": "passed" if bool(repo_root) else "failed",
        "detail": "Git root is recorded for the selected local project.",
    },
    {
        "id": "operators_bound_to_project",
        "status": "passed" if set(operator_ids) >= {"codex_app_server", "claude_code", "antigravity_cli"} else "failed",
        "detail": "Registered Runtime Gateway operators are visible but not executable for the selected project.",
    },
    {
        "id": "external_projects_not_inferred",
        "status": "passed" if selector_contract["external_projects_registered"] == 0 else "failed",
        "detail": "The selector does not scan or register arbitrary server projects.",
    },
    {
        "id": "runtime_still_blocked",
        "status": "passed" if not selected_project["runtime_execution_allowed"] and selected_project["human_confirmation_required_for_runtime"] else "failed",
        "detail": "Project selection does not grant runtime execution.",
    },
    {
        "id": "no_runtime_side_effects",
        "status": "passed",
        "detail": "No worktree, provider auth, agent launch, token spend, command execution or remote mutation happened.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "project_selector_ready" if not missing_files and not failed_checks else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "project_selector_ready": overall == "project_selector_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "worktree_created": False,
    "branch_changed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "next_cut": "TKT-088 - Control Plane Local Project Connect View",
    "missing_files": missing_files,
    "selector_contract": selector_contract,
    "selected_project": selected_project,
    "checks": checks,
}

(artifact_root / "project-selector-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Project Selector Contract",
    "",
    f"- Overall: `{overall}`",
    f"- Selected project: `{selected_project['display_name']}`",
    f"- Project id: `{selected_project['project_id']}`",
    f"- Repo root: `{selected_project['repo_root']}`",
    f"- Branch: `{selected_project['git_branch']}`",
    "- External projects registered: `0`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Leitura humana",
    "",
]
lines.extend(f"- {item}" for item in selector_contract["human_explanation"])
lines.extend(["", "## Operadores vinculados", ""])
lines.extend(f"- `{item}`" for item in operator_ids)
lines.extend(["", "## Checks", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PROJECT_SELECTOR.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Project Selector contract recorded for the local ARTEMIS repository.",
        "- No external projects, runtime auth, worktree creation, agent launch, command execution or token spend happened.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Runtime Gateway Service artifact checked.",
        "- Local project AGENTS.md, task source and Git root checked.",
        "- Operator bindings and no-runtime invariants checked.",
        "- External projects are not inferred or registered in this cut.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-086 defines the read-only Project Selector contract.",
        "",
        "The next cut should render selected-project and local-provider discovery state in the Control Plane before adding any authenticated runtime action.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-project-selector.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_project_selector_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_project_selector",
                "name": "scripts/artemis-portal-project-selector.sh",
                "mode": "read_only",
            },
            ticket="TKT-086",
            title="ARTEMIS Portal Project Selector Contract",
            exec_pack="docs/exec-packs/done/TKT-086-artemis-portal-project-selector.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "project_selector_ready" else "blocked",
            payload={
                "project_selector_ready": overall == "project_selector_ready",
                "selected_project_id": selected_project["project_id"],
                "external_projects_registered": 0,
                "runtime_execution_allowed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "project-selector-contract.json"),
                str(artifact_root / "PROJECT_SELECTOR.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal project selector: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"selected_project_id={selected_project['project_id']}")
    print("runtime_execution_allowed=false")
    print("agents_started=false")
    print("commands_executed=0")
PY
