# ARTEMIS ASSISTED HUMAN DECISION RUNBOOK

Este runbook orienta o preenchimento humano de:

```bash
artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json
```

Ele nao aprova cleanup, nao executa cleanup e nao substitui revisao humana. O agente pode preparar, validar e explicar; a decisao permanece humana.

## Regra central

Cada workspace deve ficar em exatamente um destes estados:

- `pending`: decisao ainda aberta.
- `approved`: humano aprovou todos os comandos locais exatamente como listados.
- `deferred`: humano decidiu manter o workspace por enquanto.
- `rejected`: humano rejeitou cleanup deste workspace.

Use `deferred` quando houver aprovacao parcial, duvida, evidencia insuficiente ou preferencia por manter o workspace.

## Campos obrigatorios

Para `approved`, `deferred` e `rejected`, preencha:

- `decision_record.decided_by`: nome, usuario ou papel do humano que decidiu.
- `decision_record.decided_at`: timestamp ISO-8601, por exemplo `2026-05-04T17:45:00Z`.
- `decision_record.reason`: motivo claro e auditavel.

Para `pending`, deixe esses campos vazios e mantenha `approved_commands` como lista vazia.

## Quando usar cada decisao

### `approved`

Use apenas quando todos os itens abaixo forem verdadeiros:

- `STATUS.md`, `VALIDATION.md` e `HANDOFF.md` do ticket foram revisados.
- O worktree esta registrado em `git worktree list --porcelain`.
- A branch local ja esta integrada ao `HEAD` atual.
- O worktree esta limpo.
- O lock corresponde ao ticket.
- Todos os comandos em `commands_after_approval` foram aceitos exatamente.

Para `approved`, copie todos os comandos de `commands_after_approval` para `decision_record.approved_commands` na mesma ordem.

### `deferred`

Use quando cleanup deve esperar. Exemplos:

- ha duvida sobre a evidencia;
- o humano quer revisar os arquivos do worktree;
- parte dos comandos parece correta, mas outra parte nao;
- o ticket ainda pode ser util para investigacao;
- existe risco operacional nao resolvido.

Para `deferred`, `approved_commands` deve ficar vazio.

### `rejected`

Use quando o humano decidiu que o workspace nao deve ser removido por este fluxo. Exemplos:

- o workspace sera preservado como referencia;
- a branch deve ser tratada por outro processo;
- a decisao de cleanup foi rejeitada por politica ou contexto externo.

Para `rejected`, `approved_commands` deve ficar vazio.

## Como preencher

1. Abra `real-cleanup-decision.json`.
2. Localize o item em `reviews` pelo campo `ticket`.
3. Revise `required_evidence`.
4. Escolha `decision`.
5. Se a decisao for `approved`, `deferred` ou `rejected`, preencha `decided_by`, `decided_at` e `reason`.
6. Se a decisao for `approved`, copie todos os comandos de `commands_after_approval` para `approved_commands`.
7. Se a decisao for `pending`, `deferred` ou `rejected`, deixe `approved_commands` vazio.
8. Salve o arquivo.
9. Rode o contrato.
10. Rode o dry-run.

## Validar contrato

```bash
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-assisted-human-decision-runbook/run-01/validation/approval-contract --json
```

Interprete:

- `overall=human_gate`: ainda ha decisoes `pending`.
- `overall=passed`: nao ha invalidos nem pendentes; decisoes finais foram preenchidas.
- `summary.invalid > 0`: corrija o arquivo antes de qualquer outro passo.
- `summary.execution_allowed`: quantidade de tickets aprovados e prontos para dry-run.

## Validar dry-run

```bash
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-real-cleanup-decision-package/run-01/real-cleanup-decision.json --artifact-root artifacts/artemis-assisted-human-decision-runbook/run-01/validation/approved-cleanup-dry-run --json
```

Interprete:

- `executed_commands=0` deve permanecer verdadeiro no dry-run.
- `ready_to_execute` indica quantos tickets passariam no contrato se uma execucao real fosse explicitamente autorizada depois.
- `human_gate` indica decisoes pendentes, deferidas, rejeitadas ou invalidas.

## Limites

Este TKT nao usa `--execute`.

Nao remova:

- worktrees;
- locks;
- branches.

Nao faça:

- push;
- merge remoto;
- alteracao de GitHub settings;
- decisao em nome do humano.

## Resultado esperado agora

Enquanto nenhum humano preencher a decisao real, a validacao correta e:

- `pending=3`;
- `execution_allowed=0`;
- `human_gate=3` no dry-run;
- `executed_commands=0`.
