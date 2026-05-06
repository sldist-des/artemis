# VALIDATION

## Resultado local

- Overall: `heartbeat_ready`.
- Ticks completed: `2`.
- Heartbeat: `artifacts/artemis-symphony-daemon/run-01/heartbeat.json`.
- Heartbeat log: `artifacts/artemis-symphony-daemon/run-01/heartbeat.jsonl`.
- Commands executed: `0`.
- Runner auto execution allowed: `false`.
- Bridge called: `false`.
- Long-running process started: `false`.
- Compatibility: `spec_ready`, `daemon_implemented=true`, `daemon_dry_run=true`.
- Validation Gate: `passed=58`, `failed=0`, `human_gate=2`.
- Event Log: `events=30`.
- Control Plane screenshot: `/tmp/artemis-tkt045-control-plane.png`.

## Comandos de verificacao

- `scripts/artemis-symphony-daemon.sh --input control-plane/tasks.json --artifact-root artifacts/artemis-symphony-daemon/run-01 --ticks 2 --interval 0 --max-concurrency 1 --json`
- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- `google-chrome --headless --disable-gpu --no-sandbox --window-size=1600,1000 --screenshot=/tmp/artemis-tkt045-control-plane.png http://127.0.0.1:8145/control-plane/`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
