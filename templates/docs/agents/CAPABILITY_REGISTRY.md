# Capability Registry

Atualize este arquivo quando uma ferramenta agentic ganhar, perder ou alterar capacidades relevantes.

| Plataforma | Capacidade | Status | Onde usar | Risco | Ultima verificacao | Fonte |
|---|---|---|---|---|---|---|
| Claude Code | Subagents | verificar | pesquisa, revisao, tarefas isoladas | custo/contexto | YYYY-MM-DD | docs oficiais |
| Claude Code | Hooks | verificar | bloqueios, logs, validacao | falso positivo | YYYY-MM-DD | docs oficiais |
| Claude Code | Skills | verificar | workflows repetiveis | drift | YYYY-MM-DD | docs oficiais |
| Codex | CLI | verificar | VPS Linux, terminal | permissoes | YYYY-MM-DD | docs oficiais |
| Codex | codex exec | verificar | automacoes e CI | execucao nao supervisionada | YYYY-MM-DD | docs oficiais |
| Codex | Subagents | verificar | paralelismo explicito | coordenacao | YYYY-MM-DD | docs oficiais |
| OpenAI Agents SDK | Guardrails | verificar | seguranca e validacao | cobertura incompleta | YYYY-MM-DD | docs oficiais |
| OpenAI Agents SDK | Tracing | verificar | observabilidade | dados sensiveis | YYYY-MM-DD | docs oficiais |
| Claude Platform | Managed Agents | verificar | agentes de produto/operacao | acoplamento | YYYY-MM-DD | docs oficiais |

Regra: recurso novo entra primeiro no registry, depois em teste pequeno, depois vira skill, hook, agente ou policy.

