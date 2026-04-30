# VALIDATION - ARTEMIS Local Runner Run 01

## Comandos planejados

```bash
sh -n scripts/artemis-runner.sh
scripts/artemis-runner.sh --ticket TKT-011 --command "scripts/artemis-dry-run.sh"
scripts/artemis-runner.sh --ticket TKT-011 --command "scripts/artemis-dry-run.sh" --execute
scripts/artemis-runner.sh --ticket TKT-011 --command "git push origin main"
scripts/validate-artemis.sh
git diff --check
```

## Resultado

Passou.

## Evidencia

- `sh -n scripts/artemis-runner.sh` passou.
- `scripts/artemis-runner.sh --ticket TKT-011 --command "scripts/artemis-dry-run.sh"` criou tentativa plan-only.
- `scripts/artemis-runner.sh --ticket TKT-011 --command "scripts/artemis-dry-run.sh" --execute` executou comando seguro e gravou output em `COMMAND.txt`.
- `scripts/artemis-runner.sh --ticket TKT-011 --command "git push origin main"` bloqueou o comando com Human Gate.
- `scripts/validate-artemis.sh` passou.
- `git diff --check` passou.
- Chrome headless renderizou `http://127.0.0.1:8123/control-plane/index.html` em `/tmp/artemis-local-runner-control-plane.png`.

## Tentativa registrada

- `artifacts/artemis-local-runner/run-01/attempts/20260430T185019Z-2-tkt-011/`
