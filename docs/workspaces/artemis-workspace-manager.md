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

O modo padrao e read-only. Ele calcula readiness e registra evidencias, mas nao cria worktree, nao troca branch, nao inicia agente e nao faz push.

A materializacao real exige flag explicita:

```bash
scripts/artemis-workspace.sh --ticket TKT-021 --artifact-root artifacts/artemis-workspace-materialization/run-01 --materialize
```

Esse comando cria apenas efeitos locais: branch, worktree e lock. Ele nao inicia Codex, Claude, push, merge, PR ou cleanup automatico.

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
scripts/artemis-workspace.sh --ticket TKT-019 --artifact-root artifacts/<ticket>/run-01 --materialize
```

`scripts/artemis-dry-run.sh` inclui readiness de workspace para tarefas elegiveis.

`scripts/artemis-runner.sh` grava `workspace.json` em cada tentativa supervisionada e bloqueia a tentativa quando o workspace nao esta `ready`.

`scripts/artemis-workspace-lifecycle.sh` lista locks, worktrees, branches e artifact roots ja materializados. O comando e somente leitura e classifica cada workspace como `active`, `review_ready` ou `decision_required`; nenhuma classificacao remove worktree ou lock automaticamente.

`scripts/artemis-workspace-cleanup-review.sh` transforma o inventario em um pacote de decisao humana com checklist, bloqueios e comandos candidatos. Ele nao executa cleanup.

`scripts/artemis-approved-workspace-cleanup.sh` valida decisoes aprovadas e usa dry-run por padrao. Execucao real exige `--execute`, decisao `approved` e comandos locais exatamente iguais aos gerados pela revisao.

## Invariantes

- Um agente escritor por worktree.
- Lock existente exige Human Gate.
- Worktree existente exige Human Gate.
- Workspace nao e fonte canonica; Exec Pack, artifacts, validacao e Git continuam canonicos.
- Materializacao real exige `--materialize` e `--ticket`.
- Cleanup automatico e proibido; abandono ou remocao de worktree exige revisao humana.
