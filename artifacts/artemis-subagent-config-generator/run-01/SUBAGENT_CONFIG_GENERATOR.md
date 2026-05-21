# ARTEMIS SUBAGENT CONFIG GENERATOR

Status: `subagent_config_preview_ready`.

This cut generates provider-specific preview configs from the Socratic Router. The files are intentionally stored under the artifact root and are not installed into provider runtime directories.

## Preview files

- `codex` preview: `artifacts/artemis-subagent-config-generator/run-01/preview/.codex/agents/artemis-codex-architect-verifier.toml` -> future target `.codex/agents/artemis-codex-architect-verifier.toml`.
- `claude_code` preview: `artifacts/artemis-subagent-config-generator/run-01/preview/.claude/agents/artemis-claude-repo-mapper.md` -> future target `.claude/agents/artemis-claude-repo-mapper.md`.
- `antigravity_cli` preview: `artifacts/artemis-subagent-config-generator/run-01/preview/antigravity/artemis-antigravity-async-validator.json` -> future target `antigravity subagent definition`.

## Install gate

Installation remains blocked until a human accepts the preview, chooses the project/worktree, approves provider auth and budget, and declares rollback plus validation.

## No runtime effects

- Provider auth: `false`
- Provider messages sent: `0`
- Runtime subagents started: `false`
- Tokens spent: `0`
- Remote state mutated: `false`
