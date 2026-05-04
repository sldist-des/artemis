# VALIDATION

## Validacoes

- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-approved-workspace-cleanup/run-01 --json`: passou com `overall=human_gate`.
- `scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root /tmp/artemis-approved-workspace-cleanup-execute-pending --execute --json`: recusou execucao com exit code `3` e `executed_commands=0`.
- `scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json`: passou com `passed=28`, `failed=0`, `human_gate=2`.
- `scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json`: passou.
- `sh -n scripts/artemis-approved-workspace-cleanup.sh`: passou via Validation Gate.
- `git diff --check`: passou.
- Control Plane smoke em Chrome headless: `/tmp/artemis-tkt026-control-plane.png`.

## Resultado do dry-run

- TKT-021: Human Gate por decisao `pending`.
- TKT-022: Human Gate por decisao `pending`.
- TKT-023: Human Gate por decisao `pending`.

## Criterio aplicado

O executor so considera um ticket pronto quando:

- `decision_record.decision` e `approved`;
- `decided_by`, `decided_at` e `reason` estao preenchidos;
- `approved_commands` corresponde exatamente aos comandos gerados pela revisao;
- todos os comandos estao na allowlist local.

## Gaps

- Nenhum cleanup real foi executado.
- Nenhuma decisao humana foi aprovada.
- Handoff de runtime limpo ou mantido fica adiado para TKT-027.
