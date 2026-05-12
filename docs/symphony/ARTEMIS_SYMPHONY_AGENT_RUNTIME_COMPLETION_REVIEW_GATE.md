# ARTEMIS Symphony - Agent Runtime Completion Review Gate

O Agent Runtime Completion Review Gate e o corte do ARTEMIS Symphony que abre
a revisao humana final antes de qualquer Done Ledger.

Ele consome o `completion-handoff.json` e um registro de decisao humana local.
O gate nao aceita revisao no lugar do humano, nao marca Done, nao fecha remoto,
nao executa comandos, nao inicia agentes, nao faz push, PR, deploy, producao ou
secrets.

## Entradas

- `artifacts/artemis-agent-runtime-completion-handoff/run-01/completion-handoff.json`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-decision.json`

## Saidas

- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-gate.json`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-decision.json`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/COMPLETION_REVIEW_GATE.md`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/events.json`

## Estado atual esperado

Como o Completion Handoff ainda esta bloqueado por validacao pos-execucao nao
concluida, o estado esperado do Review Gate e:

- `overall=human_gate`
- `review_state=waiting_for_completion_handoff_ready`
- `completion_handoff_ready=false`
- `completion_review_ready=false`
- `completion_review_accepted=false`
- `ready_for_done_ledger=false`
- `decision=pending`
- evento canonico `approval.requested`

## Comando canonico

```bash
scripts/artemis-agent-runtime-completion-review-gate.sh --json
```

Com paths explicitos:

```bash
scripts/artemis-agent-runtime-completion-review-gate.sh \
  --completion-handoff artifacts/artemis-agent-runtime-completion-handoff/run-01/completion-handoff.json \
  --artifact-root artifacts/artemis-agent-runtime-completion-review-gate/run-01 \
  --json
```

## Regras

- `completion_review_ready` so pode ser verdadeiro quando o Completion Handoff
  estiver pronto, sem rollback pendente e sem comandos falhos.
- `completion_review_accepted` so pode ser verdadeiro com decisao humana
  `accepted`, responsavel, data, motivo e `done_authorized=true`.
- `remote_close_authorized` deve permanecer `false` neste corte.
- O Done Ledger deve continuar bloqueado enquanto
  `completion_review_accepted=false`.

## Proximo corte

`TKT-070 - Agent Runtime Done Ledger do ARTEMIS Symphony` deve consumir
`completion-review-gate.json` e registrar Done tecnico apenas quando a revisao
humana final estiver aceita.
