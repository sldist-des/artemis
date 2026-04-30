# TKT-018 - Renderizar timeline de eventos no Control Plane

## Objetivo

Fazer o ARTEMIS Control Plane consumir o event log canonico como uma timeline read-only.

## Resultado esperado

O Control Plane deve carregar um JSON de eventos local quando servido por HTTP e mostrar uma timeline compacta com evento, estado, produtor, ticket e link de evidencia, sem permitir alterar a fonte canonica.

## Nivel ARTEMIS da execucao

Nivel 2 - visualizacao operacional sem backend.

## Agentes envolvidos

- Designer: define composicao compacta da timeline.
- Implementer: atualiza `control-plane/index.html`.
- Reviewer: valida que eventos nao viram estado canonico.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `control-plane/index.html`
- `control-plane/tasks.json`
- `docs/schemas/artemis-event.schema.json`
- `scripts/artemis-event-log.sh`
- `artifacts/artemis-event-log-schema/run-01/event-log.example.json`

## Escopo

- Carregar event log local quando servido por HTTP.
- Renderizar timeline read-only.
- Mostrar fallback quando event log nao existir.
- Apontar para artifact/evidence quando houver.
- Manter cards e estados atuais funcionando.

## Fora de escopo

- Criar backend.
- Persistir eventos em banco.
- Permitir edicao de eventos pela UI.
- Executar adapters automaticamente.
- Alterar schema canonico.

## Invariantes

- Exec Packs continuam contrato.
- Artifacts continuam evidencia.
- Git continua memoria duravel.
- Timeline e visualizacao, nao fonte de verdade.
- UI deve continuar abrindo sem servidor, usando fallback local.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-events/run-01/STATUS.md`
- `artifacts/artemis-control-plane-events/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-events/run-01/HANDOFF.md`
