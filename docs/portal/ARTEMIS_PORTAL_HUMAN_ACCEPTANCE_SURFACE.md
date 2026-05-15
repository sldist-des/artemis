# ARTEMIS Portal Human Acceptance Surface

O Human Acceptance Surface e o contrato que separa evidencia tecnica de
decisao humana explicita.

Ele nao aceita trabalho automaticamente, nao marca tarefa como done, nao fecha
ledger, nao inicia runtime e nao executa comando. Ele define como uma pessoa
com autoridade pode aceitar, rejeitar ou deferir trabalho depois de ver as
evidencias, falhas, Human Gates, riscos residuais e lacunas de teste.

## Regra central

Evidencia explica. Aceite decide. Ledger registra.

```text
Validation evidence
  -> Human owner decision
  -> Accepted, rejected or deferred
  -> Done Ledger handoff only after explicit accepted decision
```

## Acceptance record

Campos obrigatorios:

- `acceptance_surface_id`
- `project_id`
- `ticket`
- `evidence_surface_id`
- `validation_gate_ref`
- `completion_review_gate_ref`
- `done_ledger_ref`
- `decision`
- `decided_by`
- `decision_authority`
- `reason`
- `accepted_evidence_refs`
- `rejected_evidence_refs`
- `deferred_blocker_refs`
- `residual_risk_acknowledged`
- `human_gate_acknowledged`
- `done_ledger_handoff_allowed`
- `event_refs`
- `decided_at`

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
- `auto_accept_flag`
- `background_approval`
- `implicit_acceptance`

## Decision model

- `accepted`
- `rejected`
- `deferred`
- `needs_more_evidence`
- `blocked_by_human_gate`

## Autoridade

Agentes podem:

- preparar resumo de aceite;
- listar evidencias;
- listar gates e riscos residuais;
- preparar handoff para Done Ledger.

Agentes nao podem:

- registrar aceite por conta propria;
- marcar done;
- fechar tarefa remota;
- aprovar budget;
- aprovar acesso a secret;
- aprovar escrita em producao.

## Regras de enforcement

- Evidencia pode sugerir readiness, mas so o humano owner aceita.
- Este corte nao registra aceite real.
- `accepted` fica bloqueado se existirem checks falhos.
- Human Gates precisam ser reconhecidos explicitamente por uma pessoa antes do
  handoff para Done Ledger.
- Rejeicao e deferimento preservam motivo ou blockers.
- Agentes preparam sumarios e handoffs, mas nao aprovam o proprio trabalho.
- Done Ledger handoff continua bloqueado ate existir decisao real `accepted`.

## Fora de escopo neste corte

- aceitar entrega real;
- marcar tarefa como done;
- fechar ledger;
- fechar issue, PR ou tarefa remota;
- iniciar runtime;
- executar comando;
- enviar mensagem para provider;
- gastar tokens;
- criar branch, worktree, PR, push ou deploy;
- guardar prompt bruto, transcript completo, secrets ou output bruto.

Proximo corte recomendado: `NONE - ARTEMIS Portal supervised control spine complete`.
