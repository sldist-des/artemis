# TKT-082 - ARTEMIS Portal Human Acceptance Surface Contract

## Objetivo

Definir o contrato verificavel da superficie de aceite humano do portal
ARTEMIS, separando evidencia tecnica de decisao humana explicita.

## Nivel ARTEMIS da execucao

Nivel 2 - contrato operacional local, sem runtime real, sem provider, sem
secrets, sem escrita remota e sem mutacao de estado canonico.

## Agentes envolvidos

- Codex: implementacao e validacao do contrato.
- Humano owner: autoridade futura para aceitar, rejeitar ou deferir trabalho.
- Verifier: consumidor futuro das evidencias antes do handoff para ledger.

## Escopo

- Criar `scripts/artemis-portal-human-acceptance-surface.sh`.
- Criar documentacao do Human Acceptance Surface.
- Criar artefatos locais em `artifacts/artemis-portal-human-acceptance-surface/run-01/`.
- Integrar o novo produtor ao Event Log, Project Graph e Validation Gate.
- Declarar schema de aceite, modelo de decisao, autoridade, politica de UI,
  ponte de eventos e limites de seguranca.

## Fora de escopo

- Registrar aceite real.
- Marcar tarefa como done.
- Fechar Done Ledger.
- Fechar issue, PR ou tarefa remota.
- Iniciar runtime, provider, agente remoto ou sessao paga.
- Executar comandos a partir do portal.
- Tocar secrets, auth, producao, push, deploy ou branch protection.

## Resultado esperado

Um contrato verificavel deve definir decision record, estados de aceite,
autoridade humana, blockers, handoff para Done Ledger e invariantes que impedem
aceite implicito por agente.

## Evidencias obrigatorias

- `artifacts/artemis-portal-human-acceptance-surface/run-01/human-acceptance-surface-contract.json`
- `artifacts/artemis-portal-human-acceptance-surface/run-01/HUMAN_ACCEPTANCE_SURFACE.md`
- `artifacts/artemis-portal-human-acceptance-surface/run-01/events.json`
- `docs/portal/ARTEMIS_PORTAL_HUMAN_ACCEPTANCE_SURFACE.md`
- `scripts/validate-artemis.sh`

## Criterios de aceite

- O contrato reporta `overall=human_acceptance_surface_ready`.
- `acceptance_recorded=false`.
- `accepted=false`.
- `done_ledger_handoff_allowed=false`.
- `task_state_mutated=false`.
- `runtime_execution_allowed=false`.
- `commands_executed=0`.
- `tokens_spent=0`.
- `remote_state_mutated=false`.
- Secrets, prompts brutos, transcripts completos e raw runtime output nao sao
  registrados.
- O Validation Gate reconhece o novo script, doc, artefato e evento canonico.

## Validacao

Executar:

```bash
scripts/artemis-portal-human-acceptance-surface.sh --json
scripts/artemis-validation-gate.sh --json
scripts/validate-artemis.sh
```

## Handoff

Com este corte, o spine supervisionado do portal fica completo como contrato
local: controle de tarefa mostra intencao, evidencia mostra prova e aceite
humano define a decisao explicita antes de qualquer Done Ledger.
