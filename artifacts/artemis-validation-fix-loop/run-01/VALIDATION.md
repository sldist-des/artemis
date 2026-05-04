# VALIDATION

## Checks planejados

- `sh -n scripts/artemis-runner.sh`
- `scripts/artemis-workspace.sh --ticket TKT-023 --artifact-root artifacts/artemis-validation-fix-loop/run-01 --materialize --json`
- `scripts/artemis-runner.sh --ticket TKT-023 --command "false" --execute --use-workspace --attempt-purpose validation --artifact-root artifacts/artemis-validation-fix-loop/run-01`
- `scripts/artemis-runner.sh --ticket TKT-023 --command "pwd" --execute --use-workspace --attempt-purpose retry --retry-of 20260504T141956Z-2-tkt-023 --artifact-root artifacts/artemis-validation-fix-loop/run-01`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- `git diff --check`

## Resultado

- `sh -n scripts/artemis-runner.sh`: passed.
- `scripts/artemis-workspace.sh --ticket TKT-023 --artifact-root artifacts/artemis-validation-fix-loop/run-01 --materialize --json`: passed; criou branch, worktree e lock.
- `scripts/artemis-runner.sh --ticket TKT-023 --command "false" --execute --use-workspace --attempt-purpose validation --artifact-root artifacts/artemis-validation-fix-loop/run-01`: expected failure; artifact path foi impresso e eventos foram gravados.
- `scripts/artemis-runner.sh --ticket TKT-023 --command "pwd" --execute --use-workspace --attempt-purpose retry --retry-of 20260504T141956Z-2-tkt-023 --artifact-root artifacts/artemis-validation-fix-loop/run-01`: passed; `COMMAND.txt` retornou `/srv/veri-artemis-worktrees/tkt-023`.
- Eventos da tentativa falha incluem `attempt_purpose=validation`, `state.to=blocked` e `severity=error`.
- Eventos do retry incluem `attempt_purpose=retry` e `retry_of=20260504T141956Z-2-tkt-023`.
- `scripts/validate-artemis.sh`: passed depois de ativar TKT-024.
- `scripts/artemis-validation-gate.sh`: human_gate esperado, com `passed=22 failed=0 human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passed; event log aponta TKT-024 como proximo Exec Pack ativo e inclui a tentativa falha + retry do TKT-023.
- Headless Chrome Control Plane smoke screenshot: passed; `/tmp/artemis-tkt023-control-plane.png` mostra TKT-024 ativo, 24 concluidos e timeline carregada.
- `git diff --check`: passed.

## Human Gates conhecidos

- Worktrees TKT-021, TKT-022 e TKT-023 permanecem ativos ate lifecycle/cleanup humano.
- GitHub auth ainda invalido para push.
- CODEOWNERS ainda nao tem owners ativos.
