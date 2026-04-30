# TKT-014 - Preparar Codex app-server adapter

## Objetivo

Preparar a integracao futura entre ARTEMIS e Codex app-server sem abandonar o controle terminal-first.

## Resultado esperado

Um contrato local deve mapear threads, turns, items e approvals do Codex app-server para tarefas, tentativas, eventos, Human Gates e evidencias ARTEMIS.

## Nivel ARTEMIS da execucao

Nivel 2 - adapter planejado para runtime externo.

## Agentes envolvidos

- Architect: define mapeamento entre app-server e ARTEMIS.
- Implementer: cria contrato local e stubs read-only quando possivel.
- Reviewer: valida que terminal override e Human Gate continuam preservados.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- `docs/control-plane/artemis-control-plane.md`
- Documentacao oficial do Codex app-server.

## Escopo

- Revisar documentacao oficial do Codex app-server.
- Definir contrato de eventos ARTEMIS.
- Mapear Thread, Turn, Item e Approval para ARTEMIS.
- Definir como eventos alimentam Control Plane e artifacts.
- Nao implementar daemon ainda.

## Fora de escopo

- Rodar app-server em producao.
- Abrir acesso remoto.
- Persistir eventos em banco.
- Substituir terminal.
- Integrar Claude Code.

## Invariantes

- Terminal continua soberano.
- App-server e fonte de eventos, nao dono do metodo.
- Approvals viram Human Gate.
- Exec Pack continua contrato.
- Sem escrita remota automatica.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-codex-app-server-adapter/run-01/STATUS.md`
- `artifacts/artemis-codex-app-server-adapter/run-01/VALIDATION.md`
- `artifacts/artemis-codex-app-server-adapter/run-01/HANDOFF.md`
