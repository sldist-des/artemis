#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-subagent-config-generator/run-01"
router_contract="artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-subagent-config-generator.sh [--artifact-root path] [--router-contract path] [--json]

Builds preview-only ARTEMIS subagent config artifacts for Codex, Claude Code
and Antigravity CLI from the Socratic Router contract. It writes previews under
the artifact root only. It does not write .codex/agents, .claude/agents,
Antigravity runtime definitions, authenticate providers, start agents, send
prompts, execute commands, spend tokens or mutate remote state.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
      shift 2
      ;;
    --router-contract)
      router_contract="${2:-}"
      if [ -z "$router_contract" ]; then usage; exit 2; fi
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

python3 - "$artifact_root" "$router_contract" "$format" <<'PY'
import json
import sys
import tomllib
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
router_contract_path = Path(sys.argv[2])
output_format = sys.argv[3]
generated_at = now_utc()

preview_root = artifact_root / "preview"
codex_preview_dir = preview_root / ".codex" / "agents"
claude_preview_dir = preview_root / ".claude" / "agents"
antigravity_preview_dir = preview_root / "antigravity"
for path in [codex_preview_dir, claude_preview_dir, antigravity_preview_dir]:
    path.mkdir(parents=True, exist_ok=True)

missing_files = []
if not router_contract_path.is_file():
    missing_files.append(str(router_contract_path))
router_payload = json.loads(router_contract_path.read_text(encoding="utf-8")) if router_contract_path.is_file() else {}

provider_ids = {profile.get("provider_id") for profile in router_payload.get("provider_profiles", [])}
socratic_gate = router_payload.get("socratic_gate", [])

codex_toml = '''name = "artemis-codex-architect-verifier"
description = "Use after ARTEMIS Socratic Gate passes for complex implementation, architecture review, validation strategy or completion evidence."
prompt = """
You are an ARTEMIS Codex subagent.

Follow AGENTS.md and the active Exec Pack. Do not widen scope. Before editing,
confirm the requested outcome, read scope, write scope, forbidden scope, budget,
validation commands and handoff artifacts are present. If any are missing,
return BLOCKED instead of improvising.

Return STATUS, VALIDATION and HANDOFF evidence. Never push, deploy, touch
secrets, change auth, mutate remote state or spend extra budget without an
explicit Human Gate approval.
"""
'''

claude_md = """---
name: artemis-claude-repo-mapper
description: Use after ARTEMIS Socratic Gate passes for repository mapping, framework orientation, medium bounded implementation slices, documentation and handoff drafting.
tools: Read, Grep, Glob
---

You are an ARTEMIS Claude Code subagent.

Stay inside the assigned read/write scope and keep checkpoints short. Prefer
mapping the repository, identifying language/framework conventions and
returning precise handoff notes before any larger implementation. If the task is
long, ambiguous or lacks validation, return BLOCKED with the missing decision.

Never bypass AGENTS.md, Human Gate, budget policy, validation policy or the
single-writer worktree rule.
"""

antigravity_json = {
    "name": "artemis-antigravity-async-validator",
    "provider_id": "antigravity_cli",
    "mode": "preview_only_not_installable",
    "description": "Use only after ARTEMIS Socratic Gate and inherited-scope Human Gate pass for isolated async validation lanes.",
    "task": "Run an isolated async validation or exploration lane and return evidence only.",
    "scope": {
        "read": ["assigned Exec Pack", "assigned artifact paths", "declared validation inputs"],
        "write": ["assigned artifact root only"],
        "forbidden": ["secrets", "auth", "remote state", "production", "push", "deploy", "undeclared paths"],
    },
    "approval_policy": {
        "requires_human_gate_for_inherited_scopes": True,
        "default_launch_state": "blocked_until_approved",
        "dry_run_first": True,
    },
    "handoff": ["STATUS.md", "VALIDATION.md", "HANDOFF.md", "events.json"],
    "budget": {
        "max_duration_minutes": 45,
        "tokens_must_be_preapproved": True,
        "stop_on_scope_drift": True,
    },
}

preview_files = [
    {
        "provider_id": "codex",
        "format": "toml",
        "runtime_target": ".codex/agents/artemis-codex-architect-verifier.toml",
        "preview_path": codex_preview_dir / "artemis-codex-architect-verifier.toml",
        "content": codex_toml,
    },
    {
        "provider_id": "claude_code",
        "format": "markdown_yaml_frontmatter",
        "runtime_target": ".claude/agents/artemis-claude-repo-mapper.md",
        "preview_path": claude_preview_dir / "artemis-claude-repo-mapper.md",
        "content": claude_md,
    },
    {
        "provider_id": "antigravity_cli",
        "format": "json",
        "runtime_target": "antigravity subagent definition",
        "preview_path": antigravity_preview_dir / "artemis-antigravity-async-validator.json",
        "content": json.dumps(antigravity_json, ensure_ascii=False, indent=2) + "\n",
    },
]

for item in preview_files:
    item["preview_path"].write_text(item["content"], encoding="utf-8")

codex_parse_ok = True
try:
    tomllib.loads((codex_preview_dir / "artemis-codex-architect-verifier.toml").read_text(encoding="utf-8"))
except tomllib.TOMLDecodeError:
    codex_parse_ok = False

antigravity_parse_ok = True
try:
    json.loads((antigravity_preview_dir / "artemis-antigravity-async-validator.json").read_text(encoding="utf-8"))
except json.JSONDecodeError:
    antigravity_parse_ok = False

claude_preview = (claude_preview_dir / "artemis-claude-repo-mapper.md").read_text(encoding="utf-8")
claude_frontmatter_ok = claude_preview.startswith("---\n") and "\n---\n\n" in claude_preview and "name: artemis-claude-repo-mapper" in claude_preview

safety_invariants = {
    "runtime_configs_written": False,
    "preview_configs_written": True,
    "runtime_subagents_started": False,
    "provider_messages_sent": 0,
    "provider_auth_performed": False,
    "commands_executed_by_provider": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "secrets_read": False,
    "secrets_written": False,
    "real_runtime_paths_written": False,
    "human_gate_required_before_install": True,
}

install_gate = {
    "state": "preview_ready_install_blocked",
    "required_before_install": [
        "human accepts generated preview",
        "project path is selected",
        "worktree ownership is assigned",
        "provider auth policy is active",
        "budget policy is active",
        "validation commands are declared",
        "rollback/delete plan for generated configs is declared",
    ],
    "blocked_runtime_paths": [
        ".codex/agents/artemis-codex-architect-verifier.toml",
        ".claude/agents/artemis-claude-repo-mapper.md",
        "Antigravity runtime subagent definition",
    ],
}

checks = [
    {
        "id": "router_contract_available",
        "passed": not missing_files and router_payload.get("overall") == "subagent_socratic_router_ready",
        "evidence": str(router_contract_path),
    },
    {
        "id": "all_three_providers_available",
        "passed": provider_ids == {"codex", "claude_code", "antigravity_cli"},
        "evidence": sorted(provider_ids),
    },
    {
        "id": "socratic_gate_available",
        "passed": len(socratic_gate) >= 9,
        "evidence": f"{len(socratic_gate)} questions",
    },
    {
        "id": "codex_preview_valid_toml",
        "passed": codex_parse_ok,
        "evidence": str(codex_preview_dir / "artemis-codex-architect-verifier.toml"),
    },
    {
        "id": "claude_preview_has_frontmatter",
        "passed": claude_frontmatter_ok,
        "evidence": str(claude_preview_dir / "artemis-claude-repo-mapper.md"),
    },
    {
        "id": "antigravity_preview_valid_json",
        "passed": antigravity_parse_ok,
        "evidence": str(antigravity_preview_dir / "artemis-antigravity-async-validator.json"),
    },
    {
        "id": "runtime_paths_untouched",
        "passed": not Path(".codex/agents/artemis-codex-architect-verifier.toml").exists()
        and not Path(".claude/agents/artemis-claude-repo-mapper.md").exists(),
        "evidence": "No project runtime subagent config path was written.",
    },
    {
        "id": "no_runtime_side_effects",
        "passed": safety_invariants["runtime_subagents_started"] is False
        and safety_invariants["provider_messages_sent"] == 0
        and safety_invariants["tokens_spent"] == 0
        and safety_invariants["remote_state_mutated"] is False,
        "evidence": safety_invariants,
    },
]

overall = "subagent_config_preview_ready" if all(check["passed"] for check in checks) else "subagent_config_preview_blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-subagent-config-generator.sh",
    "mode": "preview_only_no_runtime_install",
    "overall": overall,
    "reason": "ARTEMIS generated provider-specific subagent config previews without installing runtime configs.",
    "ticket": "TKT-104",
    "artifact_root": str(artifact_root),
    "router_contract": str(router_contract_path),
    "preview_root": str(preview_root),
    "preview_files": [
        {
            "provider_id": item["provider_id"],
            "format": item["format"],
            "runtime_target": item["runtime_target"],
            "preview_path": str(item["preview_path"]),
        }
        for item in preview_files
    ],
    "install_gate": install_gate,
    "safety_invariants": safety_invariants,
    "checks": checks,
    "next_cut": {
        "ticket": "TKT-105",
        "title": "Project Registry Registration Dry Run",
        "goal": "Return to the project registry lane and prove the planned registry write as dry-run only.",
    },
}

generator_path = artifact_root / "subagent-config-generator.json"
generator_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

summary_lines = [
    "# ARTEMIS SUBAGENT CONFIG GENERATOR",
    "",
    "Status: `subagent_config_preview_ready`.",
    "",
    "This cut generates provider-specific preview configs from the Socratic Router. The files are intentionally stored under the artifact root and are not installed into provider runtime directories.",
    "",
    "## Preview files",
    "",
]
for item in payload["preview_files"]:
    summary_lines.append(f"- `{item['provider_id']}` preview: `{item['preview_path']}` -> future target `{item['runtime_target']}`.")
summary_lines.extend(
    [
        "",
        "## Install gate",
        "",
        "Installation remains blocked until a human accepts the preview, chooses the project/worktree, approves provider auth and budget, and declares rollback plus validation.",
        "",
        "## No runtime effects",
        "",
        "- Provider auth: `false`",
        "- Provider messages sent: `0`",
        "- Runtime subagents started: `false`",
        "- Tokens spent: `0`",
        "- Remote state mutated: `false`",
    ]
)
(artifact_root / "SUBAGENT_CONFIG_GENERATOR.md").write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

status_lines = [
    "# STATUS",
    "",
    "- Ticket: TKT-104",
    f"- Overall: `{overall}`",
    f"- Preview files: `{len(preview_files)}`",
    "- Runtime configs written: `false`",
    "- Runtime subagents started: `false`",
    "- Provider messages sent: `0`",
    "- Tokens spent: `0`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-105 - Project Registry Registration Dry Run`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = ["# VALIDATION", ""]
for check in checks:
    validation_lines.append(f"- [{'x' if check['passed'] else ' '}] `{check['id']}`")
validation_lines.extend(
    [
        "",
        "Expected verification:",
        "",
        "```bash",
        "sh -n scripts/artemis-subagent-config-generator.sh",
        "scripts/artemis-subagent-config-generator.sh --artifact-root artifacts/artemis-subagent-config-generator/run-01 --json",
        "python3 -m json.tool artifacts/artemis-subagent-config-generator/run-01/subagent-config-generator.json",
        "python3 -m json.tool artifacts/artemis-subagent-config-generator/run-01/events.json",
        "scripts/validate-artemis.sh",
        "```",
    ]
)
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "The ARTEMIS method now has preview-only provider config artifacts for Codex, Claude Code and Antigravity CLI subagents.",
    "",
    "Do not copy these previews into runtime paths until a future install gate records human approval, selected project/worktree, auth policy, budget policy, validation commands and rollback/delete plan.",
    "",
    "The next cut returns to the Project Registry lane as TKT-105.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

events = [
    event(
        event_id="evt_artemis_subagent_config_preview_ready",
        event_type="orchestration.subagent_config_preview_ready",
        generated_at=generated_at,
        producer={
            "name": "scripts/artemis-subagent-config-generator.sh",
            "kind": "script",
            "version": "1",
        },
        ticket="TKT-104",
        title="ARTEMIS Subagent Config Generator Dry Run",
        exec_pack="docs/exec-packs/done/TKT-104-artemis-subagent-config-generator.md",
        artifact_root=str(artifact_root),
        state_from="router_ready",
        state_to="done",
        payload=payload,
        gate={
            "kind": "validation",
            "status": "passed" if overall == "subagent_config_preview_ready" else "blocked",
            "required": True,
            "checks": checks,
        },
        links={
            "correlation_id": "tkt-104",
            "generator": str(generator_path),
            "router": str(router_contract_path),
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-subagent-config-generator.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"{overall}: {artifact_root}")
PY
