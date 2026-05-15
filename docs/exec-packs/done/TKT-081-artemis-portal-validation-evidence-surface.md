# TKT-081 - ARTEMIS Portal Validation Evidence Surface Contract

## Objetivo

Definir o contrato de Validation Evidence Surface do ARTEMIS Portal para mostrar
provas, falhas, Human Gates, riscos residuais e lacunas de teste sem aceitar
entrega, mutar estado canonico ou executar comandos.

## Resultado esperado

Um contrato verificavel deve definir evidence record, evidence kinds, status
model, readiness model, display policy, acceptance boundary, event bridge,
evidencia e handoff sem acionar provider, runtime, comando, token spend, aceite
ou remote write.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_TASK_CONTROL_SURFACE.md`
- `docs/portal/ARTEMIS_PORTAL_VALIDATION_EVIDENCE_SURFACE.md`
- `scripts/artemis-portal-validation-evidence-surface.sh`
- `artifacts/artemis-portal-task-control-surface/run-01/task-control-surface-contract.json`
- `artifacts/artemis-validation-gate/run-01/validation-gate.json`
- `artifacts/artemis-project-graph/run-01/project-graph.json`

## Escopo

- Definir Validation Evidence Surface como contrato de interface e eventos.
- Definir schema de evidence record.
- Definir evidence kinds e status model.
- Definir readiness model e display policy para humanos.
- Definir boundary que impede aceite ou done neste corte.
- Definir event bridge sem mutacao de estado.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Aceitar entrega.
- Marcar tarefa como done.
- Fechar Done Ledger.
- Enviar mensagem para provider.
- Receber resposta real de agente.
- Iniciar runtime.
- Executar comando.
- Gastar tokens.
- Guardar prompt bruto, transcript completo, secrets ou raw runtime output.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Evidencia nao e aceite.
- Pass tecnico nao e aprovacao humana.
- Falhas, Human Gates e lacunas `not_tested` aparecem antes de aceite.
- Done exige validacao, aceite humano quando aplicavel e ledger separado.
- Prompt bruto, transcript completo, secrets e raw runtime output nao entram em
  artifacts git.
- Todo evidence card aponta para artifact fonte ou lacuna explicita.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-validation-evidence-surface.sh
scripts/artemis-portal-validation-evidence-surface.sh --artifact-root artifacts/artemis-portal-validation-evidence-surface/run-01 --json
python3 -m json.tool artifacts/artemis-portal-validation-evidence-surface/run-01/validation-evidence-surface-contract.json
python3 -m json.tool artifacts/artemis-portal-validation-evidence-surface/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-validation-evidence-surface/run-01/validation-evidence-surface-contract.json`
- `artifacts/artemis-portal-validation-evidence-surface/run-01/VALIDATION_EVIDENCE_SURFACE.md`
- `artifacts/artemis-portal-validation-evidence-surface/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Validation Evidence Surface estiver
documentado, artifactado, validado e sem aceite, mutacao de tarefa, provider
message, resposta real de agente, runtime, comandos, gasto de token, prompt
bruto, transcript completo, secrets ou mutacao remota.
