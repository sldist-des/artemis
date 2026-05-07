# ARTEMIS AGENT LAUNCH CONTRACT

## Regra central

TKT-058 define o contrato minimo antes de qualquer agente real. Ele nao inicia runtime, nao executa comandos de agente, nao instala dependencias e nao escreve remoto.

## Perfis

- **Codex app-server** (`codex_app_server`): Receber tarefas remotas ou web e manter supervisao por artifacts, approvals e Validation Gate. Execute default: `false`.
- **Claude Code** (`claude_code`): Mapear repositorio, entender linguagem e executar tarefas medias com checkpoints curtos. Execute default: `false`.
- **Codex terminal-first** (`codex_cli`): Atuar como executor principal local quando a tarefa exige controle fino, git e verificacao ampla. Execute default: `false`.
- **Verifier** (`codex_subagent_or_manual_review`): Validar evidencia, testes, logs, screenshots e claims antes de Done ou handoff. Execute default: `false`.

## Gates

- **Project** (`required`): A launch request must name the repository/project and the canonical AGENTS.md contract.
- **Task** (`required`): A launch request must point to an Exec Pack or explicit task artifact with objective, scope and risk.
- **Auth** (`human_required`): Any Codex app-server, Claude Code, GitHub or account-backed runtime requires explicit human authentication.
- **Budget** (`human_required`): Model, max tokens/cost, max agents, max wall time and stop rule must be declared before runtime.
- **Command** (`required`): The exact command surface must be reviewed; launch remains execute=false until the next contract authorizes it.
- **Workspace** (`required`): Agent write scope, branch/worktree, lock and dirty-state policy must be known before execution.
- **Validation** (`required`): The task must name tests, static checks, screenshots or artifacts that prove completion.
- **Rollback** (`required`): A clean abort path and artifacts to preserve on failure must be listed before runtime.
- **Remote write** (`blocked_by_default`): Push, PR, issue mutation, deploy and production writes remain blocked until explicit human approval.

## Evidencia

- **Launch request**: Project, task, runtime profile, budget, auth state, command surface and stop rule are explicit.
- **Preflight**: Contract is internally valid and read-only safety invariants are intact.
- **Runtime logs**: When runtime exists, every agent turn must be tied to task, budget, command and evidence.
- **Handoff**: Next action is known and unresolved gates are visible.
