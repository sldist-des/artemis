#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-subagent-socratic-router/run-01"
format="text"

usage() {
  cat >&2 <<'USAGE'
usage: scripts/artemis-subagent-socratic-router.sh [--artifact-root path] [--json]

Builds the ARTEMIS Socratic Subagent Router contract for Codex, Claude Code
and Antigravity CLI. This cut is contract-only: it does not authenticate
providers, create runtime subagent configs, send prompts, start agents, spend
tokens, execute provider commands or mutate remote state.
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

provider_sources = [
    {
        "provider_id": "codex",
        "official_doc": "https://developers.openai.com/codex/subagents",
        "verified_at": "2026-05-21",
        "observed_contract": [
            "project subagents live under .codex/agents/",
            "user subagents live under ~/.codex/agents/",
            "subagents use TOML fields such as name, description, prompt and optional tools",
            "explicit invocation can reference the agent by name",
        ],
    },
    {
        "provider_id": "claude_code",
        "official_doc": "https://code.claude.com/docs/en/sub-agents",
        "verified_at": "2026-05-21",
        "observed_contract": [
            "project subagents live under .claude/agents/",
            "user subagents live under ~/.claude/agents/",
            "subagents are Markdown files with YAML frontmatter",
            "Claude can delegate proactively from descriptions and can be invoked explicitly",
        ],
    },
    {
        "provider_id": "antigravity_cli",
        "official_doc": "https://antigravity.google/docs/cli-using",
        "related_doc": "https://antigravity.google/docs/subagents",
        "verified_at": "2026-05-21",
        "observed_contract": [
            "Antigravity CLI exposes subagent-oriented workflows",
            "subagents can be long-running or asynchronous",
            "subagents inherit parent scopes and permissions",
            "ARTEMIS must treat inherited scopes as a human-gated risk",
        ],
    },
]

socratic_gate = [
    {
        "id": "intent",
        "question": "What is the single outcome the subagent must produce?",
        "blocks_launch_if_empty": True,
        "required_evidence": "one-sentence outcome and artifact name",
    },
    {
        "id": "necessity",
        "question": "Why is a subagent better than doing the task in the current session?",
        "blocks_launch_if_empty": True,
        "required_evidence": "parallelism, isolation, specialist capability or latency reason",
    },
    {
        "id": "bounded_scope",
        "question": "What exact files, directories or APIs may the subagent touch?",
        "blocks_launch_if_empty": True,
        "required_evidence": "read scope, write scope and forbidden scope",
    },
    {
        "id": "independence",
        "question": "Can this task run without depending on another active writer?",
        "blocks_launch_if_false": True,
        "required_evidence": "dependency statement and worktree ownership",
    },
    {
        "id": "provider_fit",
        "question": "Which provider fits the task shape and why?",
        "blocks_launch_if_empty": True,
        "required_evidence": "provider id, model policy and rejection of unsuitable providers",
    },
    {
        "id": "validation",
        "question": "What validation proves the subagent result is acceptable?",
        "blocks_launch_if_empty": True,
        "required_evidence": "commands, expected outputs and artifact checks",
    },
    {
        "id": "budget",
        "question": "What token, time and concurrency limits apply?",
        "blocks_launch_if_empty": True,
        "required_evidence": "budget policy, max duration and stop condition",
    },
    {
        "id": "human_gate",
        "question": "Could this touch secrets, remote state, auth, money, production or inherited broad scopes?",
        "blocks_launch_if_true_without_approval": True,
        "required_evidence": "approval id or explicit dry-run/no-side-effect proof",
    },
    {
        "id": "handoff",
        "question": "What should the subagent hand back if it succeeds, fails or gets blocked?",
        "blocks_launch_if_empty": True,
        "required_evidence": "STATUS, VALIDATION, HANDOFF and blocker escalation format",
    },
]

provider_profiles = [
    {
        "provider_id": "codex",
        "display_name": "Codex subagents",
        "config_surface": ".codex/agents/*.toml or ~/.codex/agents/*.toml",
        "runtime_surface": "Codex native subagents and Codex terminal/app-server lanes",
        "best_for": [
            "complex implementation",
            "code review",
            "test strategy",
            "architecture and verification",
            "longer reasoning with strict repo evidence",
        ],
        "avoid_for": [
            "unclear goals",
            "tasks without validation",
            "multiple writers on the same worktree",
        ],
        "artemis_launch_rule": "Use for high-value engineering slices after Socratic Gate passes and write ownership is explicit.",
        "required_config_fields": ["name", "description", "prompt"],
        "optional_config_fields": ["tools"],
        "default_human_gate": "remote-write-and-high-risk",
    },
    {
        "provider_id": "claude_code",
        "display_name": "Claude Code subagents",
        "config_surface": ".claude/agents/*.md or ~/.claude/agents/*.md",
        "runtime_surface": "Claude Code subagents and SDK/headless lanes",
        "best_for": [
            "repository mapping",
            "framework orientation",
            "medium bounded implementation",
            "documentation and handoff drafting",
            "fast exploration before Codex executes a larger slice",
        ],
        "avoid_for": [
            "very long tasks without checkpoints",
            "ambiguous multi-stage ownership",
            "unbounded repository rewrites",
        ],
        "artemis_launch_rule": "Use for short-to-medium specialist slices with frequent checkpoints and exact handoff expectations.",
        "required_config_fields": ["name", "description"],
        "optional_config_fields": ["tools", "model", "color"],
        "default_human_gate": "remote-write-and-high-risk",
    },
    {
        "provider_id": "antigravity_cli",
        "display_name": "Antigravity CLI subagents",
        "config_surface": "antigravity CLI subagent definition surface",
        "runtime_surface": "Antigravity CLI long-running/asynchronous agent lanes",
        "best_for": [
            "background exploration",
            "isolated long-running checks",
            "asynchronous validation lanes",
            "provider-specific experiments behind dry-run gates",
        ],
        "avoid_for": [
            "tasks with broad inherited permissions",
            "secret-bearing workflows",
            "remote writes without explicit human gate",
            "production-adjacent automation",
        ],
        "artemis_launch_rule": "Use only after inherited scopes are displayed and approved; default to dry-run until permissions are narrow.",
        "required_config_fields": ["name", "task", "scope"],
        "optional_config_fields": ["timeout", "approval_policy"],
        "default_human_gate": "inherited-scope-and-async-runtime",
    },
]

routing_rules = [
    {
        "rule_id": "no_clear_outcome_no_subagent",
        "if": "intent question is unanswered",
        "then": "do not launch; ask the human or refine the Exec Pack",
    },
    {
        "rule_id": "single_writer",
        "if": "the task can write files",
        "then": "assign exactly one writer and one worktree before launch",
    },
    {
        "rule_id": "codex_for_deep_engineering",
        "if": "task is complex, multi-file, validation-heavy or architectural",
        "then": "prefer Codex subagent or Codex terminal owner",
    },
    {
        "rule_id": "claude_for_mapping_and_medium_slices",
        "if": "task is repository mapping, language orientation or bounded medium implementation",
        "then": "prefer Claude Code subagent with short checkpoint",
    },
    {
        "rule_id": "antigravity_for_async_isolated_lanes",
        "if": "task is asynchronous, long-running or provider-specific experiment",
        "then": "prefer Antigravity only with inherited-scope review and dry-run gate",
    },
    {
        "rule_id": "human_gate_for_risk",
        "if": "task touches auth, secrets, remote state, production, money, broad permissions or push",
        "then": "block launch until a recorded human decision exists",
    },
    {
        "rule_id": "validation_before_done",
        "if": "subagent returns changes or claims completion",
        "then": "run validation gate and capture evidence before Done Ledger",
    },
]

safety_invariants = {
    "runtime_subagents_started": False,
    "provider_messages_sent": 0,
    "provider_auth_performed": False,
    "provider_configs_written": False,
    "commands_executed_by_provider": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "secrets_read": False,
    "secrets_written": False,
    "single_writer_required": True,
    "human_gate_required_for_inherited_scopes": True,
    "validation_required_before_done": True,
}

launch_contract = {
    "minimum_fields": [
        "task_id",
        "exec_pack",
        "outcome",
        "provider_id",
        "subagent_profile",
        "read_scope",
        "write_scope",
        "forbidden_scope",
        "budget_policy",
        "timeout_minutes",
        "validation_commands",
        "handoff_artifacts",
        "human_gate_policy",
    ],
    "handoff_artifacts": ["STATUS.md", "VALIDATION.md", "HANDOFF.md", "events.json"],
    "blocked_until_next_cut": [
        "generate concrete .codex/agents/*.toml files",
        "generate concrete .claude/agents/*.md files",
        "generate Antigravity subagent definitions",
        "start provider runtimes from the portal",
        "send prompts to provider agents",
    ],
}

checks = [
    {
        "id": "official_sources_declared",
        "passed": all(item.get("official_doc") for item in provider_sources),
        "evidence": [item["official_doc"] for item in provider_sources],
    },
    {
        "id": "all_three_providers_mapped",
        "passed": {item["provider_id"] for item in provider_profiles}
        == {"codex", "claude_code", "antigravity_cli"},
        "evidence": [item["provider_id"] for item in provider_profiles],
    },
    {
        "id": "socratic_gate_declared",
        "passed": len(socratic_gate) >= 9,
        "evidence": f"{len(socratic_gate)} questions",
    },
    {
        "id": "safety_invariants_declared",
        "passed": safety_invariants["runtime_subagents_started"] is False
        and safety_invariants["provider_messages_sent"] == 0
        and safety_invariants["tokens_spent"] == 0,
        "evidence": safety_invariants,
    },
    {
        "id": "human_gate_for_antigravity_inherited_scopes",
        "passed": any(
            profile["provider_id"] == "antigravity_cli"
            and "inherited" in profile["default_human_gate"]
            for profile in provider_profiles
        ),
        "evidence": "Antigravity profile blocks broad inherited scopes behind Human Gate.",
    },
]

overall = "subagent_socratic_router_ready" if all(check["passed"] for check in checks) else "subagent_socratic_router_blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-subagent-socratic-router.sh",
    "mode": "contract_only_no_runtime",
    "overall": overall,
    "reason": "ARTEMIS can now decide when and how to route subagents across Codex, Claude Code and Antigravity CLI without launching them.",
    "ticket": "TKT-103",
    "artifact_root": str(artifact_root),
    "provider_sources": provider_sources,
    "socratic_gate": socratic_gate,
    "provider_profiles": provider_profiles,
    "routing_rules": routing_rules,
    "launch_contract": launch_contract,
    "safety_invariants": safety_invariants,
    "checks": checks,
    "next_cut": {
        "ticket": "TKT-104",
        "title": "ARTEMIS Subagent Config Generator Dry Run",
        "goal": "Generate preview-only Codex, Claude Code and Antigravity subagent config artifacts from this router contract without writing runtime configs.",
    },
}

router_path = artifact_root / "subagent-socratic-router.json"
router_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

router_md = [
    "# ARTEMIS SUBAGENT SOCRATIC ROUTER",
    "",
    "Status: `subagent_socratic_router_ready`.",
    "",
    "This contract teaches ARTEMIS when to use subagents and which provider lane fits the work. It is intentionally contract-only: no runtime agent is started, no prompt is sent to a provider and no token is spent.",
    "",
    "## Provider lanes",
]
for profile in provider_profiles:
    router_md.extend(
        [
            "",
            f"### {profile['display_name']}",
            "",
            f"- Provider: `{profile['provider_id']}`",
            f"- Config surface: `{profile['config_surface']}`",
            f"- Runtime surface: `{profile['runtime_surface']}`",
            f"- ARTEMIS rule: {profile['artemis_launch_rule']}",
            f"- Default Human Gate: `{profile['default_human_gate']}`",
            "- Best for: " + ", ".join(profile["best_for"]),
            "- Avoid for: " + ", ".join(profile["avoid_for"]),
        ]
    )

router_md.extend(
    [
        "",
        "## Socratic Gate",
        "",
        "A subagent launch is blocked until these questions have concrete answers:",
        "",
    ]
)
for idx, item in enumerate(socratic_gate, start=1):
    router_md.append(f"{idx}. {item['question']} Evidence: {item['required_evidence']}.")

router_md.extend(
    [
        "",
        "## Safety invariants",
        "",
        "- One writer per worktree.",
        "- Human Gate before secrets, auth, remote state, production, money or broad inherited scopes.",
        "- Validation evidence before Done Ledger.",
        "- Provider configs and runtime launches are blocked until a later approved cut.",
        "",
        "## Official references",
        "",
    ]
)
for source in provider_sources:
    router_md.append(f"- `{source['provider_id']}`: {source['official_doc']}")
    if source.get("related_doc"):
        router_md.append(f"- `{source['provider_id']}` related: {source['related_doc']}")

(artifact_root / "SUBAGENT_SOCRATIC_ROUTER.md").write_text("\n".join(router_md) + "\n", encoding="utf-8")

status_lines = [
    "# STATUS",
    "",
    f"- Ticket: TKT-103",
    f"- Overall: `{overall}`",
    "- Runtime subagents started: `false`",
    "- Provider messages sent: `0`",
    "- Tokens spent: `0`",
    "- Provider configs written: `false`",
    "- Remote state mutated: `false`",
    "- Next cut: `TKT-104 - ARTEMIS Subagent Config Generator Dry Run`",
]
(artifact_root / "STATUS.md").write_text("\n".join(status_lines) + "\n", encoding="utf-8")

validation_lines = [
    "# VALIDATION",
    "",
]
for check in checks:
    validation_lines.append(f"- [{'x' if check['passed'] else ' '}] `{check['id']}`")
validation_lines.extend(
    [
        "",
        "Expected verification:",
        "",
        "```bash",
        "sh -n scripts/artemis-subagent-socratic-router.sh",
        "scripts/artemis-subagent-socratic-router.sh --artifact-root artifacts/artemis-subagent-socratic-router/run-01 --json",
        "python3 -m json.tool artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json",
        "python3 -m json.tool artifacts/artemis-subagent-socratic-router/run-01/events.json",
        "scripts/validate-artemis.sh",
        "```",
    ]
)
(artifact_root / "VALIDATION.md").write_text("\n".join(validation_lines) + "\n", encoding="utf-8")

handoff_lines = [
    "# HANDOFF",
    "",
    "The ARTEMIS method now has a provider-aware Socratic Router for subagents.",
    "",
    "Use it before launching Codex, Claude Code or Antigravity CLI subagents. The router must produce an explicit outcome, scope, provider fit, validation plan, budget, stop condition and Human Gate decision before any runtime provider receives work.",
    "",
    "Next cut should generate preview-only config artifacts from this contract. It must still avoid writing `.codex/agents`, `.claude/agents` or Antigravity runtime definitions until the human accepts the generated plan.",
]
(artifact_root / "HANDOFF.md").write_text("\n".join(handoff_lines) + "\n", encoding="utf-8")

events = [
    event(
        event_id="evt_artemis_subagent_socratic_router_ready",
        event_type="orchestration.subagent_router_ready",
        generated_at=generated_at,
        producer={
            "name": "scripts/artemis-subagent-socratic-router.sh",
            "kind": "script",
            "version": "1",
        },
        ticket="TKT-103",
        title="ARTEMIS Subagent Socratic Router",
        exec_pack="docs/exec-packs/done/TKT-103-artemis-subagent-socratic-router.md",
        artifact_root=str(artifact_root),
        state_from="planned",
        state_to="done",
        payload=payload,
        gate={
            "kind": "validation",
            "status": "passed" if overall == "subagent_socratic_router_ready" else "blocked",
            "required": True,
            "checks": checks,
        },
        links={
            "correlation_id": "tkt-103",
            "router": str(router_path),
            "codex_docs": "https://developers.openai.com/codex/subagents",
            "claude_code_docs": "https://code.claude.com/docs/en/sub-agents",
            "antigravity_cli_docs": "https://antigravity.google/docs/cli-using",
        },
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-subagent-socratic-router.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"{overall}: {artifact_root}")
PY
