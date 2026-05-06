# HANDOFF

## Estado

ARTEMIS esta `ready_with_human_gates` para aplicacao local, com gates humanos externos preservados.

## Para aplicar em um projeto

- Rode scripts/bootstrap-artemis.sh /caminho/do/projeto.
- Edite AGENTS.md, ARCHITECTURE.md e AI_PROCESS.md no projeto alvo.
- Mantenha CLAUDE.md como adaptador fino apontando para AGENTS.md.
- Crie o primeiro Exec Pack em docs/exec-packs/active/.
- Rode lint, testes e scripts/validate-artemis.sh do projeto quando existirem.
- Use branch e worktree por tarefa antes de implementar com agente.
- Registre STATUS.md, VALIDATION.md e HANDOFF.md para toda tarefa material.

## Nao fazer automaticamente

- Nao preencher decisao humana real.
- Nao executar cleanup real.
- Nao criar push/PR remoto sem GitHub configurado pelo humano.
- Nao substituir revisao humana por readiness tecnica.
