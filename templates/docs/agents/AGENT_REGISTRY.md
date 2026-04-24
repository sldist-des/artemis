# Agent Registry

Registre somente agentes que o projeto realmente usa.

| Agente | Obrigatorio | Runtime sugerido | Quando usar | Saidas obrigatorias |
|---|---:|---|---|---|
| Context Curator | sim | Codex ou Claude Code | Preparar Context Pack | Exec Pack, prompt do executor, prompt do revisor |
| Implementer | sim | Claude Code ou Codex | Implementar tarefa no worktree | Diff, validacao, artifacts |
| Reviewer | sim | Codex ou Claude Code | Revisar diff contra contrato | Relatorio de achados e recomendacao |
| Memory Keeper | sim | Codex ou Claude Code | Registrar aprendizado e handoff | Handoff, docs/ADR sugeridos |
| Architecture Steward | opcional | Codex, Claude Code ou humano | Mudanca estrutural | Revisao arquitetural |
| Test Auditor | opcional | Codex ou Claude Code | Mudanca comportamental critica | Lacunas de teste |
| Security Reviewer | opcional | Codex, Claude Code ou humano | Auth, secrets, dados, permissoes | Riscos de seguranca |
| Toolsmith | opcional | Codex ou Claude Code | Criar hooks, scripts, skills | Ferramenta documentada |

