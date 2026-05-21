# TKT-097 - ARTEMIS Project Registry Decision Intake

## Objetivo

Criar o intake estruturado de decisao humana para candidatos do Project
Registry, incluindo template preenchivel e validacao de contrato.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de projeto, portal e seguranca de runtime.

## Agentes envolvidos

- Codex executor: contrato, script, artifacts, evento e leitura na home.
- Humano owner: autoridade futura para preencher e assinar a decisao.

## Resultado esperado

O metodo passa a ter um ponto claro para receber uma decisao humana, mas o
estado padrao continua pendente e sem efeito operacional.

## Escopo

- Consumir `project-registry-human-review-gate.json`.
- Gerar `project-registry-decision-template.json`.
- Classificar decisao como `pending`, `recorded` ou `invalid`.
- Emitir artifact e evento de decision intake.
- Atualizar a home para mostrar decisao pendente.
- Manter registro, troca de projeto, runtime, auth, comandos e tokens
  bloqueados.

## Fora de escopo

- Registrar projeto externo.
- Aplicar decisao aprovada.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_DECISION_INTAKE.md`
- `scripts/artemis-portal-project-registry-decision-intake.sh`
- `control-plane/index.html`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-intake.json`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-template.json`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/PROJECT_REGISTRY_DECISION_INTAKE.md`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/STATUS.md`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/VALIDATION.md`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/HANDOFF.md`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-portal-project-registry-decision-intake.sh
scripts/artemis-portal-project-registry-decision-intake.sh --artifact-root artifacts/artemis-portal-project-registry-decision-intake/run-01 --json
python3 -m json.tool artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-intake.json
python3 -m json.tool artifacts/artemis-portal-project-registry-decision-intake/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-intake.json`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/project-registry-decision-template.json`
- `artifacts/artemis-portal-project-registry-decision-intake/run-01/events.json`

## Handoff

Handoff aceito quando o intake classificar a decisao como pendente por padrao,
gerar template preenchivel e preservar registro, troca de projeto e runtime
bloqueados.
