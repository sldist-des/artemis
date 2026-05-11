# ARTEMIS Symphony - Agent Runtime Completion Handoff

O Agent Runtime Completion Handoff e o corte do ARTEMIS Symphony que consolida
resultado, validacao, custo, rollback e riscos residuais depois da validacao
pos-execucao.

Ele consome:

- `artifacts/artemis-agent-runtime-post-execution-validation-gate/run-01/post-execution-validation-gate.json`

Ele produz:

- `artifacts/artemis-agent-runtime-completion-handoff/run-01/completion-handoff.json`
- `artifacts/artemis-agent-runtime-completion-handoff/run-01/COMPLETION_HANDOFF.md`
- `artifacts/artemis-agent-runtime-completion-handoff/run-01/STATUS.md`
- `artifacts/artemis-agent-runtime-completion-handoff/run-01/VALIDATION.md`
- `artifacts/artemis-agent-runtime-completion-handoff/run-01/HANDOFF.md`
- `artifacts/artemis-agent-runtime-completion-handoff/run-01/events.json`

## Regra central

O handoff final so fica pronto quando:

- o Post-Execution Validation Gate esta `post_execution_validation_completed`;
- `summary.post_execution_validation_completed=true`;
- `validation_package.ready_for_completion_handoff=true`;
- nao ha comando de runtime falho;
- nao ha rollback pendente;
- remoto, producao e secrets continuam bloqueados.

Qualquer estado plan-only, Human Gate, validacao pendente, falha de validacao,
rollback pendente ou evidencia ausente mantem o handoff em `human_gate` ou
`failed`.

## Estado esperado no corte atual

Como o runtime supervisionado ainda esta bloqueado por Human Gate, o resultado
esperado e:

- `overall=human_gate`;
- `handoff_state=waiting_for_post_execution_validation_completed`;
- `completion_handoff_ready=false`;
- `ready_for_done=false`;
- `commands_executed=0`;
- `validations_executed=0`;
- `rollback_required=false`;
- evento canonico `handoff.recorded`.

## Comando

```bash
scripts/artemis-agent-runtime-completion-handoff.sh --json
```

Com entrada explicita:

```bash
scripts/artemis-agent-runtime-completion-handoff.sh \
  --post-validation-gate artifacts/artemis-agent-runtime-post-execution-validation-gate/run-01/post-execution-validation-gate.json \
  --artifact-root artifacts/artemis-agent-runtime-completion-handoff/run-01 \
  --json
```

## Invariantes

- Nao inicia agentes.
- Nao executa comandos.
- Nao aprova Human Gate.
- Nao faz push, PR, deploy ou escrita remota.
- Nao toca secrets ou producao.
- Nao marca Done sem `post_execution_validation_completed=true`.
- Explica o estado para agentes e humanos nao tecnicos.

## Proximo corte

`TKT-069 - Agent Runtime Completion Review Gate do ARTEMIS Symphony` deve
consumir `completion-handoff.json` e preparar a revisao humana final antes de
qualquer Done externo.
