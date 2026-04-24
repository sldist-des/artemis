# Capability Registry

Registro inicial de capacidades relevantes. Confirme documentacao oficial antes de promover qualquer capacidade para politica obrigatoria.

| Plataforma | Capacidade | Status | Onde usar | Risco | Ultima verificacao | Fonte |
|---|---|---|---|---|---|---|
| Codex | AGENTS.md | ativo | contrato comum do repo | drift se duplicado | 2026-04-24 | ambiente local |
| Codex | apply_patch | ativo | edicoes controladas | patch amplo demais | 2026-04-24 | ambiente local |
| Codex | subagents | disponivel | tarefas independentes | coordenacao excessiva | 2026-04-24 | ambiente local |
| Claude Code | CLAUDE.md | previsto | adaptador para runtime | virar segunda fonte | 2026-04-24 | docs do processo |
| Claude Code | subagents/hooks/skills | verificar | automacao futura | dependencia de runtime | 2026-04-24 | verificar docs oficiais |
| GitHub Actions | workflow CI | previsto | validacao automatica | falso senso de cobertura | 2026-04-24 | template local |

## Politica

Quando uma ferramenta mudar capacidade relevante:

1. confirmar em fonte oficial;
2. atualizar este registry;
3. testar em tarefa pequena;
4. promover para template, script, hook ou policy somente depois.

