# ARTEMIS Quickstart

Este guia e a versao curta para iniciar um projeto no fluxo ARTEMIS.

Para a regra operacional completa, leia `ARTEMIS_WORKFLOW.md`.

## Fluxo minimo

```text
Demanda humana
  -> Context Pack
  -> Branch + worktree
  -> Implementacao por agente
  -> Evidencias
  -> Revisao por outro agente
  -> PR
  -> Revisao humana
  -> Merge + handoff
```

## Papeis

| Papel | Responsabilidade |
|---|---|
| Humano Arquiteto | Define prioridade, arquitetura, riscos e merge final. |
| Context Curator | Prepara o Context Pack e os prompts. Nao implementa. |
| Implementer | Altera codigo, testes e docs dentro do escopo. |
| Reviewer | Critica diff, validacao, escopo e arquitetura. |
| Memory Keeper | Atualiza handoff, docs curtas, ADRs e aprendizados. |

## Checklist por tarefa

- [ ] Existe issue ou Exec Pack.
- [ ] Escopo e fora de escopo estao claros.
- [ ] Invariantes e riscos foram listados.
- [ ] Existe branch isolada.
- [ ] Existe worktree isolada para o agente escritor.
- [ ] O agente sabe quais ferramentas pode usar.
- [ ] Validacoes obrigatorias estao no pacote.
- [ ] Evidencias foram registradas.
- [ ] Outro agente ou sessao revisou o resultado.
- [ ] Revisao humana aprovou o merge quando ha risco medio/alto.

## Niveis ARTEMIS

| Nivel | Uso |
|---|---|
| 0 | Tarefa pequena, um executor, evidencia simples. |
| 1 | Context Curator, Implementer e Reviewer. Fluxo minimo recomendado. |
| 2 | Subagentes especializados para pesquisa, testes, seguranca ou docs. |
| 3 | Multi-worktree coordenado para epicos, migracoes ou frentes paralelas. |
| 4 | Harness programavel com SDK, tracing, guardrails e automacao duravel. |

## Regra de ouro

Nao transforme prompt em governanca. Regra importante deve virar arquivo, hook, invariant, template, teste ou policy.
