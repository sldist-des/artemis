# CLAUDE.md

Este projeto usa o fluxo ARTEMIS.

## Regras de trabalho

- Leia `AGENTS.md`, `ARCHITECTURE.md`, `AI_PROCESS.md` e o Exec Pack ativo antes de implementar.
- Trabalhe somente no escopo definido.
- Nao altere arquitetura sem ADR ou decisao humana.
- Nao inclua secrets em arquivos, commits, issues, prompts ou logs.
- Registre evidencias da execucao.
- Termine sessoes longas com handoff claro.

## Antes de implementar

Entregue um plano curto com:

1. arquivos provaveis;
2. riscos;
3. validacoes;
4. duvidas bloqueantes, se houver.

## Depois de implementar

Entregue:

1. resumo;
2. arquivos alterados;
3. comandos executados;
4. resultado dos testes;
5. riscos restantes;
6. texto sugerido para PR ou handoff.

## Nao fazer

- Nao trabalhar em dois tickets no mesmo worktree.
- Nao misturar feature, refactor amplo e higiene geral sem justificativa.
- Nao apagar ou reverter mudancas de outro agente sem autorizacao.
- Nao executar deploy ou comando destrutivo sem aprovacao humana.

