# TKT-003 - Operacionalizar o proprio repositorio ARTEMIS

## Objetivo

Transformar `/srv/veri` no primeiro projeto ARTEMIS completo, materializando no repositorio real os arquivos que antes existiam apenas como templates.

## Resultado esperado

O repositorio deve conter camada operacional real para GitHub, arquitetura, processo, invariantes, agentes e validacao automatizada minima.

## Nivel ARTEMIS da execucao

Nivel 1 - preparar, executar e revisar com evidencia.

## Agentes envolvidos

- Context Curator: delimita esta rodada.
- Implementer: cria arquivos operacionais.
- Reviewer: valida estrutura e convencoes.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `AGENTS.md`
- `README.md`
- `templates/`
- `artemis-github-operating-model.md`
- `artemis-arquitetura-agentes.md`

## Escopo

- Criar `.github/` real com issue template, PR template, CODEOWNERS seguro e workflow CI minimo.
- Criar `ARCHITECTURE.md` real.
- Criar `AI_PROCESS.md` real.
- Criar `docs/invariants/core.md`.
- Criar `docs/agents/` real.
- Criar script de validacao local/CI.
- Registrar artifacts da rodada.

## Fora de escopo

- Criar remoto GitHub.
- Fazer push.
- Ativar branch protection/rulesets.
- Definir owners reais.
- Instalar dependencias.

## Invariantes

- `AGENTS.md` continua fonte canonica comum.
- `CLAUDE.md` continua adaptador fino.
- `docs/exec-packs/` e o caminho canonico.
- Workflows nao fazem deploy.
- Placeholders ativos de owner nao devem entrar em CODEOWNERS real.

## Ferramentas autorizadas

- Edicao local.
- Shell seguro.
- `scripts/validate-artemis.sh`.
- Git local.

## Ferramentas proibidas

- Push remoto.
- Deploy.
- Instalacao de dependencias.
- Secrets.

## Comandos de validacao

```bash
scripts/validate-artemis.sh
git diff --check
git status --short
```

## Evidencias obrigatorias

- `artifacts/repository-operationalization/run-01/STATUS.md`
- `artifacts/repository-operationalization/run-01/VALIDATION.md`
- `artifacts/repository-operationalization/run-01/HANDOFF.md`

## Escalonar para humano se

- For necessario escolher owner GitHub real.
- For necessario configurar remoto, push ou branch protection.
- O CI exigir dependencia externa.

## Entregaveis

- Arquivos operacionais reais do repositorio.
- Validador local/CI.
- Commit local.

