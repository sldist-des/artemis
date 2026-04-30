# TKT-015 - Preparar Claude Code adapter

## Objetivo

Preparar a integracao futura entre ARTEMIS e Claude Code sem duplicar o contrato comum definido em `AGENTS.md`.

## Resultado esperado

Um contrato local deve mapear Claude Code headless, hooks, subagents, logs e eventos de tool use para Runner Adapter, eventos, Human Gates e evidencias ARTEMIS.

## Nivel ARTEMIS da execucao

Nivel 2 - adapter planejado para runtime externo.

## Agentes envolvidos

- Architect: define mapeamento entre Claude Code e ARTEMIS.
- Implementer: cria contrato local e stubs read-only quando possivel.
- Reviewer: valida que `AGENTS.md` segue canonico e `CLAUDE.md` continua adaptador fino.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `AGENTS.md`
- `CLAUDE.md`
- `ARTEMIS_WORKFLOW.md`
- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- Documentacao oficial atual do Claude Code quando o ticket for executado.

## Escopo

- Revisar superficie oficial do Claude Code relevante para headless, hooks, subagents e logs.
- Definir contrato de eventos ARTEMIS equivalente ao adapter Codex.
- Mapear execucao headless para tentativa supervisionada.
- Mapear hooks para guardrails e evidencia.
- Mapear subagents para agentes especializados sob `AGENTS.md`.
- Nao implementar daemon ainda.

## Fora de escopo

- Rodar Claude Code em producao.
- Substituir `AGENTS.md` por `CLAUDE.md`.
- Abrir acesso remoto.
- Persistir eventos em banco.
- Criar integracao bidirecional com GitHub.

## Invariantes

- `AGENTS.md` continua fonte canonica.
- `CLAUDE.md` continua adaptador fino.
- Hooks que apontarem risco viram Human Gate.
- Exec Pack continua contrato.
- Sem escrita remota automatica.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-claude-code-adapter/run-01/STATUS.md`
- `artifacts/artemis-claude-code-adapter/run-01/VALIDATION.md`
- `artifacts/artemis-claude-code-adapter/run-01/HANDOFF.md`
