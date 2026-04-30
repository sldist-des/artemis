# TKT-002 - Canonizar AGENTS.md como guia comum

## Objetivo

Padronizar `AGENTS.md` como fonte canonica comum para Codex, Claude Code e outros agentes, deixando `CLAUDE.md` como adaptador fino.

## Resultado esperado

O projeto e o starter kit devem evitar duplicacao entre `AGENTS.md` e `CLAUDE.md`, reduzindo risco de drift entre agentes.

## Nivel ARTEMIS da execucao

Nivel 0 - ajuste documental e operacional simples.

## Agentes envolvidos

- Implementer: atualiza guias.
- Reviewer: verifica consistencia de referencias.
- Memory Keeper: registra evidencia.

## Contexto minimo

- `templates/AGENTS.md`
- `templates/CLAUDE.md`
- `AGENTS.md`
- `CLAUDE.md`

## Escopo

- Criar `AGENTS.md` raiz.
- Criar `CLAUDE.md` raiz como adaptador.
- Atualizar template `CLAUDE.md`.
- Atualizar documentacao curta que menciona o papel dos guias.
- Registrar artifacts.

## Fora de escopo

- Criar configuracao real de Claude Code.
- Criar subagents ou hooks nesta rodada.
- Configurar Codex ou GitHub remoto.

## Invariantes

- Regras compartilhadas ficam em `AGENTS.md`.
- `CLAUDE.md` nao deve virar uma segunda fonte de verdade.
- O kit deve continuar aplicavel a qualquer projeto.

## Ferramentas autorizadas

- Edicao local.
- `rg`, `sed`, `git diff`, `git status`.
- Commit Git local.

## Ferramentas proibidas

- Push remoto.
- Instalacao de dependencias.
- Alteracoes em producao.

## Comandos de validacao

```bash
rg -n "AGENTS.md|CLAUDE.md" README.md ARTEMIS_QUICKSTART.md templates/CLAUDE.md AGENTS.md CLAUDE.md
git diff --check
```

## Evidencias obrigatorias

- `artifacts/agent-guide-canon/run-01/STATUS.md`
- `artifacts/agent-guide-canon/run-01/VALIDATION.md`
- `artifacts/agent-guide-canon/run-01/HANDOFF.md`

## Escalonar para humano se

- For desejado manter regras duplicadas entre Claude e Codex.
- For necessario escrever configuracoes especificas de runtime Claude Code.

## Entregaveis

- Guias canonicos atualizados.
- Templates ajustados.
- Commit local.

