#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-workspace-session/run-01"
run_assignment="artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json"
budget_ledger="artifacts/artemis-portal-budget-ledger/run-01/budget-ledger-contract.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-workspace-session.sh [--artifact-root path] [--run-assignment path] [--budget-ledger path] [--json]

Builds the ARTEMIS Portal Workspace Session contract. It does not
authenticate providers, issue vault leases, start agents, execute commands,
spend tokens, create worktrees, change branches, push, deploy or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --run-assignment)
      run_assignment="${2:-}"
      if [ -z "$run_assignment" ]; then usage; exit 2; fi
      shift 2
      ;;
    --budget-ledger)
      budget_ledger="${2:-}"
      if [ -z "$budget_ledger" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$run_assignment" "$budget_ledger" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
run_assignment_path = Path(sys.argv[2])
budget_ledger_path = Path(sys.argv[3])
output_format = sys.argv[4]
generated_at = now_utc()

required_files = [
    Path("docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md"),
    Path("docs/portal/ARTEMIS_PORTAL_BUDGET_LEDGER.md"),
    Path("docs/exec-packs/done/TKT-076-artemis-portal-budget-ledger.md"),
    Path("artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json"),
    Path("artifacts/artemis-portal-budget-ledger/run-01/budget-ledger-contract.json"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

assignment_payload = {}
if run_assignment_path.is_file():
    assignment_payload = json.loads(run_assignment_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(run_assignment_path))

budget_payload = {}
if budget_ledger_path.is_file():
    budget_payload = json.loads(budget_ledger_path.read_text(encoding="utf-8"))
else:
    missing_files.append(str(budget_ledger_path))

sample_assignment = assignment_payload.get("sample_assignment", {})
sample_ledger_entry = budget_payload.get("sample_ledger_entry", {})
workspace_policy_id = sample_assignment.get("workspace_policy_id", "workspace:single-writer-worktree")

session_record_schema = {
    "required_fields": [
        "workspace_session_id",
        "assignment_id",
        "project_id",
        "ticket",
        "agent_profile_id",
        "workspace_policy_id",
        "budget_policy_id",
        "repository_path",
        "worktree_path",
        "branch_policy",
        "writer_lock",
        "allowed_write_roots",
        "forbidden_paths",
        "dirty_worktree_policy",
        "validation_policy_id",
        "opened_at",
        "expires_at",
        "session_state",
        "evidence",
    ],
    "forbidden_fields": [
        "plaintext_secret",
        "raw_access_token",
        "raw_refresh_token",
        "private_key_material",
        "session_cookie",
        "provider_billing_secret",
        "runtime_command_output",
        "git_remote_token",
        "ssh_private_key",
    ],
}

workspace_contract = {
    "purpose": "Bind a portal run assignment and budget ledger to one concrete repository/worktree session before launcher preflight.",
    "state": "contract_only",
    "workspace_session_ready": True,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "actual_cost_units": 0,
    "worktree_created": False,
    "branch_changed": False,
    "remote_state_mutated": False,
    "session_record_schema": session_record_schema,
    "state_model": [
        "requested",
        "assignment_bound",
        "budget_bound",
        "workspace_selecting",
        "lock_pending",
        "locked_for_preflight",
        "dirty_state_review",
        "ready_for_launcher_preflight",
        "released",
        "rejected",
        "expired",
    ],
    "workspace_policies": [
        {
            "workspace_policy_id": "workspace:single-writer-worktree",
            "label": "Single writer worktree",
            "max_writers": 1,
            "requires_writer_lock": True,
            "verifier_requires_separate_session": True,
            "remote_writes_allowed": False,
            "dirty_worktree_policy": "detect_and_report_before_launch",
        },
        {
            "workspace_policy_id": "workspace:read-only-review",
            "label": "Read-only review",
            "max_writers": 0,
            "requires_writer_lock": False,
            "verifier_requires_separate_session": False,
            "remote_writes_allowed": False,
            "dirty_worktree_policy": "read_only_no_changes",
        },
    ],
    "allowed_write_roots": [
        "repository_worktree",
        "artifact_root",
        "tmp_validation_root",
    ],
    "forbidden_paths": [
        ".git/config",
        ".git/hooks",
        ".env",
        ".env.*",
        "secrets/",
        "private/",
        "production/",
        "node_modules/",
        "vendor/",
    ],
    "branch_policy": {
        "base_branch": "main",
        "session_branch": "contract_fixture_no_branch_created",
        "may_create_branch": False,
        "may_push": False,
        "requires_human_gate_for_remote_write": True,
        "requires_clean_or_acknowledged_dirty_state": True,
    },
    "lock_policy": {
        "lock_scope": "project_worktree",
        "one_writer_per_worktree": True,
        "writer_must_release_on_completion": True,
        "stale_lock_requires_human_review": True,
        "lock_file_contains_secrets": False,
    },
    "release_policy": {
        "release_requires_handoff": True,
        "release_requires_validation_result": True,
        "release_records_dirty_state": True,
        "release_may_not_delete_user_changes": True,
    },
    "enforcement_rules": [
        "A Workspace Session must consume an accepted Run Assignment and ready Budget Ledger.",
        "A writer agent requires an exclusive writer lock before launcher preflight.",
        "Verifier agents must use read-only mode or a separate workspace session.",
        "Dirty worktree state must be detected and reported before runtime launch.",
        "Forbidden paths cannot be written by portal-managed agents.",
        "Remote writes, branch protection changes and deploys require separate Human Gate authority.",
        "Workspace approval is not runtime execution permission.",
        "The session record must not contain secrets, provider tokens, private keys or raw command output.",
    ],
}

selected_workspace_policy = next(
    (policy for policy in workspace_contract["workspace_policies"] if policy["workspace_policy_id"] == workspace_policy_id),
    workspace_contract["workspace_policies"][0],
)

sample_workspace_session = {
    "workspace_session_id": "workspace-session-tkt-077-contract-fixture",
    "assignment_id": sample_assignment.get("assignment_id", "assign-tkt-075-contract-fixture"),
    "ledger_entry_id": sample_ledger_entry.get("ledger_entry_id", "cost-tkt-076-contract-fixture"),
    "project_id": sample_assignment.get("project_id", "artemis"),
    "ticket": "TKT-077",
    "source_ticket": sample_assignment.get("ticket", "TKT-075"),
    "agent_profile_id": sample_assignment.get("agent_profile_id", "codex_frontier_engineer"),
    "workspace_policy_id": selected_workspace_policy["workspace_policy_id"],
    "budget_policy_id": sample_ledger_entry.get("budget_policy_id", sample_assignment.get("budget_policy_id", "budget:frontier-engineering")),
    "repository_path": ".",
    "worktree_path": ".",
    "branch_policy": workspace_contract["branch_policy"],
    "writer_lock": {
        "required": selected_workspace_policy["requires_writer_lock"],
        "max_writers": selected_workspace_policy["max_writers"],
        "lock_state": "contract_fixture_not_acquired",
        "lock_owner": "none",
    },
    "allowed_write_roots": workspace_contract["allowed_write_roots"],
    "forbidden_paths": workspace_contract["forbidden_paths"],
    "dirty_worktree_policy": selected_workspace_policy["dirty_worktree_policy"],
    "validation_policy_id": sample_assignment.get("validation_policy_id", "validation:standard-plus"),
    "opened_at": generated_at,
    "expires_at": "contract_fixture_no_runtime_expiry",
    "session_state": "ready_for_launcher_preflight",
    "runtime_execution_allowed": False,
    "remote_writes_allowed": False,
    "worktree_created": False,
    "branch_changed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "evidence": [
        "artifacts/artemis-portal-workspace-session/run-01/workspace-session-contract.json",
        "artifacts/artemis-portal-workspace-session/run-01/WORKSPACE_SESSION.md",
    ],
}

checks = [
    {
        "id": "run_assignment_ready",
        "status": "passed" if assignment_payload.get("overall") == "assignment_ready" else "failed",
        "detail": "Workspace Session consumes an accepted Run Assignment.",
    },
    {
        "id": "budget_ledger_ready",
        "status": "passed" if budget_payload.get("overall") == "budget_ledger_ready" else "failed",
        "detail": "Workspace Session consumes a ready Budget Ledger before runtime spend.",
    },
    {
        "id": "workspace_policy_bound",
        "status": "passed" if workspace_policy_id == selected_workspace_policy["workspace_policy_id"] else "failed",
        "detail": "Assignment workspace policy resolves to a concrete workspace policy.",
    },
    {
        "id": "single_writer_lock_declared",
        "status": "passed" if selected_workspace_policy["max_writers"] <= 1 else "failed",
        "detail": "Writer sessions are constrained to one writer per worktree.",
    },
    {
        "id": "write_scope_declared",
        "status": "passed" if workspace_contract["allowed_write_roots"] and workspace_contract["forbidden_paths"] else "failed",
        "detail": "Allowed write roots and forbidden paths are declared.",
    },
    {
        "id": "no_runtime_execution",
        "status": "passed" if not sample_workspace_session["runtime_execution_allowed"] and sample_workspace_session["commands_executed"] == 0 else "failed",
        "detail": "This cut records workspace policy only and cannot start runtime.",
    },
    {
        "id": "no_remote_mutation",
        "status": "passed" if not sample_workspace_session["remote_writes_allowed"] and not workspace_contract["branch_policy"]["may_push"] else "failed",
        "detail": "Remote writes remain blocked until an explicit Human Gate.",
    },
    {
        "id": "no_secret_values_recorded",
        "status": "passed",
        "detail": "No provider secrets, project secrets, SSH keys or raw command output are stored.",
    },
]

failed_checks = [item for item in checks if item["status"] != "passed"]
overall = "workspace_session_ready" if not missing_files and not failed_checks else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "workspace_session_ready": overall == "workspace_session_ready",
    "secret_values_recorded": False,
    "runtime_auth_executed": False,
    "vault_lease_issued": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "estimated_cost_units": 0,
    "actual_cost_units": 0,
    "worktree_created": False,
    "branch_changed": False,
    "remote_state_mutated": False,
    "next_cut": "TKT-078 - ARTEMIS Portal Runtime Session Contract",
    "missing_files": missing_files,
    "workspace_contract": workspace_contract,
    "sample_workspace_session": sample_workspace_session,
    "checks": checks,
}

(artifact_root / "workspace-session-contract.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Workspace Session Contract",
    "",
    f"- Overall: `{overall}`",
    "- Runtime auth executed: `false`",
    "- Vault lease issued: `false`",
    "- Agents started: `false`",
    "- Commands executed: `0`",
    "- Tokens spent: `0`",
    "- Worktree created: `false`",
    "- Branch changed: `false`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-078 - ARTEMIS Portal Runtime Session Contract`",
    "",
    "## Regra central",
    "",
    "Nenhum assignment pode chegar ao launcher sem uma sessao de workspace que declare repositorio, worktree, branch policy, writer lock, allowed write roots, forbidden paths e dirty-worktree policy.",
    "",
    "## Selected workspace policy",
    "",
    f"- Workspace policy: `{selected_workspace_policy['workspace_policy_id']}`",
    f"- Max writers: `{selected_workspace_policy['max_writers']}`",
    f"- Requires writer lock: `{str(selected_workspace_policy['requires_writer_lock']).lower()}`",
    f"- Remote writes allowed: `{str(selected_workspace_policy['remote_writes_allowed']).lower()}`",
    f"- Dirty worktree policy: `{selected_workspace_policy['dirty_worktree_policy']}`",
    "",
    "## Session required fields",
    "",
]
for field in session_record_schema["required_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Forbidden fields", ""])
for field in session_record_schema["forbidden_fields"]:
    lines.append(f"- `{field}`")

lines.extend(["", "## Allowed write roots", ""])
for root_name in workspace_contract["allowed_write_roots"]:
    lines.append(f"- `{root_name}`")

lines.extend(["", "## Forbidden paths", ""])
for forbidden_path in workspace_contract["forbidden_paths"]:
    lines.append(f"- `{forbidden_path}`")

lines.extend(["", "## Enforcement rules", ""])
for rule in workspace_contract["enforcement_rules"]:
    lines.append(f"- {rule}")

lines.extend(["", "## Validation", ""])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "WORKSPACE_SESSION.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Workspace Session contract recorded.",
        "- No provider auth, vault lease, worktree creation, branch change, command execution, agent runtime, token spend or remote write executed.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Run Assignment artifact checked.",
        "- Budget Ledger artifact checked.",
        "- Workspace policy, session schema, writer lock, write scope, forbidden paths, branch policy and release policy defined.",
        "- No secrets, runtime auth, vault lease, worktree creation, branch change, command execution, agent launch, token spend or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-077 defines the ARTEMIS Portal Workspace Session contract.",
        "",
        "The next cut should define the Portal Runtime Session contract that binds workspace, budget, auth lease and launcher preflight into a supervised execution session without bypassing Human Gates.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-workspace-session.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_workspace_session_contract_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_workspace_session",
                "name": "scripts/artemis-portal-workspace-session.sh",
                "mode": "read_only",
            },
            ticket="TKT-077",
            title="ARTEMIS Portal Workspace Session Contract",
            exec_pack="docs/exec-packs/done/TKT-077-artemis-portal-workspace-session.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "workspace_session_ready" else "blocked",
            payload={
                "workspace_session_ready": overall == "workspace_session_ready",
                "workspace_session_id": sample_workspace_session["workspace_session_id"],
                "workspace_policy_id": selected_workspace_policy["workspace_policy_id"],
                "assignment_id": sample_workspace_session["assignment_id"],
                "budget_policy_id": sample_workspace_session["budget_policy_id"],
                "writer_lock_required": selected_workspace_policy["requires_writer_lock"],
                "max_writers": selected_workspace_policy["max_writers"],
                "runtime_auth_executed": False,
                "vault_lease_issued": False,
                "worktree_created": False,
                "branch_changed": False,
                "agents_started": False,
                "commands_executed": 0,
                "tokens_spent": 0,
                "secret_values_recorded": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[
                str(artifact_root / "workspace-session-contract.json"),
                str(artifact_root / "WORKSPACE_SESSION.md"),
            ],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal workspace session: {overall}")
    print(f"artifact_root={artifact_root}")
    print("worktree_created=false")
    print("branch_changed=false")
    print("remote_state_mutated=false")
PY
