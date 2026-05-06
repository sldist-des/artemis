# ARTEMIS Apply Guide

Este guia e o handoff curto para aplicar ARTEMIS em outro projeto.

## Quando usar

Use ARTEMIS quando o projeto precisa receber trabalho de Codex, Claude Code ou outros agentes sem perder escopo, revisao, validacao e memoria de decisao.

## Instalar em um projeto

Na raiz deste repositorio ARTEMIS, rode:

```bash
scripts/bootstrap-artemis.sh /caminho/do/projeto
```

O bootstrap copia os templates sem sobrescrever arquivos existentes.

## Adaptar no projeto alvo

Depois do bootstrap:

1. Edite `AGENTS.md` com o objetivo real do projeto, comandos canonicos, invariantes e regras de review.
2. Edite `ARCHITECTURE.md` com os modulos, fronteiras e areas sensiveis.
3. Edite `AI_PROCESS.md` com o fluxo operacional do time.
4. Mantenha `CLAUDE.md` como adaptador fino apontando para `AGENTS.md`.
5. Crie o primeiro Exec Pack em `docs/exec-packs/active/`.
6. Rode validacoes do projeto e registre evidencias em `artifacts/`.

## Primeiro ciclo recomendado

```text
Demanda humana
  -> Exec Pack
  -> branch/worktree
  -> implementacao por agente
  -> validacao
  -> review por outro agente
  -> revisao humana
  -> merge
  -> handoff
```

## Gates que continuam humanos

- Secrets, auth, billing, dados sensiveis e producao.
- Push, PR, merge, CODEOWNERS, rulesets e branch protection reais.
- Cleanup de worktrees, locks ou branches quando houver risco de perda.
- Qualquer expansao relevante de escopo.

## Verificar este kit

```bash
scripts/artemis-application-readiness.sh --artifact-root artifacts/artemis-application-readiness/run-01 --json
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
```

O estado esperado do kit local e `ready_with_human_gates`: tecnicamente aplicavel, mas preservando decisoes humanas para GitHub remoto e cleanup real.
