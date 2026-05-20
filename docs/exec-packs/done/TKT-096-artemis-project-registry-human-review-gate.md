# TKT-096 - ARTEMIS Project Registry Human Review Gate

## Objetivo

Criar o gate de revisao humana para candidatos do Project Registry sem permitir
registro automatico, troca de projeto ou runtime.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: contrato, script, artifacts, evento e leitura na home.
- Humano owner: autoridade futura para aprovar, rejeitar ou adiar candidato.

## Resultado esperado

O candidato fica claramente aguardando decisao humana, com schema minimo de
decisao declarado e todos os efeitos operacionais bloqueados.

## Escopo

- Consumir `project-selector-registry-intake.json`.
- Declarar schema de decisao humana do registro de projeto.
- Emitir artifact e evento de Human Gate.
- Atualizar a home para mostrar candidato aguardando decisao.
- Manter registro, troca de projeto, runtime, auth, comandos e tokens
  bloqueados.

## Fora de escopo

- Registrar projeto externo.
- Aprovar candidato sem arquivo de decisao humana.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md`
- `scripts/artemis-portal-project-registry-human-review-gate.sh`
- `control-plane/index.html`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/project-registry-human-review-gate.json`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-human-review-gate.sh
scripts/artemis-portal-project-registry-human-review-gate.sh --artifact-root artifacts/artemis-portal-project-registry-human-review-gate/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-human-review-gate/run-01/project-registry-human-review-gate.json
python3 -m json.tool artifacts/artemis-portal-project-registry-human-review-gate/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/project-registry-human-review-gate.json`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md`
- `artifacts/artemis-portal-project-registry-human-review-gate/run-01/events.json`

## Handoff

Handoff aceito quando o candidato estiver em Human Gate explicito, com decisao
pendente e sem liberar registro, troca de projeto ou runtime.
