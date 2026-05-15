# ARTEMIS Portal Validation Evidence Surface

O Validation Evidence Surface e o contrato que mostra provas, falhas, Human
Gates, riscos residuais e lacunas de teste em linguagem humana no portal.

Ele nao aceita entrega, nao marca tarefa como done, nao muda estado canonico,
nao inicia runtime e nao executa comando. Ele organiza evidencia para que uma
pessoa consiga decidir com clareza em um fluxo posterior de aceite humano.

## Regra central

Evidencia explica. Aceite decide. Ledger registra.

```text
Task control
  -> Validation evidence
  -> Failed checks first
  -> Human Gates as decision points
  -> Not-tested gaps visible
  -> Human Acceptance in a separate surface
```

## Evidence record

Campos obrigatorios:

- `evidence_surface_id`
- `project_id`
- `ticket`
- `control_id`
- `validation_gate_ref`
- `project_graph_ref`
- `evidence_kind`
- `claim`
- `source_artifact`
- `status`
- `severity`
- `human_readable_summary`
- `machine_check_ref`
- `blocker_refs`
- `event_refs`
- `generated_at`

Campos proibidos:

- `plaintext_secret`
- `raw_access_token`
- `raw_refresh_token`
- `private_key_material`
- `session_cookie`
- `raw_prompt`
- `full_prompt_transcript`
- `raw_runtime_stdout`
- `raw_runtime_stderr`
- `provider_secret`
- `git_remote_token`
- `ssh_private_key`
- `unredacted_user_data`

## Evidence kinds

- `validation_gate_summary`
- `test_result`
- `static_check`
- `json_schema_check`
- `artifact_presence`
- `graph_consistency`
- `human_gate_status`
- `residual_risk`
- `not_tested_gap`

## Status model

- `passed`
- `failed`
- `human_gate`
- `not_run`
- `not_applicable`
- `blocked`

## Regras de enforcement

- Validation Evidence Surface explica evidencia; nao aceita trabalho.
- Falhas e Human Gates aparecem antes de qualquer fluxo de aceite.
- Prompt bruto, transcript completo, secrets e raw runtime output sao proibidos.
- Cada evidence card aponta para artifact fonte ou lacuna `not_tested`.
- Done e aceite continuam bloqueados ate uma superficie futura registrar a
  decisao humana.
- Sumarios de evidencia separam pass tecnico de aprovacao humana.

## Fora de escopo neste corte

- aceitar entrega;
- marcar tarefa como done;
- fechar ledger;
- iniciar runtime;
- executar comando;
- enviar mensagem para provider;
- gastar tokens;
- criar branch, worktree, PR, push ou deploy;
- guardar prompt bruto, transcript completo, secrets ou output bruto.

Proximo corte recomendado: `TKT-082 - ARTEMIS Portal Human Acceptance Surface Contract`.
