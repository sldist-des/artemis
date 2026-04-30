# CLAUDE CODE ADAPTER CONTRACT

- Overall: passed
- Reason: Claude Code local contract check passed.
- Claude CLI: /root/.local/bin/claude
- CLAUDE.md role: thin_adapter

## Sources

- https://code.claude.com/docs/en/cli-reference
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/agent-sdk/overview

## Boundary

- AGENTS.md remains canonical.
- CLAUDE.md remains a thin runtime adapter.
- Claude Code is a Runner Adapter, not the owner of ARTEMIS.
- First cut is headless/read-only contract probing.
- Remote control, broad permissions, unreviewed MCP, and bypass permission modes require Human Gate.
- No daemon is introduced in TKT-015.

## Mapping

| Claude Code | ARTEMIS | Rule |
|---|---|---|
| `claude -p / --print` | `supervised_attempt` | Non-interactive Claude Code run maps to one ARTEMIS attempt with artifacts. |
| `--output-format json` | `attempt_result` | Single structured result records duration, cost, turns, error state, and session id when available. |
| `--output-format stream-json` | `event_stream` | Streaming messages become append-only Control Plane and artifact events. |
| `--include-hook-events` | `guardrail_event_stream` | Hook lifecycle events are evidence and may trigger Human Gate. |
| `SessionStart` | `context_load` | Load Exec Pack, AGENTS.md, workflow, and task evidence at session start. |
| `UserPromptSubmit` | `intent_gate` | Validate prompt scope and block secrets or out-of-scope requests before execution. |
| `PreToolUse` | `policy_gate` | Block or ask before risky Bash/Edit/Write/Web/MCP operations. |
| `PostToolUse` | `evidence_event` | Record successful tool effects into artifacts and Control Plane events. |
| `Notification` | `human_gate_signal` | Permission prompts and waiting states become visible Human Gate signals. |
| `Stop / SubagentStop` | `handoff_or_validation_gate` | Stop hooks can block completion until required validation and handoff evidence exist. |
| `subagent / Agent tool` | `specialist_agent` | Specialized Claude subagents remain under AGENTS.md authority and scoped tool permissions. |
| `--worktree` | `workspace_isolation_candidate` | May become a future workspace adapter but does not replace ARTEMIS worktree policy yet. |

## Human Gate Events

- `Notification`
- `UserPromptSubmit:block`
- `PreToolUse:ask`
- `PreToolUse:deny`
- `Stop:block`
- `SubagentStop:block`
- `dangerous_permission_mode_requested`
- `remote_control_requested`

## Blocked or Human Gate Flags

- `--dangerously-skip-permissions`
- `--allow-dangerously-skip-permissions`
- `--remote`
- `--remote-control`
- `--mcp-config with unreviewed server`
- `--allowedTools with broad Bash/Edit/Write`
- `--permission-mode bypassPermissions`
- `--plugin-dir with unreviewed plugins`
