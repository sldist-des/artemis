# ARCHITECTURE.md

Este repositorio e a base do metodo ARTEMIS.

## Visao geral

ARTEMIS e um processo operacional para trabalho agentic com Codex, Claude Code e humanos. O repositorio guarda a doutrina, os templates, os prompts, os scripts de bootstrap e as evidencias de evolucao do proprio metodo.

## Modulos principais

| Area | Responsabilidade |
|---|---|
| `README.md` | Entrada curta e orientacao de uso. |
| `ARTEMIS_QUICKSTART.md` | Guia rapido de adocao. |
| `fluxo-artemis-claude-codex-v1.3.md` | Documento-base do processo ARTEMIS. |
| `artemis-arquitetura-agentes.md` | Arquitetura universal de agentes. |
| `artemis-github-operating-model.md` | Modelo operacional GitHub. |
| `AGENTS.md` | Contrato canonico para agentes. |
| `CLAUDE.md` | Adaptador fino para Claude Code. |
| `templates/` | Kit copiavel para projetos alvo. |
| `prompts/` | Prompts operacionais reutilizaveis. |
| `docs/agents/` | Registro de agentes, capacidades, ferramentas e handoff. |
| `docs/exec-packs/` | Contratos de execucao por tarefa. |
| `docs/invariants/` | Regras duras do repositorio e do metodo. |
| `scripts/` | Automacoes locais sem dependencia externa. |
| `artifacts/` | Evidencias das rodadas ARTEMIS. |

## Fronteiras

- Regras compartilhadas de agentes ficam em `AGENTS.md`.
- `CLAUDE.md` nao deve duplicar o contrato comum; ele aponta para `AGENTS.md`.
- Templates copiaveis ficam em `templates/`.
- Arquivos que governam este repositorio ficam na raiz ou em `docs/`.
- Evidencias de execucao ficam em `artifacts/<ticket>/run-XX/`.

## Contratos publicos

Os seguintes caminhos sao contratos do kit ARTEMIS e devem mudar com cuidado:

- `templates/AGENTS.md`
- `templates/CLAUDE.md`
- `templates/AI_PROCESS.md`
- `templates/docs/exec-packs/TEMPLATE.md`
- `prompts/context-curator.md`
- `prompts/implementer.md`
- `prompts/reviewer.md`
- `scripts/bootstrap-artemis.sh`

## Decisoes estruturais

- `AGENTS.md` e a fonte canonica para Codex e Claude Code.
- `docs/exec-packs/` e o nome canonico; nao usar o caminho legado de exec plans.
- O repositorio deve funcionar sem instalar dependencias.
- CI minimo deve validar estrutura, shell scripts e convencoes ARTEMIS.

## Zonas de risco

Exigem cuidado e justificativa:

- alteracoes no bootstrap;
- alteracoes no template de Exec Pack;
- alteracoes no contrato `AGENTS.md`/`CLAUDE.md`;
- alteracoes em workflows GitHub;
- alteracoes que tornem o kit dependente de ferramenta externa.
