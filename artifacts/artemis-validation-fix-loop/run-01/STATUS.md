# STATUS

## Resultado

TKT-023 formalizou o loop de validacao/fix/retry em workspace isolado.

## Mudancas

- `scripts/artemis-runner.sh` ganhou `--attempt-purpose`.
- `scripts/artemis-runner.sh` ganhou `--retry-of`.
- Tentativas com falha passam a imprimir o artifact path antes de sair com codigo diferente de zero.
- `RUNNER.md`, `RESULT.md` e `events.json` registram `attempt_purpose` e `retry_of`.
- A tentativa de retry preserva a tentativa anterior e aponta para ela.

## Evidencia executada

- Tentativa de validacao: `artifacts/artemis-validation-fix-loop/run-01/attempts/20260504T141956Z-2-tkt-023`
- Resultado da validacao: exit code `1`, evento `runner.attempt_completed` com estado `blocked` e severidade `error`.
- Tentativa de retry: `artifacts/artemis-validation-fix-loop/run-01/attempts/20260504T142001Z-2-tkt-023`
- Resultado do retry: exit code `0`, `retry_of=20260504T141956Z-2-tkt-023`.

## Invariantes preservados

- Runner continua terminal-first.
- Retry nao apaga evidencia anterior.
- Cada tentativa tem eventos canonicos.
- Workspace isolado e lock continuam exigidos para execucao com `--use-workspace`.
- Cleanup automatico continua fora de escopo.
