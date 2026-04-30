# TKT-016 - Definir schema canonico de eventos ARTEMIS

## Objetivo

Unificar o formato de eventos ARTEMIS emitidos ou simulados por Exec Packs, GitHub Issues, Codex app-server, Claude Code e futuros runner adapters.

## Resultado esperado

Um schema local versionado deve definir eventos de tarefa, tentativa, runner, tool use, approval, Human Gate, validacao, evidencia e handoff, com campos minimos para o Control Plane consumir sem virar fonte canonica.

## Nivel ARTEMIS da execucao

Nivel 2 - contrato estrutural para adapters.

## Agentes envolvidos

- Architect: define schema e invariantes.
- Implementer: cria schema local e gerador/exemplo read-only quando possivel.
- Reviewer: valida compatibilidade com adapters TKT-013, TKT-014 e TKT-015.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `docs/control-plane/artemis-control-plane.md`
- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- `artifacts/artemis-github-issues-adapter/run-01/`
- `artifacts/artemis-codex-app-server-adapter/run-01/`
- `artifacts/artemis-claude-code-adapter/run-01/`

## Escopo

- Definir schema JSON versionado para eventos ARTEMIS.
- Definir tipos de evento minimos.
- Definir campos obrigatorios e opcionais.
- Definir mapeamento dos adapters existentes para o schema.
- Criar exemplo local de event log.
- Nao implementar daemon ainda.

## Fora de escopo

- Persistir eventos em banco.
- Criar backend.
- Abrir WebSocket.
- Executar agentes automaticamente.
- Escrever em GitHub remoto.

## Invariantes

- Exec Pack continua contrato.
- Artifacts continuam evidencia canonica.
- Git continua memoria duravel.
- Control Plane consome eventos, mas nao vira fonte canonica.
- Human Gate deve ser evento rastreavel, nao estado implicito.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-event-log-schema/run-01/STATUS.md`
- `artifacts/artemis-event-log-schema/run-01/VALIDATION.md`
- `artifacts/artemis-event-log-schema/run-01/HANDOFF.md`
