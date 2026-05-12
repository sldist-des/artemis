# PROJECT OPERATIONS GRAPH

## Resultado

- Overall: `project_graph_ready`.
- Reason: Project Operations Graph contract is ready.
- Nodes: `21`.
- Edges: `50`.
- Tasks: `70`.
- Events: `57`.

## Nos

- `project:artemis` (project): ARTEMIS.
- `task_set:exec_packs` (task_set): Exec Packs.
- `agent_roles:owners` (agent_roles): Owners and agent roles.
- `gate:human` (gate): Human Gates.
- `validation:gate` (validation): Validation Gate.
- `memory:zone` (memory): Human-AI Memory Zone.
- `artifact:evidence` (artifact_set): Artifacts and evidence.
- `event_log:timeline` (event_log): Canonical event timeline.
- `cost:budget` (cost_guard): Token and runtime budget.
- `runtime:dry_run` (runtime_plan): Agent Runtime Dry-Run.
- `runtime:approval_gate` (human_gate): Agent Runtime Approval Gate.
- `runtime:decision_intake` (human_gate): Agent Runtime Decision Intake.
- `runtime:launcher_preflight` (runtime_preflight): Agent Runtime Launcher Preflight.
- `runtime:launcher_command_plan` (runtime_command_plan): Agent Runtime Launcher Command Plan.
- `runtime:launcher_execution_gate` (runtime_execution_gate): Agent Runtime Launcher Execution Gate.
- `runtime:launcher_supervised_execution` (runtime_supervised_execution): Agent Runtime Launcher Supervised Execution.
- `runtime:execution_result_intake` (runtime_result_intake): Agent Runtime Execution Result Intake.
- `runtime:post_execution_validation_gate` (runtime_post_validation_gate): Agent Runtime Post-Execution Validation Gate.
- `runtime:completion_handoff` (runtime_completion_handoff): Agent Runtime Completion Handoff.
- `runtime:completion_review_gate` (runtime_completion_review_gate): Agent Runtime Completion Review Gate.
- `control_plane:view` (view): Control Plane.

## Arestas

- `project:artemis` --contains--> `task_set:exec_packs`.
- `task_set:exec_packs` --requires_evidence--> `artifact:evidence`.
- `task_set:exec_packs` --assigned_to--> `agent_roles:owners`.
- `task_set:exec_packs` --blocked_by_when_sensitive--> `gate:human`.
- `validation:gate` --verifies--> `task_set:exec_packs`.
- `memory:zone` --provides_context--> `task_set:exec_packs`.
- `memory:zone` --summarizes_history--> `event_log:timeline`.
- `event_log:timeline` --records--> `artifact:evidence`.
- `cost:budget` --constrains_runtime--> `agent_roles:owners`.
- `runtime:dry_run` --declares_budget--> `cost:budget`.
- `runtime:dry_run` --requires_preflight--> `validation:gate`.
- `runtime:dry_run` --requests_human_decision--> `runtime:approval_gate`.
- `runtime:approval_gate` --opens--> `gate:human`.
- `runtime:approval_gate` --requires_budget_approval--> `cost:budget`.
- `runtime:approval_gate` --feeds_decision--> `runtime:decision_intake`.
- `runtime:decision_intake` --requires_validation--> `validation:gate`.
- `runtime:decision_intake` --preserves_budget_limits--> `cost:budget`.
- `runtime:decision_intake` --gates_preflight--> `runtime:launcher_preflight`.
- `runtime:launcher_preflight` --rechecks--> `validation:gate`.
- `runtime:launcher_preflight` --keeps_execution_blocked--> `cost:budget`.
- `runtime:launcher_preflight` --gates_command_plan--> `runtime:launcher_command_plan`.
- `runtime:launcher_command_plan` --declares_validation--> `validation:gate`.
- `runtime:launcher_command_plan` --keeps_execution_blocked--> `cost:budget`.
- `runtime:launcher_command_plan` --gates_execution--> `runtime:launcher_execution_gate`.
- `runtime:launcher_execution_gate` --requires_final_human_confirmation--> `gate:human`.
- `runtime:launcher_execution_gate` --requires_validation--> `validation:gate`.
- `runtime:launcher_execution_gate` --binds_runtime_budget--> `cost:budget`.
- `runtime:launcher_execution_gate` --gates_supervised_execution--> `runtime:launcher_supervised_execution`.
- `runtime:launcher_supervised_execution` --produces_validation_evidence--> `validation:gate`.
- `runtime:launcher_supervised_execution` --spends_budget_only_when_ready--> `cost:budget`.
- `runtime:launcher_supervised_execution` --records_results--> `event_log:timeline`.
- `runtime:launcher_supervised_execution` --feeds_result_intake--> `runtime:execution_result_intake`.
- `runtime:execution_result_intake` --gates_post_execution_validation--> `validation:gate`.
- `runtime:execution_result_intake` --records_actual_spend--> `cost:budget`.
- `runtime:execution_result_intake` --records_result_classification--> `event_log:timeline`.
- `runtime:execution_result_intake` --gates_post_execution_validation--> `runtime:post_execution_validation_gate`.
- `runtime:post_execution_validation_gate` --records_post_execution_validation--> `validation:gate`.
- `runtime:post_execution_validation_gate` --preserves_runtime_budget--> `cost:budget`.
- `runtime:post_execution_validation_gate` --records_validation_result--> `event_log:timeline`.
- `runtime:post_execution_validation_gate` --gates_completion_handoff--> `runtime:completion_handoff`.
- `runtime:completion_handoff` --records_completion_readiness--> `validation:gate`.
- `runtime:completion_handoff` --summarizes_runtime_budget--> `cost:budget`.
- `runtime:completion_handoff` --records_handoff--> `event_log:timeline`.
- `runtime:completion_handoff` --gates_completion_review--> `runtime:completion_review_gate`.
- `runtime:completion_review_gate` --requires_human_acceptance--> `gate:human`.
- `runtime:completion_review_gate` --records_review_readiness--> `validation:gate`.
- `runtime:completion_review_gate` --records_review_gate--> `event_log:timeline`.
- `control_plane:view` --observes--> `project:artemis`.
- `control_plane:view` --shows--> `validation:gate`.
- `control_plane:view` --shows--> `memory:zone`.

## Perguntas operacionais

- Como esta o projeto?
- Quem esta responsavel pelo que?
- O que depende de decisao humana?
- Qual contexto e seguro para agentes?
- Qual custo ou runtime foi ativado?
