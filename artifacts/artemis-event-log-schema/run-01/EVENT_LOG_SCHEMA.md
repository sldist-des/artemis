# ARTEMIS EVENT LOG SCHEMA

- Schema version: 1
- Events: 5
- Source: scripts/artemis-event-log.sh

## Event Types

- `task.discovered`: `evt_tkt-019_task_discovered` -> ready
- `runner.readiness_checked`: `evt_tkt-013_github_issues_readiness` -> human_gate
- `adapter.contract_recorded`: `evt_tkt-014_codex_app_server_contract` -> done
- `adapter.contract_recorded`: `evt_tkt-015_claude_code_contract` -> done
- `validation.completed`: `evt_validation_gate_current` -> human_gate

## Invariants

- Exec Pack remains the task contract.
- Artifacts remain canonical evidence.
- Git remains durable memory.
- Control Plane may consume events but does not become canonical state.
- Human Gate is explicit event data, not hidden UI state.
