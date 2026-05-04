# VALIDATION

## Checks planejados

- `sh -n scripts/artemis-runner.sh`
- `scripts/validate-artemis.sh`
- `scripts/artemis-workspace.sh --ticket TKT-022 --artifact-root artifacts/artemis-runner-workspace-execution/run-01 --materialize --json`
- `scripts/artemis-runner.sh --ticket TKT-022 --command "pwd" --execute --use-workspace --artifact-root artifacts/artemis-runner-workspace-execution/run-01`
- `git worktree list --porcelain`
- `scripts/artemis-validation-gate.sh`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- Headless Chrome Control Plane smoke screenshot
- `git diff --check`

## Resultado

- `sh -n scripts/artemis-runner.sh`: passed.
- `scripts/validate-artemis.sh`: passed antes da materializacao do TKT-022.
- `scripts/artemis-workspace.sh --ticket TKT-022 --artifact-root artifacts/artemis-runner-workspace-execution/run-01 --materialize --json`: passed; criou branch, worktree e lock.
- `scripts/artemis-runner.sh --ticket TKT-022 --command "pwd" --execute --use-workspace --artifact-root artifacts/artemis-runner-workspace-execution/run-01`: passed; `COMMAND.txt` retornou `/srv/veri-artemis-worktrees/tkt-022`.
- `git worktree list --porcelain`: passed; lista `/srv/veri-artemis-worktrees/tkt-022` na branch `artemis/tkt-022-executar-runner-no-workspace-materia`.
- `scripts/validate-artemis.sh`: passed depois de ativar TKT-023.
- `scripts/artemis-validation-gate.sh`: human_gate esperado, com `passed=22 failed=0 human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passed; event log aponta TKT-023 como proximo Exec Pack ativo e inclui os eventos da tentativa em workspace.
- Headless Chrome Control Plane smoke screenshot: passed; `/tmp/artemis-tkt022-control-plane.png` mostra TKT-023 ativo, 23 concluidos e timeline carregada.
- `git diff --check`: passed.

## Human Gates conhecidos

- Worktrees TKT-021 e TKT-022 permanecem ativos ate cleanup humano.
- GitHub auth ainda invalido para push.
- CODEOWNERS ainda nao tem owners ativos.
