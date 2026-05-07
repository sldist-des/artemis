# ARTEMIS Symphony Remote Promotion

O ARTEMIS Symphony Remote Promotion promove um item revisado do Remote Intake
para uma fonte local executavel somente quando existe decisao humana exata.

## Contrato

- Remote Intake define pacote de revisao.
- Decisao humana define autoridade de promocao local.
- Exec Pack local define contrato de execucao.
- Fonte promovida fica em `state=ready`.
- Comando terminal exato fica registrado, mas nao e executado aqui.
- Validation Gate continua obrigatorio antes de qualquer execucao.
- Queue, Bridge e Runner nao sao chamados pela promocao.
- Escritas remotas continuam bloqueadas.

## Uso

```bash
scripts/artemis-symphony-remote-promotion.sh \
  --remote-intake artifacts/artemis-symphony-remote-intake/run-01/remote-intake.json \
  --decision artifacts/artemis-symphony-promotion/run-01/fixtures/decision.json \
  --artifact-root artifacts/artemis-symphony-promotion/run-01 \
  --json
```

Sem `--decision`, o resultado deve permanecer em Human Gate.

## Artefatos

- `remote-promotion.json` - resumo da promocao e invariantes.
- `promoted-source.json` - fonte local pronta para dry-run/queue posterior.
- `DECISION.md` - decisao humana interpretada e blockers.
- `STATUS.md` - estado operacional.
- `VALIDATION.md` - comandos de validacao.
- `HANDOFF.md` - proximo corte.
- `events.json` - evento canonico.

## Decisao minima

```json
{
  "decision": "approved",
  "ticket": "TKT-950",
  "promote_to": "TKT-950",
  "title": "Validate supervised source intake",
  "owner": "Codex",
  "risk": "low",
  "exec_pack": "docs/exec-packs/done/TKT-009-local-task-source.md",
  "evidence": "artifacts/artemis-symphony-promotion/run-01/STATUS.md",
  "command": "scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-promotion/run-01/promoted-source.json",
  "validation_gate": "artifacts/artemis-validation-gate/run-01/validation-gate.json",
  "remote_review_acknowledged": true,
  "terminal_command_acknowledged": true,
  "validation_gate_required": true,
  "decided_by": "Humano",
  "reason": "Exact local promotion approved after review."
}
```

## Proximo corte

`TKT-055 - Project Graph View do ARTEMIS Symphony`
