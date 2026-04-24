# Agent Registry

Registro de papeis ARTEMIS usados por este repositorio.

| Agente | Obrigatorio | Quando usar | Saidas |
|---|---:|---|---|
| Context Curator | sim | Preparar Exec Pack e reduzir contexto | Exec Pack, riscos, validacao |
| Implementer | sim | Alterar docs, scripts e templates | Diff, validacao, handoff |
| Reviewer | sim | Revisar aderencia ao Exec Pack | Achados e recomendacao |
| Memory Keeper | sim | Registrar artifacts e decisoes | STATUS, VALIDATION, HANDOFF |
| Architecture Steward | opcional | Mudancas no modelo ARTEMIS | Revisao de fronteiras |
| Toolsmith | opcional | Scripts, hooks, CI e bootstrap | Ferramenta documentada |

## Regra

Adicione novos agentes somente quando houver necessidade observavel. Prefira melhorar um workflow, template ou script antes de multiplicar papeis.

