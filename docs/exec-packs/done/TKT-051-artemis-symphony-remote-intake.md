# TKT-051 - Intake remoto revisavel do ARTEMIS Symphony

## Objetivo

Criar a camada de revisao local entre a fonte remota supervisionada e qualquer
promocao para fila, service ou runner.

## Escopo

- Criar `scripts/artemis-symphony-remote-intake.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_REMOTE_INTAKE.md`.
- Gerar artifacts em `artifacts/artemis-symphony-remote-intake/run-01/`.
- Atualizar spec, compatibilidade, Validation Gate e Control Plane.

## Fora de Escopo

- Promover issue remota para `ready`.
- Chamar Queue, Service, Bridge ou Runner.
- Escrever em GitHub.
- Criar PR, branch, label ou comentario.

## Contrato

- `review-source.json` sempre fica em `state=human`.
- `promotion_allowed=0`.
- `direct_dispatch_allowed=false`.
- `remote_writes_allowed=false`.
- `runner_auto_execution_allowed=false`.
- `commands_executed=0`.

## Validacao

```bash
sh -n scripts/artemis-symphony-remote-intake.sh
scripts/artemis-symphony-remote-intake.sh --remote-source artifacts/artemis-symphony-remote-source/run-01/remote-source.json --artifact-root artifacts/artemis-symphony-remote-intake/run-01 --json
scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-remote-intake/run-01/review-source.json --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencia

- `artifacts/artemis-symphony-remote-intake/run-01/STATUS.md`
- `artifacts/artemis-symphony-remote-intake/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-remote-intake/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-remote-intake/run-01/REVIEW.md`
- `artifacts/artemis-symphony-remote-intake/run-01/remote-intake.json`
- `artifacts/artemis-symphony-remote-intake/run-01/review-source.json`
- `artifacts/artemis-symphony-remote-intake/run-01/events.json`

## Handoff

O proximo corte e `TKT-052 - Promocao local do intake remoto do ARTEMIS
Symphony`, que deve exigir decisao humana exata antes de converter intake
remoto revisado em fonte local executavel.
