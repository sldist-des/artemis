# TKT-050 - Fonte remota supervisionada do ARTEMIS Symphony

## Objetivo

Conectar GitHub Issues ao ARTEMIS Symphony como fonte remota supervisionada,
sem conceder autoridade de execucao automatica.

## Escopo

- Criar `scripts/artemis-symphony-remote-source.sh`.
- Criar `docs/symphony/ARTEMIS_SYMPHONY_REMOTE_SOURCE.md`.
- Gerar artifacts em `artifacts/artemis-symphony-remote-source/run-01/`.
- Atualizar especificacao, compatibilidade, Validation Gate e Control Plane.

## Fora de Escopo

- Push, PR, merge, deploy ou configuracao remota automatica.
- Escrita em GitHub Issues.
- Execucao direta de runner a partir de issue.
- Substituir Exec Pack por labels ou corpo de issue.

## Contrato

- Issue remota define intencao e evidencia.
- Exec Pack local define contrato de execucao.
- `remote_writes_allowed=false`.
- `runner_auto_execution_allowed=false`.
- `direct_dispatch_allowed=false`.
- `commands_executed=0`.

## Validacao

```bash
sh -n scripts/artemis-symphony-remote-source.sh
scripts/artemis-symphony-remote-source.sh --github-artifact artifacts/artemis-symphony-remote-source/run-01/fixtures/github-issues.json --artifact-root artifacts/artemis-symphony-remote-source/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Evidencia

- `artifacts/artemis-symphony-remote-source/run-01/STATUS.md`
- `artifacts/artemis-symphony-remote-source/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-remote-source/run-01/HANDOFF.md`
- `artifacts/artemis-symphony-remote-source/run-01/remote-source.json`
- `artifacts/artemis-symphony-remote-source/run-01/task-source.json`
- `artifacts/artemis-symphony-remote-source/run-01/events.json`

## Handoff

O proximo corte e `TKT-051 - Intake remoto revisavel do ARTEMIS Symphony`,
que deve revisar/promover itens remotos antes de qualquer fila, service ou
execucao.
