# ARTEMIS SUBAGENT SOCRATIC ROUTER

Status: `subagent_socratic_router_ready`.

This contract teaches ARTEMIS when to use subagents and which provider lane fits the work. It is intentionally contract-only: no runtime agent is started, no prompt is sent to a provider and no token is spent.

## Provider lanes

### Codex subagents

- Provider: `codex`
- Config surface: `.codex/agents/*.toml or ~/.codex/agents/*.toml`
- Runtime surface: `Codex native subagents and Codex terminal/app-server lanes`
- ARTEMIS rule: Use for high-value engineering slices after Socratic Gate passes and write ownership is explicit.
- Default Human Gate: `remote-write-and-high-risk`
- Best for: complex implementation, code review, test strategy, architecture and verification, longer reasoning with strict repo evidence
- Avoid for: unclear goals, tasks without validation, multiple writers on the same worktree

### Claude Code subagents

- Provider: `claude_code`
- Config surface: `.claude/agents/*.md or ~/.claude/agents/*.md`
- Runtime surface: `Claude Code subagents and SDK/headless lanes`
- ARTEMIS rule: Use for short-to-medium specialist slices with frequent checkpoints and exact handoff expectations.
- Default Human Gate: `remote-write-and-high-risk`
- Best for: repository mapping, framework orientation, medium bounded implementation, documentation and handoff drafting, fast exploration before Codex executes a larger slice
- Avoid for: very long tasks without checkpoints, ambiguous multi-stage ownership, unbounded repository rewrites

### Antigravity CLI subagents

- Provider: `antigravity_cli`
- Config surface: `antigravity CLI subagent definition surface`
- Runtime surface: `Antigravity CLI long-running/asynchronous agent lanes`
- ARTEMIS rule: Use only after inherited scopes are displayed and approved; default to dry-run until permissions are narrow.
- Default Human Gate: `inherited-scope-and-async-runtime`
- Best for: background exploration, isolated long-running checks, asynchronous validation lanes, provider-specific experiments behind dry-run gates
- Avoid for: tasks with broad inherited permissions, secret-bearing workflows, remote writes without explicit human gate, production-adjacent automation

## Socratic Gate

A subagent launch is blocked until these questions have concrete answers:

1. What is the single outcome the subagent must produce? Evidence: one-sentence outcome and artifact name.
2. Why is a subagent better than doing the task in the current session? Evidence: parallelism, isolation, specialist capability or latency reason.
3. What exact files, directories or APIs may the subagent touch? Evidence: read scope, write scope and forbidden scope.
4. Can this task run without depending on another active writer? Evidence: dependency statement and worktree ownership.
5. Which provider fits the task shape and why? Evidence: provider id, model policy and rejection of unsuitable providers.
6. What validation proves the subagent result is acceptable? Evidence: commands, expected outputs and artifact checks.
7. What token, time and concurrency limits apply? Evidence: budget policy, max duration and stop condition.
8. Could this touch secrets, remote state, auth, money, production or inherited broad scopes? Evidence: approval id or explicit dry-run/no-side-effect proof.
9. What should the subagent hand back if it succeeds, fails or gets blocked? Evidence: STATUS, VALIDATION, HANDOFF and blocker escalation format.

## Safety invariants

- One writer per worktree.
- Human Gate before secrets, auth, remote state, production, money or broad inherited scopes.
- Validation evidence before Done Ledger.
- Provider configs and runtime launches are blocked until a later approved cut.

## Official references

- `codex`: https://developers.openai.com/codex/subagents
- `claude_code`: https://code.claude.com/docs/en/sub-agents
- `antigravity_cli`: https://antigravity.google/docs/cli-using
- `antigravity_cli` related: https://antigravity.google/docs/subagents
