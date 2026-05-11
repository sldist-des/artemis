# TKT-052 - Promocao local do intake remoto do ARTEMIS Symphony

## Objetivo

Criar uma promocao local revisavel para itens vindos do Remote Intake, sem
transformar GitHub Issues, PRs ou qualquer fonte remota em autoridade de
execucao automatica.

## Escopo entregue

- `scripts/artemis-symphony-remote-promotion.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_REMOTE_PROMOTION.md`
- Artefatos canonicos em `artifacts/artemis-symphony-promotion/run-01/`
- Evento canonico `evt_tkt-052_symphony_remote_promotion`
- Validacao no `scripts/validate-artemis.sh`
- Cobertura no `scripts/artemis-validation-gate.sh`
- Exposicao no Control Plane

## Contrato

- Sem decisao humana exata, a promocao fica em Human Gate.
- Com decisao aprovada, o script gera `promoted-source.json` local.
- A fonte promovida fica em `state=ready`.
- O comando terminal exato e registrado, mas nao executado.
- Validation Gate e obrigatorio antes de execucao posterior.
- Queue, Bridge, Runner e GitHub nao sao chamados.
- Escritas remotas continuam bloqueadas.

## Validacao esperada

```bash
scripts/artemis-symphony-remote-promotion.sh --json
scripts/artemis-symphony-remote-promotion.sh \
  --remote-intake artifacts/artemis-symphony-remote-intake/run-01/remote-intake.json \
  --decision artifacts/artemis-symphony-promotion/run-01/fixtures/decision.json \
  --artifact-root artifacts/artemis-symphony-promotion/run-01 \
  --json
scripts/artemis-dry-run.sh --input artifacts/artemis-symphony-promotion/run-01/promoted-source.json --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
git diff --check
```

## Handoff

O proximo corte e `TKT-064 - Agent Runtime Launcher Execution Gate do ARTEMIS Symphony`,
mantendo tarefas, agentes, dependencias, gates, validacoes, custos, memoria e
artefatos como grafo operacional auditavel.
