# ARTEMIS AGENT RUNTIME APPROVAL REQUEST

- Project: `ARTEMIS`
- Task: `TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony`
- Profile: `codex_terminal`
- Runtime: `codex_cli`
- Command surface: `terminal`
- Execute now: `false`
- Runtime execution allowed now: `false`

## Human Gate items

- `decision`: `pending` - Human must choose approved, deferred or rejected with identity, timestamp and reason.
- `model_policy`: `pending` - Human must accept model selection or provide an explicit override policy.
- `budget`: `pending` - Human must set max paid tokens, max agents, max commands, max runtime seconds and stop rule.
- `auth`: `pending` - Human-owned account auth must be confirmed before account-backed runtime.
- `command`: `pending` - Human must record exact command(s); placeholders or partial commands cannot execute.
- `workspace`: `pending` - Human must approve repo, branch/worktree policy, dirty-state policy and write scope.
- `validation`: `pending` - Human must define checks, tests, screenshots or artifacts required before Done.
- `rollback`: `pending` - Human must approve abort path, logs to preserve and retry/handoff rules.
- `remote_write`: `blocked_by_default` - Remote writes remain false unless a later, separate Human Gate authorizes them exactly.
