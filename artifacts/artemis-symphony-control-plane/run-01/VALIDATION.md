# VALIDATION

## Resultado local

- Control Plane contem secao `ARTEMIS Symphony`.
- Secao contem `symphony-evidence`.
- Secao mostra `runner_plan_ready`.
- Secao aponta para `artifacts/artemis-symphony-bridge/run-01/symphony-bridge.json`.
- Secao aponta para tentativa plan-only do runner.
- Screenshot desktop verificado em `/tmp/artemis-tkt044-control-plane.png`.
- Validation Gate: `passed=56`, `failed=0`, `human_gate=2`.
- Compatibility: `kernel_implemented=true`, `bridge_implemented=true`, `daemon_implemented=false`.
- Event Log: `events=27`.

## Comandos de verificacao

- `scripts/validate-artemis.sh`
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`
- `scripts/artemis-symphony-compatibility.sh --artifact-root artifacts/artemis-symphony-compatibility/run-01 --json`
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`
- `google-chrome --headless --disable-gpu --no-sandbox --window-size=1600,1000 --screenshot=/tmp/artemis-tkt044-control-plane.png http://127.0.0.1:8145/control-plane/`
- `git diff --check`

## Visual

- Screenshot aprovado: `/tmp/artemis-tkt044-control-plane.png`.
