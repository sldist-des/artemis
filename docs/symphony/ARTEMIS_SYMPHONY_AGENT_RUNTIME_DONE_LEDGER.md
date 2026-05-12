# ARTEMIS Symphony - Agent Runtime Done Ledger

O Agent Runtime Done Ledger e o corte final da espinha de runtime do ARTEMIS
Symphony. Ele consome o Completion Review Gate e registra Done tecnico local
somente quando a revisao humana final foi aceita.

Este ledger nao aceita revisao, nao fecha GitHub, nao faz merge, nao faz push,
nao executa comandos, nao inicia agentes, nao faz deploy, nao toca producao e
nao toca secrets.

## Entradas

- `artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-gate.json`

## Saidas

- `artifacts/artemis-agent-runtime-done-ledger/run-01/done-ledger.json`
- `artifacts/artemis-agent-runtime-done-ledger/run-01/DONE_LEDGER.md`
- `artifacts/artemis-agent-runtime-done-ledger/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-done-ledger/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-done-ledger/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-done-ledger/run-01/events.json`

## Estado atual esperado

Como o Completion Review Gate ainda esta bloqueado aguardando Completion
Handoff pronto e revisao humana aceita, o estado esperado do Done Ledger e:

- `overall=human_gate`
- `ledger_state=waiting_for_completion_review_accepted`
- `completion_review_accepted=false`
- `ready_for_done_ledger=false`
- `done_ledger_recorded=false`
- `technical_done=false`
- `remote_done_closed=false`
- evento canonico `human_gate.opened`

## Comando canonico

```bash
scripts/artemis-agent-runtime-done-ledger.sh --json
```

Com paths explicitos:

```bash
scripts/artemis-agent-runtime-done-ledger.sh \
  --completion-review-gate artifacts/artemis-agent-runtime-completion-review-gate/run-01/completion-review-gate.json \
  --artifact-root artifacts/artemis-agent-runtime-done-ledger/run-01 \
  --json
```

## Regras

- `done_ledger_recorded` so pode ser verdadeiro quando
  `completion_review_accepted=true`.
- `technical_done` e local; nao equivale a fechamento de GitHub, PR, issue,
  deploy, producao ou aceite de produto.
- `remote_done_closed` deve permanecer `false` neste corte.
- O ledger nunca executa comandos nem inicia runtime.

## Proximo corte

Nenhum TKT planejado no escopo atual da espinha de runtime. Novos TKTs devem
nascer como nova fase ou melhoria deliberada do ARTEMIS Symphony.
