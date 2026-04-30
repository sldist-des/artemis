# TKT-001 - Criar base Git do ARTEMIS

## Objetivo

Inicializar o Git como plano de versionamento do projeto ARTEMIS antes de avançar para novas etapas.

## Resultado esperado

O diretorio `/srv/veri` deve ser um repositorio Git em `main`, com arquivos relevantes preparados para commit e arquivos runtime locais ignorados.

## Nivel ARTEMIS da execucao

Nivel 0 - execucao simples com evidencia.

## Agentes envolvidos

- Implementer: inicializa Git, configura ignore e prepara commit.
- Memory Keeper: registra evidencia desta rodada.

## Contexto minimo

- `README.md`
- `ARTEMIS_QUICKSTART.md`
- `artifacts/artemis-bootstrap/run-01/`

## Escopo

- Inicializar repositório Git local.
- Usar branch principal `main`.
- Criar `.gitignore`.
- Preparar primeiro commit rastreavel.
- Registrar evidencias.

## Fora de escopo

- Criar repositorio remoto.
- Fazer push.
- Configurar GitHub Actions, rulesets ou CODEOWNERS reais.
- Criar PR.

## Invariantes

- Nao versionar estado runtime local.
- Nao versionar secrets.
- Nao apagar arquivos existentes.
- Seguir o protocolo Lore para commit.

## Ferramentas autorizadas

- `git init`
- `git branch`
- `git status`
- `git add`
- `git commit`
- leitura local e shell seguro.

## Ferramentas proibidas

- `git reset --hard`
- `git clean`
- push remoto.
- comandos destrutivos.

## Politica de permissao

Sem confirmacao: leitura de status e criacao de `.gitignore`.

Com confirmacao/escalacao: operacoes que gravam metadados Git quando o sandbox montar `.git` como somente leitura.

Nunca nesta tarefa: push, reset destrutivo, clean destrutivo.

## Comandos de validacao

```bash
git status --branch --short --ignored
git diff --cached --stat
git log --oneline --decorate -1
```

## Evidencias obrigatorias

- `artifacts/git-foundation/run-01/STATUS.md`
- `artifacts/git-foundation/run-01/VALIDATION.md`
- `artifacts/git-foundation/run-01/HANDOFF.md`

## Handoff esperado

Resumo do estado Git, commit criado e riscos restantes.

## Escalonar para humano se

- For necessario criar remoto.
- For necessario escolher owner, org ou nome de repositorio GitHub.
- O commit falhar por politica de identidade.

## Entregaveis

- Repositorio Git inicializado.
- Branch `main`.
- `.gitignore`.
- Primeiro commit.

