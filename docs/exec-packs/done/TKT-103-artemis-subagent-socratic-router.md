# TKT-103 - ARTEMIS Subagent Socratic Router

## Objetivo

Implementar o contrato socratico para decidir quando e como usar subagentes no
metodo ARTEMIS, cobrindo Codex, Claude Code e Antigravity CLI.

## Nivel ARTEMIS da execucao

Nivel 3 - orquestracao multi-agente, runtime supervisionado e seguranca de
delegacao.

## Agentes envolvidos

- Codex executor: contrato, docs, artifacts, evento e validacao.
- Humano owner: autoridade futura para aprovar configuracao real de subagentes,
  auth, runtime, custo e permissao herdada.

## Resultado esperado

O metodo passa a ter um router provider-aware, baseado em perguntas
socraticas, que bloqueia delegacao ambigua e exige escopo, budget, validacao,
handoff e Human Gate antes de qualquer runtime externo.

## Escopo

- Registrar fontes oficiais de Codex, Claude Code e Antigravity CLI.
- Definir Socratic Gate para subagentes.
- Definir perfis de provedor e regras de roteamento.
- Declarar invariantes de seguranca, custo e validacao.
- Emitir artifacts e evento canonico.
- Atualizar registries e validacao do repositorio.

## Fora de escopo

- Criar arquivos reais em `.codex/agents`.
- Criar arquivos reais em `.claude/agents`.
- Criar definicoes reais de Antigravity.
- Autenticar provedores.
- Iniciar runtime.
- Enviar prompts para provedores.
- Executar comandos por provedores.
- Gastar tokens.
- Tocar secrets.
- Mutar remoto, push, PR ou deploy.

## Arquivos

- `docs/agents/ARTEMIS_SUBAGENT_SOCRATIC_ROUTER.md`
- `scripts/artemis-subagent-socratic-router.sh`
- `artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json`
- `artifacts/artemis-subagent-socratic-router/run-01/SUBAGENT_SOCRATIC_ROUTER.md`
- `artifacts/artemis-subagent-socratic-router/run-01/STATUS.md`
- `artifacts/artemis-subagent-socratic-router/run-01/VALIDATION.md`
- `artifacts/artemis-subagent-socratic-router/run-01/HANDOFF.md`
- `artifacts/artemis-subagent-socratic-router/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-subagent-socratic-router.sh
scripts/artemis-subagent-socratic-router.sh --artifact-root artifacts/artemis-subagent-socratic-router/run-01 --json
python3 -m json.tool artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json
python3 -m json.tool artifacts/artemis-subagent-socratic-router/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-subagent-socratic-router/run-01/subagent-socratic-router.json`
- `artifacts/artemis-subagent-socratic-router/run-01/SUBAGENT_SOCRATIC_ROUTER.md`
- `artifacts/artemis-subagent-socratic-router/run-01/events.json`

## Handoff

Handoff aceito quando o router ficar em
`subagent_socratic_router_ready`, com Codex, Claude Code e Antigravity CLI
mapeados, Socratic Gate declarado e sem iniciar subagentes, escrever configs,
enviar prompts, executar comandos, gastar tokens ou mutar remoto.

