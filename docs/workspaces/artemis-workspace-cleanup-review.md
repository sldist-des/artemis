# ARTEMIS Workspace Cleanup Review

Cleanup de workspace e uma decisao humana, nao uma rotina automatica.

O inventario de lifecycle pode indicar `review_ready`, mas esse estado significa apenas que ha evidencia suficiente para revisao. Ele nao autoriza remover worktree, branch ou lock.

## Protocolo

1. Gere inventario atualizado:

```bash
scripts/artemis-workspace-lifecycle.sh --artifact-root artifacts/artemis-workspace-lifecycle/run-01 --json
```

2. Gere o pacote de revisao:

```bash
scripts/artemis-workspace-cleanup-review.sh --artifact-root artifacts/artemis-workspace-cleanup-review/run-01 --json
```

3. Revise para cada ticket:

- `STATUS.md`, `VALIDATION.md` e `HANDOFF.md` do artifact root;
- lock local em `.artemis/locks/`;
- worktree registrado em `git worktree list --porcelain`;
- branch local integrada ao `HEAD` atual;
- worktree limpo.

4. Registre a decisao humana em `DECISION_TEMPLATE.md` antes de qualquer comando de cleanup.

## Estados

- `eligible_for_human_cleanup_approval`: o workspace esta apto a revisao humana para cleanup local.
- `defer_cleanup`: falta evidencia, ha branch nao integrada, worktree sujo ou divergencia local.

## Invariantes

- O script de revisao nunca remove worktree, lock ou branch.
- `pending` nao e aprovacao.
- Comandos de cleanup precisam aparecer explicitamente na decisao humana.
- Workspace sujo, branch nao integrada ou evidencia ausente interrompem o cleanup.
- Push, merge remoto e PR continuam fora deste protocolo.

## Executor aprovado

Antes do executor, valide o contrato da decisao humana:

```bash
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-human-cleanup-approval-contract/run-01 --json
```

Decisoes validas:

- `pending`: decisao aberta, sem metadata obrigatoria e sem comandos aprovados;
- `approved`: exige `decided_by`, `decided_at`, `reason` e todos os comandos exatos;
- `deferred`: exige metadata e razao para manter o workspace pendente;
- `rejected`: exige metadata e razao para rejeitar cleanup.

`approved_commands` so pode aparecer em `approved`, e precisa ser identico a `commands_after_approval`. Aprovacao parcial deve ser `deferred`.

Para exemplos sinteticos:

```bash
scripts/artemis-human-decision-fixtures.sh --artifact-root artifacts/artemis-human-decision-fixtures/run-01 --json
```

As fixtures usam caminhos sinteticos e nao devem ser usadas com `--execute`.

Para preparar um pacote real preenchivel, sem executar cleanup:

```bash
scripts/artemis-real-cleanup-decision-package.sh --source artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-real-cleanup-decision-package/run-01 --json
```

O pacote grava `real-cleanup-decision.json` com todas as decisoes como `pending`. O humano deve preencher `decision_record` por workspace e validar o arquivo antes de qualquer executor.

O preenchimento humano deve seguir:

```bash
artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md
```

Depois de alterar o runbook ou o pacote real, valide consistencia:

```bash
scripts/artemis-human-decision-runbook-consistency.sh --artifact-root artifacts/artemis-human-decision-runbook-consistency/run-01 --json
```

`scripts/artemis-approved-workspace-cleanup.sh` valida `cleanup-review.json` ou um artifact equivalente com decisoes preenchidas.

```bash
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-approved-workspace-cleanup/run-01 --json
```

O modo padrao e dry-run. O executor so considera um ticket pronto quando:

- `decision_record.decision` e `approved`;
- `decided_by`, `decided_at` e `reason` estao preenchidos;
- `approved_commands` corresponde exatamente aos comandos gerados pelo pacote de revisao;
- cada comando esta na allowlist local.

Sem `--execute`, nenhum comando e executado. Com `--execute`, qualquer decisao nao aprovada ou divergente interrompe a execucao antes de tocar no workspace.

## Handoff de runtime

`scripts/artemis-workspace-runtime-handoff.sh` registra o estado final local depois da revisao ou tentativa de cleanup.

```bash
scripts/artemis-workspace-runtime-handoff.sh --artifact-root artifacts/artemis-workspace-runtime-handoff/run-01 --json
```

Estados de handoff:

- `cleaned`: cleanup aprovado foi executado e reportou sucesso;
- `kept`: workspace permanece presente e revisavel;
- `pending`: decisao humana ainda esta aberta;
- `approved_ready`: decisao humana e valida, mas cleanup ainda nao executou;
- `deferred`: humano adiou cleanup com razao registrada;
- `rejected`: humano rejeitou cleanup com razao registrada;
- `needs_decision`: ha falha, divergencia ou evidencia insuficiente.
