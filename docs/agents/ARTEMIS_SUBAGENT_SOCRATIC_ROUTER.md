# ARTEMIS Subagent Socratic Router

Este documento define como o ARTEMIS decide quando usar subagentes em Codex,
Claude Code e Antigravity CLI.

## Intencao

Subagente nao e atalho para falta de clareza. No ARTEMIS, subagente e uma
delegacao especializada, limitada, verificavel e reversivel.

Antes de qualquer runtime receber trabalho, o metodo deve responder:

1. Qual e o unico resultado esperado?
2. Por que delegar e melhor do que executar na sessao atual?
3. Qual e o escopo exato de leitura, escrita e proibicao?
4. A tarefa e independente de outro escritor ativo?
5. Qual provedor combina com o formato da tarefa?
6. Qual validacao prova sucesso?
7. Qual limite de token, tempo e concorrencia se aplica?
8. Ha risco de secrets, auth, remoto, producao, dinheiro ou permissao herdada?
9. O que o subagente deve devolver em sucesso, falha ou bloqueio?

Se uma resposta essencial estiver vazia, o ARTEMIS nao lanca subagente. Ele
refina o Exec Pack, pede decisao humana quando necessario ou executa localmente.

## Fontes oficiais verificadas

- Codex subagents: https://developers.openai.com/codex/subagents
- Claude Code sub-agents: https://code.claude.com/docs/en/sub-agents
- Antigravity CLI: https://antigravity.google/docs/cli-using
- Antigravity subagents: https://antigravity.google/docs/subagents

## Lanes de provedor

### Codex

Use Codex quando a tarefa exigir raciocinio de engenharia profundo,
implementacao multi-arquivo, revisao de codigo, arquitetura, testes ou
validacao forte.

Superficie esperada:

- Projeto: `.codex/agents/*.toml`
- Usuario: `~/.codex/agents/*.toml`
- Campos minimos: `name`, `description`, `prompt`
- Campo opcional relevante: `tools`

Regra ARTEMIS: Codex e preferido para cortes complexos e de alto valor, desde
que exista ownership de worktree, escopo de escrita e Validation Gate.

### Claude Code

Use Claude Code para mapear repositorios, entender linguagem/framework, fazer
fatias medias e produzir handoff/documentacao com checkpoints curtos.

Superficie esperada:

- Projeto: `.claude/agents/*.md`
- Usuario: `~/.claude/agents/*.md`
- Arquivo Markdown com frontmatter YAML
- Campos comuns: `name`, `description`, `tools`, `model`, `color`

Regra ARTEMIS: Claude Code deve receber tarefas curtas ou medias, com
handoff claro. Evite tarefas longas sem checkpoints.

### Antigravity CLI

Use Antigravity CLI apenas para lanes assincronas, isoladas e explicitamente
aprovadas. Como subagentes podem herdar escopos/permissoes do pai, ARTEMIS
trata esta superficie como maior risco por padrao.

Regra ARTEMIS: qualquer lane Antigravity com permissao herdada, escrita,
rede, auth, secrets, remoto ou producao exige Human Gate antes de execucao.
O padrao inicial e dry-run.

## Contrato minimo de lancamento

Um lancamento real deve registrar:

- `task_id`
- `exec_pack`
- `outcome`
- `provider_id`
- `subagent_profile`
- `read_scope`
- `write_scope`
- `forbidden_scope`
- `budget_policy`
- `timeout_minutes`
- `validation_commands`
- `handoff_artifacts`
- `human_gate_policy`

## Invariantes

- Um escritor por worktree.
- Nenhum subagente para tarefa ambigua.
- Nenhum provider recebe prompt antes de escopo, validacao e budget.
- Human Gate antes de secrets, auth, remoto, producao, dinheiro ou permissoes
  herdadas amplas.
- Toda saida de subagente passa por Validation Gate antes de Done Ledger.
- Subagentes nao substituem o terminal-control quando o humano/Codex precisa de
  supervisao fina.

## Artefato canonico

O contrato executavel deste corte e gerado por:

```bash
scripts/artemis-subagent-socratic-router.sh --json
```

Saida principal:

- `artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json`
- `artifacts/artemis-subagent-socratic-router/run-01/SUBAGENT_SOCRATIC_ROUTER.md`
- `artifacts/artemis-subagent-socratic-router/run-01/STATUS.md`
- `artifacts/artemis-subagent-socratic-router/run-01/VALIDATION.md`
- `artifacts/artemis-subagent-socratic-router/run-01/HANDOFF.md`
- `artifacts/artemis-subagent-socratic-router/run-01/events.json`

