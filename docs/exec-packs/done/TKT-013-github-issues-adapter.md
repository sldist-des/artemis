# TKT-013 - Criar GitHub Issues adapter

## Objetivo

Preparar o ARTEMIS para usar GitHub Issues como fonte complementar de tarefas sem abandonar Exec Packs.

## Resultado esperado

Um adapter local deve conseguir verificar readiness de GitHub, documentar labels/contrato minimo e, quando houver autenticacao valida, listar issues ARTEMIS sem alterar estado remoto.

## Nivel ARTEMIS da execucao

Nivel 2 - adapter externo com Human Gate.

## Agentes envolvidos

- Architect: define contrato entre Issue, Exec Pack, branch, PR e artifacts.
- Implementer: cria adapter read-only quando autenticacao permitir.
- Reviewer: valida que nenhuma transicao remota ocorre sem permissao.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `artemis-github-operating-model.md`
- `docs/runbooks/github-setup.md`
- `scripts/github-readiness.sh`
- `scripts/artemis-validation-gate.sh`

## Escopo

- Definir contrato de labels ARTEMIS para GitHub Issues.
- Validar readiness local de GitHub.
- Criar adapter read-only se `gh auth` estiver valido.
- Registrar Human Gate quando autenticacao, owners ou rulesets estiverem pendentes.

## Fora de escopo

- Criar issues remotas automaticamente.
- Alterar labels remotas sem autorizacao.
- Criar PR.
- Push automatico.
- Branch protection real.

## Invariantes

- Issue define intencao.
- Exec Pack define contrato.
- Control Plane mostra estado.
- Nenhuma escrita remota sem humano.
- GitHub auth invalido para em Human Gate.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/github-readiness.sh
scripts/artemis-validation-gate.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-github-issues-adapter/run-01/STATUS.md`
- `artifacts/artemis-github-issues-adapter/run-01/VALIDATION.md`
- `artifacts/artemis-github-issues-adapter/run-01/HANDOFF.md`
