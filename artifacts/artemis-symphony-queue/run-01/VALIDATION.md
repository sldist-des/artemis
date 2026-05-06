# VALIDATION

## Resultado local

- Overall: `queue_empty`.
- Queue items: `0`.
- Review required: `0`.
- Commands executed: `0`.
- Bridge called: `false`.
- Runner called: `false`.
- Runner auto execution allowed: `false`.
- Synthetic validation: `queue_ready`, `queue_items=2`, `review_required=2`.
- Compatibility: `spec_ready`, `queue_implemented=true`.
- Validation Gate: `passed=60`, `failed=0`, `human_gate=2`.
- Event Log: `events=31`.
- Control Plane screenshot: `/tmp/artemis-tkt046-control-plane.png`.

## Comandos de verificacao

- `scripts/artemis-symphony-queue.sh --daemon artifacts/artemis-symphony-daemon/run-01/symphony-daemon.json --artifact-root artifacts/artemis-symphony-queue/run-01 --json`
- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- `google-chrome --headless --disable-gpu --no-sandbox --window-size=1680,1050 --screenshot=/tmp/artemis-tkt046-control-plane.png http://127.0.0.1:8146/control-plane/`
- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `git diff --check`

## Erros

- Nenhum erro tecnico local.
