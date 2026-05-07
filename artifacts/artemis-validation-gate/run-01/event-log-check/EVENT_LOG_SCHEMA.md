# ARTEMIS EVENT LOG SCHEMA

- Schema version: 1
- Events: 38
- Source: scripts/artemis-event-log.sh

## Event Types

- `runner.readiness_checked`: `evt_tkt-013_github_issues_readiness` -> human_gate
- `adapter.contract_recorded`: `evt_tkt-014_codex_app_server_contract` -> done
- `adapter.contract_recorded`: `evt_tkt-015_claude_code_contract` -> done
- `validation.completed`: `evt_validation_gate_current` -> human_gate
- `adapter.contract_recorded`: `evt_tkt-015_claude_code_contract` -> done
- `adapter.contract_recorded`: `evt_tkt-014_codex_app_server_contract` -> done
- `runner.readiness_checked`: `evt_tkt-013_github_issues_readiness` -> human_gate
- `runner.attempt_planned`: `evt_20260504t134153z-2-tkt-020_planned` -> running
- `runner.attempt_completed`: `evt_20260504t134153z-2-tkt-020_completed` -> review
- `runner.attempt_planned`: `evt_20260504t134653z-2-tkt-021_planned` -> running
- `runner.attempt_started`: `evt_20260504t134653z-2-tkt-021_started` -> running
- `runner.attempt_completed`: `evt_20260504t134653z-2-tkt-021_completed` -> review
- `runner.attempt_planned`: `evt_20260504t140934z-2-tkt-022_planned` -> running
- `runner.attempt_started`: `evt_20260504t140934z-2-tkt-022_started` -> running
- `runner.attempt_completed`: `evt_20260504t140934z-2-tkt-022_completed` -> review
- `runner.attempt_planned`: `evt_tkt-903_symphony_bridge` -> running
- `runner.readiness_checked`: `evt_tkt-903_symphony_dispatch_planned` -> ready
- `runner.attempt_planned`: `evt_20260507t133550z-26-tkt-903_planned` -> running
- `runner.attempt_completed`: `evt_20260507t133550z-26-tkt-903_completed` -> review
- `runner.readiness_checked`: `evt_task_symphony_daemon_tick-001` -> planned
- `runner.readiness_checked`: `evt_task_symphony_daemon_tick-002` -> planned
- `validation.completed`: `evt_task_symphony_daemon_completed` -> done
- `validation.completed`: `evt_task_symphony_kernel_idle` -> done
- `validation.completed`: `evt_task_symphony_queue_completed` -> done
- `runner.attempt_planned`: `evt_tkt-947_symphony_queue_bridge` -> running
- `runner.attempt_completed`: `evt_tkt-948_symphony_queue_bridge` -> review
- `validation.completed`: `evt_task_symphony_service_completed` -> review
- `runner.attempt_planned`: `evt_20260504t141956z-2-tkt-023_planned` -> running
- `runner.attempt_started`: `evt_20260504t141956z-2-tkt-023_started` -> running
- `runner.attempt_completed`: `evt_20260504t141956z-2-tkt-023_completed` -> blocked
- `runner.attempt_planned`: `evt_20260504t142001z-2-tkt-023_planned` -> running
- `runner.attempt_started`: `evt_20260504t142001z-2-tkt-023_started` -> running
- `runner.attempt_completed`: `evt_20260504t142001z-2-tkt-023_completed` -> review
- `validation.completed`: `evt_validation_gate_current` -> human_gate
- `adapter.contract_recorded`: `evt_tkt-050_symphony_remote_source` -> review
- `adapter.contract_recorded`: `evt_tkt-051_symphony_remote_intake` -> review
- `approval.resolved`: `evt_tkt-052_symphony_remote_promotion` -> ready
- `adapter.contract_recorded`: `evt_tkt-053_memory_zone` -> done

## Invariants

- Exec Pack remains the task contract.
- Artifacts remain canonical evidence.
- Git remains durable memory.
- Control Plane may consume events but does not become canonical state.
- Human Gate is explicit event data, not hidden UI state.
