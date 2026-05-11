# ARTEMIS Symphony Agent Launch Contract

O Agent Launch Contract e o corte que fica entre o Guided Collaboration e qualquer runtime real de Codex, Claude Code ou agentes futuros.

Ele nao e um launcher. Ele e um contrato de preflight: antes de iniciar agente, o ARTEMIS precisa saber projeto, tarefa, perfil, auth, budget, comando, workspace, rollback e evidencia.

## Principio

- `execute=false` e o padrao.
- Nenhum agente pago, remoto, autenticado ou longo inicia sem decisao humana explicita.
- Git, Exec Packs, Event Log, Validation Gate, artifacts e `AGENTS.md` continuam canonicos.
- O Control Plane pode mostrar e preparar o contrato, mas nao vira autoridade para aprovar Human Gates.

## Gates obrigatorios

- **Project**: repositorio, `AGENTS.md` e fonte canonica precisam estar claros.
- **Task**: objetivo, escopo, risco e evidencia precisam estar em Exec Pack ou artifact equivalente.
- **Auth**: Codex app-server, Claude Code, GitHub e contas pessoais exigem autenticacao humana.
- **Budget**: modelo, max tokens/custo, numero de agentes, tempo maximo e stop rule precisam estar definidos.
- **Command**: a superficie exata de comando precisa ser conhecida antes de runtime.
- **Workspace**: branch, worktree, lock, dirty state e escopo de escrita precisam estar declarados.
- **Validation**: testes, checks, screenshots ou artifacts de aceite precisam existir antes de Done.
- **Rollback**: abort path e artifacts preservados em falha precisam estar definidos.
- **Remote write**: push, PR, issue mutation, deploy e producao ficam bloqueados por padrao.

## Perfis iniciais

- **Codex app-server**: bom para tarefas web/remotas com approvals e artifacts.
- **Claude Code**: bom para mapeamento rapido de diretorio, linguagem e recortes medios.
- **Codex terminal-first**: bom para execucao local com git, validacao ampla e controle fino.
- **Verifier**: bom para validar evidencia e claims antes de handoff.

## Artifact canonico

O script `scripts/artemis-agent-launch-contract.sh` gera:

- `artifacts/artemis-agent-launch-contract/run-01/agent-launch-contract.json`
- `artifacts/artemis-agent-launch-contract/run-01/CONTRACT.md`
- `artifacts/artemis-agent-launch-contract/run-01/STATUS.md`
- `artifacts/artemis-agent-launch-contract/run-01/VALIDATION.md`
- `artifacts/artemis-agent-launch-contract/run-01/HANDOFF.md`
- `artifacts/artemis-agent-launch-contract/run-01/events.json`

## Proximo corte

`TKT-067 - Agent Runtime Post-Execution Validation Gate do ARTEMIS Symphony`
