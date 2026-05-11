# ARTEMIS Symphony Remote Source

O ARTEMIS Symphony Remote Source conecta GitHub Issues ao Symphony como
fonte supervisionada de intake. Ele nao transforma issue em autorizacao de
execucao.

## Contrato

- GitHub Issues define intencao e evidencia remota.
- Exec Pack local define contrato de execucao.
- Control Plane mostra estado, nao decide estado.
- Escritas remotas permanecem bloqueadas por padrao.
- Dispatch direto a partir de issue permanece bloqueado por padrao.
- Terminal-first, Human Gates e Validation Gate continuam obrigatorios.

## Uso

```bash
scripts/artemis-symphony-remote-source.sh \
  --artifact-root artifacts/artemis-symphony-remote-source/run-01 \
  --json
```

Para validacao sem depender de auth remota:

```bash
scripts/artemis-symphony-remote-source.sh \
  --github-artifact artifacts/artemis-symphony-remote-source/run-01/fixtures/github-issues.json \
  --artifact-root artifacts/artemis-symphony-remote-source/run-01 \
  --json
```

## Saidas

- `remote-source.json`
- `task-source.json`
- `events.json`
- `STATUS.md`
- `VALIDATION.md`
- `HANDOFF.md`

## Labels

- `artemis:intake` marca item remoto como intake revisavel.
- `artemis:ready` exige tambem `exec-pack:<path>` e ainda assim fica como
  intake supervisionado.
- `artemis:human-gate` preserva decisao humana.
- `artemis:blocked` materializa bloqueio.
- `artemis:done` materializa conclusao observada.
- `risk:low`, `risk:medium` e `risk:high` definem risco local.

## Limites

- Nao escreve labels, comentarios, branches, PRs ou configuracoes remotas.
- Nao chama runner automaticamente.
- Nao passa `--execute` para Queue Bridge.
- Nao substitui Exec Pack por metadados de issue.
- Nao resolve auth GitHub ou CODEOWNERS.

## Proximo Corte

`TKT-066 - Agent Runtime Execution Result Intake do ARTEMIS Symphony`
