# TKT-017 - Fazer adapters emitirem eventos canonicos ARTEMIS

## Objetivo

Atualizar os adapters existentes para emitirem eventos no schema canonico ARTEMIS junto com seus JSONs especificos.

## Resultado esperado

O adapter de issues, Codex app-server, Claude Code e Validation Gate devem produzir artifacts `events.json` ou `event-log.example.json` compativeis com `docs/schemas/artemis-event.schema.json`.

## Nivel ARTEMIS da execucao

Nivel 2 - compatibilidade estrutural entre adapters.

## Agentes envolvidos

- Architect: garante que o envelope comum permanece pequeno.
- Implementer: atualiza scripts dos adapters.
- Reviewer: valida que dados especificos continuam em `payload`.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `docs/schemas/artemis-event.schema.json`
- `docs/schemas/artemis-event-log.schema.json`
- `scripts/artemis-event-log.sh`
- `scripts/artemis-github-issues.sh`
- `scripts/artemis-codex-app-server.sh`
- `scripts/artemis-claude-code.sh`
- `scripts/artemis-validation-gate.sh`

## Escopo

- Fazer cada adapter emitir eventos canonicos.
- Manter JSON especifico atual para diagnostico.
- Atualizar Validation Gate para checar eventos.
- Atualizar docs do workflow.

## Fora de escopo

- Criar backend.
- Persistir em banco.
- Renderizar timeline no Control Plane.
- Executar runners reais.
- Escrever em remoto.

## Invariantes

- Envelope comum nao deve crescer para acomodar detalhe especifico de runtime.
- Detalhe especifico fica em `payload`.
- Artifacts continuam canonicos.
- Human Gate segue explicito.
- Sem nova dependencia.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
scripts/artemis-event-log.sh --json
```

## Evidencias obrigatorias

- `artifacts/artemis-adapter-events/run-01/STATUS.md`
- `artifacts/artemis-adapter-events/run-01/VALIDATION.md`
- `artifacts/artemis-adapter-events/run-01/HANDOFF.md`
