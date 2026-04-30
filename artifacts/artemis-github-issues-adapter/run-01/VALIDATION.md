# VALIDATION - ARTEMIS GitHub Issues Adapter Run 01

## Comandos planejados

```bash
sh -n scripts/artemis-github-issues.sh
scripts/artemis-github-issues.sh --artifact-root artifacts/artemis-github-issues-adapter/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root /tmp/artemis-gate-github-issues --json
git diff --check
```

## Resultado

Passou com Human Gate esperado.

## Evidencia

- `scripts/artemis-github-issues.sh --artifact-root artifacts/artemis-github-issues-adapter/run-01 --json` retornou `overall=human_gate`.
- `artifacts/artemis-github-issues-adapter/run-01/github-issues.json` registrou o resultado estruturado.
- `artifacts/artemis-github-issues-adapter/run-01/GITHUB_ISSUES.md` registrou o contrato de labels.
- `scripts/validate-artemis.sh` passou.
- `scripts/artemis-validation-gate.sh` retornou `passed=12`, `failed=0`, `human_gate=2`.

## Human Gate

- Reautenticar `gh`.
- Definir CODEOWNERS real.
- Depois disso, rodar novamente o adapter para listar issues com label `artemis`.
