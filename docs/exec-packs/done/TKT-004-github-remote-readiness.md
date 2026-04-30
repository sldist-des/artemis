# TKT-004 - Preparar criacao do remoto GitHub

## Objetivo

Preparar o repositorio ARTEMIS para criacao do remoto GitHub, primeiro push e ativacao posterior de protecoes.

## Resultado esperado

O repositorio deve ter um runbook claro e um script de prontidao que mostre o que falta para criar/pushar o remoto com seguranca.

## Nivel ARTEMIS da execucao

Nivel 1 - preparacao operacional com evidencia.

## Agentes envolvidos

- Context Curator: delimita o que pode ser feito sem criar remoto.
- Implementer: cria runbook e script de prontidao.
- Reviewer: valida scripts e estado Git.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `AI_PROCESS.md`
- `.github/`
- `scripts/validate-artemis.sh`
- `artemis-github-operating-model.md`

## Escopo

- Checar estado local do Git.
- Checar disponibilidade/autenticacao do GitHub CLI.
- Confirmar conta GitHub conectada quando possivel.
- Criar runbook para criacao do remoto.
- Criar script local de prontidao GitHub.
- Registrar bloqueios.

## Fora de escopo

- Criar repositorio remoto.
- Fazer push.
- Ativar branch protection/rulesets.
- Definir owner real em CODEOWNERS.
- Corrigir credencial GitHub local sem acao humana.

## Invariantes

- Nao criar remoto sem owner, nome e visibilidade claros.
- Nao fazer push com token invalido.
- Nao ativar CODEOWNERS sem owners reais.
- Nao usar secrets em arquivos.

## Ferramentas autorizadas

- `git status`
- `git remote -v`
- `gh --version`
- `gh auth status`
- GitHub app read-only para listar conta/repositorios.
- Edicao local.

## Ferramentas proibidas

- `gh repo create`
- `git push`
- branch protection/rulesets remotos.
- escrita remota GitHub.

## Comandos de validacao

```bash
scripts/validate-artemis.sh
scripts/github-readiness.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/github-remote-readiness/run-01/STATUS.md`
- `artifacts/github-remote-readiness/run-01/VALIDATION.md`
- `artifacts/github-remote-readiness/run-01/HANDOFF.md`

## Escalonar para humano se

- For necessario escolher nome do repositorio.
- For necessario escolher visibilidade.
- For necessario autenticar o `gh`.
- For necessario criar remoto ou fazer push.

## Entregaveis

- Runbook GitHub.
- Script de prontidao.
- Artifacts.
- Commit local.
