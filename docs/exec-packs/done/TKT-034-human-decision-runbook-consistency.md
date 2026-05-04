# TKT-034 - Consistencia do runbook de decisao humana

## Objetivo

Criar uma checagem de consistencia entre o runbook assistido e `real-cleanup-decision.json`, evitando drift em comandos, tickets e evidencias.

## Resultado esperado

O repositorio deve validar que os comandos documentados no runbook correspondem ao pacote real de decisao humana e que exemplos continuam nao-executaveis.

## Nivel ARTEMIS da execucao

Nivel 1 - validacao read-only.

## Agentes envolvidos

- Implementer: cria checagem read-only.
- Reviewer: garante que a checagem nao altera decisoes.
- Memory Keeper: registra evidencias e handoff.

## Contexto minimo

- `artifacts/artemis-assisted-human-decision-runbook/run-01/`
- `artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json`
- `scripts/validate-artemis.sh`

## Escopo

- Validar tickets esperados.
- Validar comandos exatos documentados.
- Validar que exemplos nao sao tratados como decisao real.
- Manter `--execute` fora de escopo.

## Fora de escopo

- Preencher decisao humana.
- Executar cleanup.
- Remover worktrees, locks ou branches.
- Fazer push ou merge remoto.

## Invariantes

- Runbook nao e fonte de autorizacao.
- JSON real continua canonico para decisao preenchida.
- Checagem e read-only.
- Nenhum agente aprova cleanup.

## Validacao prevista

```bash
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-human-decision-runbook-consistency/run-01/STATUS.md`
- `artifacts/artemis-human-decision-runbook-consistency/run-01/VALIDATION.md`
- `artifacts/artemis-human-decision-runbook-consistency/run-01/HANDOFF.md`
