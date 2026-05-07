# PROJECT OPERATIONS GRAPH

## Resultado

- Overall: `project_graph_ready`.
- Reason: Project Operations Graph contract is ready.
- Nodes: `10`.
- Edges: `12`.
- Tasks: `58`.
- Events: `44`.

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
- `control_plane:view` --observes--> `project:artemis`.
- `control_plane:view` --shows--> `validation:gate`.
- `control_plane:view` --shows--> `memory:zone`.

## Perguntas operacionais

- Como esta o projeto?
- Quem esta responsavel pelo que?
- O que depende de decisao humana?
- Qual contexto e seguro para agentes?
- Qual custo ou runtime foi ativado?
