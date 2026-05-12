#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-portal-auth-plan/run-01"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-portal-auth-plan.sh [--artifact-root path] [--json]

Builds the ARTEMIS Portal auth and agent-management architecture contract.
It does not authenticate users, request tokens, store credentials, start
agents, mutate GitHub, or contact Codex/Claude runtimes.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
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

python3 - "$artifact_root" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
output_format = sys.argv[2]
generated_at = now_utc()

required_files = [
    Path("AGENTS.md"),
    Path("ARTEMIS_WORKFLOW.md"),
    Path("ARTEMIS_INTEGRATIONS.md"),
    Path("docs/control-plane/artemis-control-plane.md"),
    Path("docs/symphony/ARTEMIS_SYMPHONY_AGENT_LAUNCH_CONTRACT.md"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

portal_auth = {
    "portal_identity": {
        "purpose": "Authenticate humans before they can see projects, connect providers, launch agents or approve gates.",
        "provider_options": ["Auth0", "Clerk", "Supabase Auth", "Keycloak", "custom OIDC"],
        "required_capabilities": [
            "organization/team membership",
            "role mapping",
            "MFA support",
            "session expiry",
            "audit log identity",
            "SCIM/SAML optional enterprise path",
        ],
    },
    "roles": [
        {
            "id": "owner",
            "can": ["manage billing", "connect providers", "manage projects", "approve high-risk gates"],
        },
        {
            "id": "maintainer",
            "can": ["connect project repos", "create tasks", "launch approved agents", "approve medium-risk gates"],
        },
        {
            "id": "reviewer",
            "can": ["review diffs", "approve technical review gates", "request changes"],
        },
        {
            "id": "operator",
            "can": ["create tasks", "start low-risk supervised runs", "view cost ledger"],
        },
        {
            "id": "viewer",
            "can": ["view projects", "view events", "view handoffs"],
        },
    ],
    "provider_connections": [
        {
            "id": "openai_codex",
            "display_name": "OpenAI / Codex",
            "adapter": "codex_app_server",
            "auth_modes": [
                "Codex app-server ChatGPT/browser auth where supported",
                "device-code flow where supported",
                "API key or service credential for API-backed paths",
                "external bearer token only behind explicit enterprise policy",
            ],
            "token_owner": "user_or_organization",
            "never_expose_to_agent": True,
        },
        {
            "id": "anthropic_claude",
            "display_name": "Anthropic / Claude Code",
            "adapter": "claude_agent_sdk",
            "auth_modes": [
                "ANTHROPIC_API_KEY",
                "Amazon Bedrock credential",
                "Google Vertex AI credential",
                "enterprise provider credential",
            ],
            "token_owner": "user_or_organization",
            "never_expose_to_agent": True,
        },
        {
            "id": "github",
            "display_name": "GitHub",
            "adapter": "github_app_or_oauth",
            "auth_modes": ["GitHub App", "OAuth app", "fine-grained PAT only as fallback"],
            "token_owner": "user_or_organization",
            "never_expose_to_agent": True,
        },
    ],
    "credential_vault": {
        "state": "planned_required",
        "rules": [
            "encrypt provider tokens at rest",
            "bind credentials to user/team/project scopes",
            "inject short-lived runtime tokens only into supervised adapters",
            "never write secrets into Exec Packs, artifacts, logs or prompts",
            "support rotation, revocation and expiry",
            "record audit entries for read, use, refresh and revoke",
            "block provider use when budget, scope or policy is missing",
        ],
    },
    "agent_management": {
        "registry_entities": [
            "agent profile",
            "runner adapter",
            "capability policy",
            "project binding",
            "budget policy",
            "validation policy",
            "human gate policy",
        ],
        "agent_states": [
            "draft",
            "ready",
            "waiting_for_auth",
            "waiting_for_budget",
            "waiting_for_human_gate",
            "running",
            "validating",
            "blocked",
            "handoff",
            "done",
        ],
    },
    "mandatory_gates": [
        "portal_login",
        "provider_connected",
        "project_bound",
        "credential_scope_checked",
        "budget_policy_checked",
        "agent_launch_approved",
        "workspace_scope_checked",
        "remote_write_approved",
        "validation_gate_passed",
        "completion_review_accepted",
    ],
    "cost_controls": {
        "required": True,
        "dimensions": ["organization", "project", "user", "provider", "model", "agent", "task", "run"],
        "limits": ["max_tokens", "max_cost", "max_wall_time", "max_parallel_agents", "stop_rule"],
    },
}

checks = [
    {
        "id": "portal_identity_separated",
        "status": "passed",
        "detail": "Portal auth, provider auth and project/runtime auth are separate layers.",
    },
    {
        "id": "vault_required",
        "status": "passed",
        "detail": "Provider credentials require vault storage and scoped injection; agents never receive raw long-lived secrets.",
    },
    {
        "id": "human_gates_preserved",
        "status": "passed",
        "detail": "Provider connection, agent launch, remote write and completion acceptance remain Human Gate surfaces.",
    },
    {
        "id": "no_runtime_auth_executed",
        "status": "passed",
        "detail": "This cut does not authenticate Codex, Claude, GitHub or any provider.",
    },
]

overall = "architecture_ready" if not missing_files else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "overall": overall,
    "portal_auth_ready": not missing_files,
    "runtime_auth_executed": False,
    "secrets_written": False,
    "remote_state_mutated": False,
    "next_cut": "TKT-073 - ARTEMIS Portal Credential Vault Contract",
    "missing_files": missing_files,
    "portal_auth": portal_auth,
    "checks": checks,
    "sources": [
        {
            "name": "OpenAI Codex app-server",
            "url": "https://developers.openai.com/codex/app-server",
            "reason": "Codex portal/runtime auth and app-server integration surface.",
        },
        {
            "name": "Anthropic Claude Agent SDK",
            "url": "https://code.claude.com/docs/en/agent-sdk/overview",
            "reason": "Claude Code SDK credential and runner integration surface.",
        },
    ],
}

(artifact_root / "portal-auth-plan.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

lines = [
    "# ARTEMIS Portal Auth Plan",
    "",
    f"- Overall: `{overall}`",
    "- Runtime auth executed: `false`",
    "- Secrets written: `false`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-073 - ARTEMIS Portal Credential Vault Contract`",
    "",
    "## Auth layers",
    "",
    "1. Portal auth: human user, organization, team, role and session.",
    "2. Provider auth: OpenAI/Codex, Anthropic/Claude, GitHub and infra credentials.",
    "3. Project/runtime auth: repository, worktree, deployment, database and secrets scope.",
    "",
    "## Provider connections",
    "",
]

for provider in portal_auth["provider_connections"]:
    lines.append(f"- `{provider['id']}` via `{provider['adapter']}`: {', '.join(provider['auth_modes'])}.")

lines.extend([
    "",
    "## Credential vault rules",
    "",
])
for rule in portal_auth["credential_vault"]["rules"]:
    lines.append(f"- {rule}.")

lines.extend([
    "",
    "## Mandatory gates",
    "",
])
for gate in portal_auth["mandatory_gates"]:
    lines.append(f"- `{gate}`")

lines.extend([
    "",
    "## Validation",
    "",
])
for check in checks:
    lines.append(f"- `{check['id']}`: {check['status']} - {check['detail']}")

(artifact_root / "PORTAL_AUTH_PLAN.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Portal auth contract recorded.",
        "- Runtime authentication remains disabled.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        "- Required local docs checked.",
        "- Portal/provider/project auth layers separated.",
        "- Credential Vault required before runtime auth.",
        "- No secrets, provider tokens or remote writes produced.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-072 defines the ARTEMIS Portal authentication and agent-management architecture.",
        "",
        "The next implementation cut should define the Credential Vault contract before any real provider login or token storage.",
    ]) + "\n",
    encoding="utf-8",
)

events = event_log(
    source="scripts/artemis-portal-auth-plan.sh",
    generated_at=generated_at,
    events=[
        event(
            event_id="evt_portal_auth_plan_recorded",
            event_type="adapter.contract_recorded",
            generated_at=generated_at,
            producer={
                "adapter": "portal_auth_plan",
                "name": "scripts/artemis-portal-auth-plan.sh",
                "mode": "read_only",
            },
            ticket="TKT-072",
            title="ARTEMIS Portal Auth Plan",
            exec_pack="docs/exec-packs/done/TKT-072-artemis-portal-auth-plan.md",
            artifact_root=str(artifact_root),
            state_to="done" if overall == "architecture_ready" else "blocked",
            payload={
                "portal_auth_ready": not missing_files,
                "runtime_auth_executed": False,
                "secrets_written": False,
                "remote_state_mutated": False,
                "next_cut": payload["next_cut"],
            },
            state_from="context",
            runner={"kind": "none"},
            severity="info",
            logs=[str(artifact_root / "portal-auth-plan.json"), str(artifact_root / "PORTAL_AUTH_PLAN.md")],
        )
    ],
)
write_event_log(artifact_root / "events.json", events)

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS portal auth plan: {overall}")
    print(f"artifact_root={artifact_root}")
    print("runtime_auth_executed=false")
    print("secrets_written=false")
PY
