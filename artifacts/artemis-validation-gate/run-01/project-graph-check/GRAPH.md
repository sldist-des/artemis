# PROJECT OPERATIONS GRAPH

## Resultado

- Overall: `project_graph_ready`.
- Reason: Project Operations Graph contract is ready.
- Nodes: `12`.
- Edges: `17`.
- Tasks: `61`.
- Events: `47`.

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
- `control_plane:view` --observes--> `project:artemis`.
- `control_plane:view` --shows--> `validation:gate`.
- `control_plane:view` --shows--> `memory:zone`.

## Perguntas operacionais

- Como esta o projeto?
- Quem esta responsavel pelo que?
- O que depende de decisao humana?
- Qual contexto e seguro para agentes?
- Qual custo ou runtime foi ativado?
