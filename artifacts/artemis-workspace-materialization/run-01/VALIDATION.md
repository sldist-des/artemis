# VALIDATION

## Checks planejados

- `sh -n scripts/artemis-workspace.sh`
- `scripts/artemis-workspace.sh --ticket TKT-021 --artifact-root artifacts/artemis-workspace-materialization/run-01 --materialize --json`
- `scripts/artemis-workspace.sh --ticket TKT-021 --json`
- `git worktree list --porcelain`
- `git show-ref --heads artemis/tkt-021-materializar-workspace-artemis-contr`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- Headless Chrome Control Plane smoke screenshot
- `git diff --check`

## Resultado

- `sh -n scripts/artemis-workspace.sh`: passed.
- `scripts/artemis-workspace.sh --ticket TKT-021 --artifact-root artifacts/artemis-workspace-materialization/run-01 --materialize --json`: passed com permissao local ampliada; criou branch, worktree e lock.
- `scripts/artemis-workspace.sh --ticket TKT-021 --json`: passed; rechecagem ficou em `human_gate` por lock/worktree/branch ja materializados.
- `git worktree list --porcelain`: passed; lista `/srv/veri-artemis-worktrees/tkt-021` na branch `artemis/tkt-021-materializar-workspace-artemis-contr`.
- `git show-ref --heads artemis/tkt-021-materializar-workspace-artemis-contr`: passed.
- `scripts/validate-artemis.sh`: passed.
- `scripts/artemis-validation-gate.sh`: human_gate esperado, com `passed=22 failed=0 human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passed; event log aponta TKT-022 como proximo Exec Pack ativo.
- Headless Chrome Control Plane smoke screenshot: passed; `/tmp/artemis-tkt021-control-plane-final.png` mostra TKT-022 ativo, TKT-021 concluido e timeline carregada.
- `git diff --check`: passed.

## Human Gates conhecidos

- O workspace materializado permanece ativo ate revisao/cleanup humano.
- GitHub auth ainda invalido para push.
- CODEOWNERS ainda nao tem owners ativos.
