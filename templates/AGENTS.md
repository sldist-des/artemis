# AGENTS.md

Este projeto usa ARTEMIS: Arquitetura, Ritmo, Trabalho Estruturado, Memoria, Implementacao e Supervisao.

## Projeto

Descreva aqui, em poucas linhas:

- objetivo do projeto;
- usuarios ou sistemas atendidos;
- dominio principal;
- partes que nao podem quebrar.

## Documentos que agentes devem ler

- `ARCHITECTURE.md`
- `AI_PROCESS.md`
- `ARTEMIS_WORKFLOW.md`
- `docs/invariants/core.md`
- Exec Pack ativo em `docs/exec-packs/active/`
- ADRs relevantes em `docs/decisions/`

## Comandos canonicos

Atualize conforme o projeto:

```bash
# instalar

# lint

# testes

# build
```

## Workflow ARTEMIS

- Toda tarefa relevante deve ter issue ou Exec Pack.
- Um agente escritor por worktree.
- Branch sugerida: `ai/<agente>/<ticket>-<slug>`.
- Worktree sugerida: `worktrees/<ticket>--<agente>`.
- Mudancas fora do escopo devem ser registradas e escaladas.
- Toda entrega deve incluir validacao e handoff.

## Review guidelines

- Trate vazamento de secrets como P0.
- Trate quebra de autenticacao/autorizacao como P0.
- Trate violacao de invariantes arquiteturais como P1.
- Trate mudanca de contrato publico sem documentacao como P1.
- Trate testes ausentes em codigo critico como P1.
- Ignore preferencias cosmeticas salvo quando contrariem padrao documentado.

## Escalar para humano

Escalar antes de:

- alterar producao;
- tocar secrets;
- alterar auth, billing, permissoes ou dados sensiveis;
- criar migracao destrutiva;
- introduzir nova dependencia;
- mudar contrato publico;
- expandir escopo de forma relevante.
