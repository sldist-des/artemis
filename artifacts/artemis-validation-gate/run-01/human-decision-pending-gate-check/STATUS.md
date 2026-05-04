# STATUS

## Resultado

TKT-037 registrou a pausa operacional em Human Gate para decisoes humanas pendentes.

## Estado do gate

- Overall: `human_gate`.
- Pending: `3`.
- Invalid: `0`.
- Approved ready: `0`.
- Executed commands: `0`.
- Cleanup execution allowed: `false`.

## Decisoes pendentes

### TKT-021 - Materializar workspace ARTEMIS controlado

- Estado atual: `pending`.
- Acao necessaria: humano preencher `decision_record`.
- Decisoes validas agora: `approved`, `deferred` ou `rejected`.

Campos obrigatorios:
- `decision_record.decision`
- `decision_record.decided_by`
- `decision_record.decided_at`
- `decision_record.reason`
- `decision_record.approved_commands`

Comandos esperados se aprovado:
- `git worktree remove ../veri-artemis-worktrees/tkt-021`
- `rm .artemis/locks/tkt-021.lock`
- `git branch -d artemis/tkt-021-materializar-workspace-artemis-contr`

### TKT-022 - Executar runner no workspace materializado

- Estado atual: `pending`.
- Acao necessaria: humano preencher `decision_record`.
- Decisoes validas agora: `approved`, `deferred` ou `rejected`.

Campos obrigatorios:
- `decision_record.decision`
- `decision_record.decided_by`
- `decision_record.decided_at`
- `decision_record.reason`
- `decision_record.approved_commands`

Comandos esperados se aprovado:
- `git worktree remove ../veri-artemis-worktrees/tkt-022`
- `rm .artemis/locks/tkt-022.lock`
- `git branch -d artemis/tkt-022-executar-runner-no-workspace-materia`

### TKT-023 - Loop de validacao e fix em workspace isolado

- Estado atual: `pending`.
- Acao necessaria: humano preencher `decision_record`.
- Decisoes validas agora: `approved`, `deferred` ou `rejected`.

Campos obrigatorios:
- `decision_record.decision`
- `decision_record.decided_by`
- `decision_record.decided_at`
- `decision_record.reason`
- `decision_record.approved_commands`

Comandos esperados se aprovado:
- `git worktree remove ../veri-artemis-worktrees/tkt-023`
- `rm .artemis/locks/tkt-023.lock`
- `git branch -d artemis/tkt-023-loop-de-validacao-e-fix-em-workspace`

## Invariantes preservados

- Human Gate is not approval.
- Agents must not fill real-cleanup-decision.json for the human.
- No --execute command is emitted by this gate.
- Pending decisions cannot remove worktrees, locks, or branches.
- Remote writes remain Human Gate.
