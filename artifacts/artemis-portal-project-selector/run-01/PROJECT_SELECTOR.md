# ARTEMIS Portal Project Selector Contract

- Overall: `project_selector_ready`
- Selected project: `ARTEMIS Method Kit`
- Project id: `artemis_method_kit`
- Repo root: `/srv/veri`
- Branch: `main`
- External projects registered: `0`
- Runtime execution allowed: `false`
- Agents started: `false`
- Commands executed: `0`
- Tokens spent: `0`
- Next cut: `TKT-087 - Control Plane Project Selector View`

## Leitura humana

- Este painel esta olhando para o ARTEMIS Method Kit.
- Nenhum projeto externo foi selecionado ainda.
- Antes de rodar Codex, Claude ou outro operador em um produto real, esse produto precisa ser cadastrado e confirmado.

## Operadores vinculados

- `codex_app_server`
- `claude_code`
- `antigravity_cli`

## Checks

- `runtime_gateway_service_ready`: passed - Project Selector consumes the read-only Runtime Gateway Service contract.
- `local_project_contract_present`: passed - Current local ARTEMIS project has agent contract and task source.
- `git_root_detected`: passed - Git root is recorded for the selected local project.
- `operators_bound_to_project`: passed - Registered Runtime Gateway operators are visible but not executable for the selected project.
- `external_projects_not_inferred`: passed - The selector does not scan or register arbitrary server projects.
- `runtime_still_blocked`: passed - Project selection does not grant runtime execution.
- `no_runtime_side_effects`: passed - No worktree, provider auth, agent launch, token spend, command execution or remote mutation happened.
