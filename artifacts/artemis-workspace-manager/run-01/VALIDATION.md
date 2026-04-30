# VALIDATION

## Checks planejados

- `scripts/artemis-workspace.sh --ticket TKT-019 --artifact-root artifacts/artemis-workspace-manager/run-01 --json`
- `scripts/artemis-dry-run.sh --json`
- `scripts/artemis-runner.sh --input /tmp/artemis-runner-task-source.json --ticket TKT-VALIDATE --command "scripts/artemis-dry-run.sh --input /tmp/artemis-runner-task-source.json" --artifact-root /tmp/artemis-runner-validation`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh`
- `git diff --check`

## Resultado

- `scripts/artemis-workspace.sh --ticket TKT-019 --artifact-root artifacts/artemis-workspace-manager/run-01 --json`: passed antes do arquivamento do TKT-019.
- `scripts/artemis-workspace.sh --ticket TKT-020 --artifact-root artifacts/artemis-workspace-manager/run-01 --json`: passed para o proximo Exec Pack ativo.
- `scripts/artemis-dry-run.sh --json`: passed; decisao elegivel inclui `workspace`.
- `scripts/artemis-runner.sh` com fonte sintetica `TKT-VALIDATE`: passed; tentativa registrou `workspace.json`.
- `scripts/validate-artemis.sh`: passed.
- `scripts/artemis-validation-gate.sh`: human_gate esperado, com `passed=21 failed=0 human_gate=2`.
- `git diff --check`: passed.

## Human Gates conhecidos

- GitHub auth ainda invalido para push.
- GitHub Issues adapter permanece read-only/local ate autenticacao e owners reais serem configurados.
