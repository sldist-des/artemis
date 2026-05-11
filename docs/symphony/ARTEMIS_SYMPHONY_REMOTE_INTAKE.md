# ARTEMIS Symphony Remote Intake

O ARTEMIS Symphony Remote Intake revisa a fonte remota antes de qualquer
promocao local. Ele transforma `remote-source.json` em um pacote de revisao e
mantem a fonte derivada em Human Gate.

## Contrato

- Fonte remota define intencao e evidencia.
- Remote Intake define pacote de revisao.
- Exec Pack local continua definindo contrato de execucao.
- Promocao local fica bloqueada ate decisao humana explicita.
- `review-source.json` usa `state=human`.
- Dispatch direto, runner automatico e escritas remotas permanecem bloqueados.

## Uso

```bash
scripts/artemis-symphony-remote-intake.sh \
  --remote-source artifacts/artemis-symphony-remote-source/run-01/remote-source.json \
  --artifact-root artifacts/artemis-symphony-remote-intake/run-01 \
  --json
```

## Saidas

- `remote-intake.json`
- `review-source.json`
- `REVIEW.md`
- `events.json`
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`

## Estados

- `remote_intake_ready`: existe item pronto para revisao humana local.
- `remote_intake_human_gate`: item existe, mas precisa de binding ou decisao.
- `remote_intake_empty`: fonte remota disponivel sem itens.
- `human_gate`: fonte remota ainda depende de auth, CODEOWNERS ou outro gate.
- `failed`: artifact ausente ou invalido.

## Limites

- Nao promove tarefa para `ready`.
- Nao chama Queue, Service, Bridge ou Runner.
- Nao escreve labels, comentarios, PRs ou branches.
- Nao substitui Exec Pack por issue.

## Proximo Corte

`TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony`
