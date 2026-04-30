# ARTEMIS Workspace Manager

O Workspace Manager define como uma tarefa ARTEMIS ganha um espaco de execucao isolado sem perder controle humano.

## Contrato

Cada tarefa elegivel recebe um plano de workspace com:

- branch planejada;
- worktree planejado;
- lock de escritor unico;
- artifact root da tarefa;
- dono escritor;
- estado de limpeza.

O primeiro corte e read-only. Ele calcula readiness e registra evidencias, mas nao cria worktree, nao troca branch, nao inicia agente e nao faz push.

## Caminhos padrao

Para um ticket `TKT-019`, o plano local usa:

```text
branch: artemis/tkt-019-<slug-do-titulo>
worktree: ../<repo>-artemis-worktrees/tkt-019
lock: .artemis/locks/tkt-019.lock
artifact_root: artifacts/<slug>/run-01
```

`.artemis/` e estado runtime local ignorado pelo Git. Artifacts continuam versionaveis quando forem evidencia de decisao, validacao ou handoff.

## Readiness

`scripts/artemis-workspace.sh` classifica workspace como:

- `ready`: workspace pode ser planejado sem criar nada agora;
- `blocked`: falta contrato minimo, como owner, risco, Exec Pack ou artifact root;
- `human_gate`: ja existe lock, worktree ou branch ocupada exigindo decisao humana.

Warnings, como branch preexistente ou worktree atual sujo, aparecem nos checks, mas nao bloqueiam automaticamente quando o trabalho sera feito em worktree isolado.

## Comandos

```bash
scripts/artemis-workspace.sh
scripts/artemis-workspace.sh --ticket TKT-019
scripts/artemis-workspace.sh --ticket TKT-019 --json
scripts/artemis-workspace.sh --ticket TKT-019 --artifact-root artifacts/artemis-workspace-manager/run-01
```

`scripts/artemis-dry-run.sh` inclui readiness de workspace para tarefas elegiveis.

`scripts/artemis-runner.sh` grava `workspace.json` em cada tentativa supervisionada e bloqueia a tentativa quando o workspace nao esta `ready`.

## Invariantes

- Um agente escritor por worktree.
- Lock existente exige Human Gate.
- Worktree existente exige Human Gate.
- Workspace nao e fonte canonica; Exec Pack, artifacts, validacao e Git continuam canonicos.
- Criacao real de worktree fica para corte posterior ou acao humana explicita.
