# ARTEMIS Subagent Config Generator

Este documento define o gerador dry-run de configs de subagentes do ARTEMIS.

## Intencao

O Socratic Router decide quando uma tarefa pode virar subagente. O Config
Generator transforma essa decisao em previews auditaveis para Codex, Claude
Code e Antigravity CLI.

Este corte nao instala configs reais. Ele escreve somente em:

```text
artifacts/artemis-subagent-config-generator/run-01/preview/
```

## Previews gerados

- Codex: `preview/.codex/agents/artemis-codex-architect-verifier.toml`
- Claude Code: `preview/.claude/agents/artemis-claude-repo-mapper.md`
- Antigravity CLI: `preview/antigravity/artemis-antigravity-async-validator.json`

Os caminhos acima sao previews. Eles nao sao carregados automaticamente pelos
runtimes dos provedores.

## Gate de instalacao

Antes de copiar qualquer preview para caminho real, o ARTEMIS precisa registrar:

- aceite humano do preview;
- projeto e worktree selecionados;
- um escritor por worktree;
- politica de auth do provedor;
- budget e limite de tempo;
- comandos de validacao;
- plano de rollback/delete dos arquivos gerados;
- Human Gate para qualquer risco de secrets, auth, remoto, producao, dinheiro
  ou permissao herdada.

## Invariantes

- Nenhum arquivo real em `.codex/agents` e escrito neste corte.
- Nenhum arquivo real em `.claude/agents` e escrito neste corte.
- Nenhuma definicao real de Antigravity e instalada neste corte.
- Nenhum provedor recebe prompt.
- Nenhum agente e iniciado.
- Nenhum token e gasto.
- Nenhum remoto e mutado.

## Artefato canonico

```bash
scripts/artemis-subagent-config-generator.sh --json
```

Saidas principais:

- `artifacts/artemis-subagent-config-generator/run-01/subagent-config-generator.json`
- `artifacts/artemis-subagent-config-generator/run-01/SUBAGENT_CONFIG_GENERATOR.md`
- `artifacts/artemis-subagent-config-generator/run-01/STATUS.md`
- `artifacts/artemis-subagent-config-generator/run-01/VALIDATION.md`
- `artifacts/artemis-subagent-config-generator/run-01/HANDOFF.md`
- `artifacts/artemis-subagent-config-generator/run-01/events.json`

