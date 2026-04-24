# GitHub Setup Runbook

Este runbook leva o repositorio ARTEMIS local para o GitHub.

## Estado atual esperado

```bash
git status --branch --short --ignored
scripts/validate-artemis.sh
scripts/github-readiness.sh
```

## Decisoes humanas antes de criar remoto

Definir:

- owner: usuario ou organizacao GitHub;
- nome do repositorio;
- visibilidade: `private` ou `public`;
- owners reais para CODEOWNERS;
- se `main` exigira PR antes de merge desde o inicio.

Padrao conservador recomendado:

```text
owner: sldist-des
repo: artemis
visibility: private
```

## Autenticacao do GitHub CLI

Se `gh auth status` reportar token invalido:

```bash
gh auth login -h github.com
```

Depois validar:

```bash
gh auth status
```

## Criar remoto

Substitua os valores antes de executar:

```bash
gh repo create OWNER/REPO --private --source=. --remote=origin --push
```

Para repositorio publico:

```bash
gh repo create OWNER/REPO --public --source=. --remote=origin --push
```

## Validar apos push

```bash
git remote -v
gh repo view OWNER/REPO --web
gh workflow list
```

## Protecoes recomendadas em `main`

Ativar no GitHub:

- exigir PR antes de merge;
- exigir status check `Validate ARTEMIS repository`;
- exigir conversa resolvida;
- bloquear force push;
- bloquear delecao;
- exigir revisao humana;
- ativar CODEOWNERS somente depois de trocar placeholders por owners reais.

## Primeiro comentario de handoff no GitHub

Ao abrir o primeiro PR real, usar:

```md
## ARTEMIS Handoff

### O que foi entregue

### Arquivos principais alterados

### Evidencias
- CI:
- Testes locais:
- Revisao IA:

### Riscos restantes

### Decisoes tomadas

### Pendencias

### Recomendacao
- [ ] pronto para revisao humana
- [ ] precisa de ajuste
- [ ] precisa de decisao arquitetural
```
