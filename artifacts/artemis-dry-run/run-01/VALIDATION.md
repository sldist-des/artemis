# VALIDATION - ARTEMIS Dry Run Run 01

## Comandos planejados

```bash
sh -n scripts/artemis-dry-run.sh
scripts/artemis-dry-run.sh
scripts/artemis-dry-run.sh --json
scripts/artemis-dry-run.sh --json > artifacts/artemis-dry-run/run-01/dry-run.json
scripts/validate-artemis.sh
git diff --check
```

## Resultado

Passou.

## Evidencia

- `sh -n scripts/artemis-dry-run.sh` passou.
- `scripts/artemis-dry-run.sh` retornou resumo legivel por humano.
- `scripts/artemis-dry-run.sh --json` retornou JSON valido.
- `scripts/artemis-dry-run.sh --json > artifacts/artemis-dry-run/run-01/dry-run.json` registrou a simulacao.
- `artifacts/artemis-dry-run/run-01/dry-run.json` classificou TKT-011 como `eligible`.
- `scripts/validate-artemis.sh` passou.
- `git diff --check` passou.
- Chrome headless renderizou `http://127.0.0.1:8123/control-plane/index.html` em `/tmp/artemis-dry-run-control-plane.png`.

## Observacoes

- O dry-run apenas imprime o que seria despachado. Ele nao inicia agentes, nao cria worktrees e nao altera Exec Packs.
