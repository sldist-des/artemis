# TKT-104 - ARTEMIS Subagent Config Generator Dry Run

## Objetivo

Gerar previews auditaveis de configs de subagentes para Codex, Claude Code e
Antigravity CLI a partir do Socratic Router.

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao multi-agente, runtime supervisionado e seguranca de
delegacao.

## Agentes envolvidos

- Codex executor: gerador dry-run, docs, artifacts, evento e validacao.
- Humano owner: autoridade futura para aceitar preview e permitir instalacao
  real em projeto/worktree selecionado.

## Resultado esperado

O metodo passa a conseguir visualizar como ficariam os subagentes de cada
provedor sem tocar os caminhos reais de runtime.

## Escopo

- Consumir `subagent-socratic-router.json`.
- Gerar preview Codex TOML.
- Gerar preview Claude Code Markdown com frontmatter.
- Gerar preview Antigravity JSON.
- Validar parsing basico dos previews.
- Bloquear instalacao real ate Human Gate futuro.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Escrever em `.codex/agents`.
- Escrever em `.claude/agents`.
- Instalar definicoes reais de Antigravity.
- Autenticar provedores.
- Iniciar runtime.
- Enviar prompts para provedores.
- Executar comandos por provedores.
- Gastar tokens.
- Tocar secrets.
- Mutar remoto, push, PR ou deploy.

## Arquivos

- `docs/agents/ARTEMIS_SUBAGENT_CONFIG_GENERATOR.md`
- `scripts/artemis-subagent-config-generator.sh`
- `artifacts/artemis-subagent-config-generator/run-01/subagent-config-generator.json`
- `artifacts/artemis-subagent-config-generator/run-01/preview/.codex/agents/artemis-codex-architect-verifier.toml`
- `artifacts/artemis-subagent-config-generator/run-01/preview/.claude/agents/artemis-claude-repo-mapper.md`
- `artifacts/artemis-subagent-config-generator/run-01/preview/antigravity/artemis-antigravity-async-validator.json`
- `artifacts/artemis-subagent-config-generator/run-01/SUBAGENT_CONFIG_GENERATOR.md`
- `artifacts/artemis-subagent-config-generator/run-01/STATUS.md`
- `artifacts/artemis-subagent-config-generator/run-01/VALIDATION.md`
- `artifacts/artemis-subagent-config-generator/run-01/HANDOFF.md`
- `artifacts/artemis-subagent-config-generator/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-subagent-config-generator.sh
scripts/artemis-subagent-config-generator.sh --artifact-root artifacts/artemis-subagent-config-generator/run-01 --json
python3 -m json.tool artifacts/artemis-subagent-config-generator/run-01/subagent-config-generator.json
python3 -m json.tool artifacts/artemis-subagent-config-generator/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-subagent-config-generator/run-01/subagent-config-generator.json`
- `artifacts/artemis-subagent-config-generator/run-01/SUBAGENT_CONFIG_GENERATOR.md`
- `artifacts/artemis-subagent-config-generator/run-01/events.json`

## Handoff

Handoff aceito quando o gerador ficar em
`subagent_config_preview_ready`, com tres previews gerados, parsing basico
aprovado e sem escrever configs reais, iniciar agentes, enviar prompts, gastar
tokens ou mutar remoto.

