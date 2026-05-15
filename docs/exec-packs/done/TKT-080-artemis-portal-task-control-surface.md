# TKT-080 - ARTEMIS Portal Task Control Surface Contract

## Objetivo

Definir o contrato de Task Control Surface do ARTEMIS Portal para transformar
intents de conversa em controles visiveis de tarefa sem mutar estado canonico,
iniciar runtime ou executar comandos.

## Resultado esperado

Um contrato verificavel deve definir control record, control kinds, autoridade,
gates, validacao, budget, event bridge, evidencia e handoff sem acionar
provider, runtime, comando, token spend ou remote write.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_AGENT_CONVERSATION.md`
- `docs/portal/ARTEMIS_PORTAL_TASK_CONTROL_SURFACE.md`
- `scripts/artemis-portal-task-control-surface.sh`
- `artifacts/artemis-portal-agent-conversation/run-01/agent-conversation-contract.json`

## Escopo

- Definir Task Control Surface como contrato de interface e eventos.
- Definir schema de control record.
- Definir controles permitidos como intent.
- Definir controles que exigem Human Gate ou runtime gate separado.
- Definir authority model e UI policy.
- Definir event bridge sem mutacao de estado.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Mutar estado canonico de tarefa por clique.
- Enviar mensagem para provider.
- Receber resposta real de agente.
- Iniciar runtime.
- Executar comando.
- Gastar tokens.
- Guardar prompt bruto, transcript completo, secrets ou raw runtime output.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Task control e intencao auditavel, nao execucao.
- Estado canonico continua nos Exec Packs, artifacts, event log e ledger.
- Human Gate continua obrigatorio para runtime sensivel, remote write, secrets e
  budget.
- Command Plan e Execution Gate continuam obrigatorios antes de comando.
- Done exige validacao e review antes de ledger.
- Stop tem prioridade sobre novas acoes de agente.
- Todo controle com impacto em tarefa gera evento e evidencia.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-task-control-surface.sh
scripts/artemis-portal-task-control-surface.sh --artifact-root artifacts/artemis-portal-task-control-surface/run-01 --json
python3 -m json.tool artifacts/artemis-portal-task-control-surface/run-01/task-control-surface-contract.json
python3 -m json.tool artifacts/artemis-portal-task-control-surface/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-task-control-surface/run-01/task-control-surface-contract.json`
- `artifacts/artemis-portal-task-control-surface/run-01/TASK_CONTROL_SURFACE.md`
- `artifacts/artemis-portal-task-control-surface/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Task Control Surface estiver documentado,
artifactado, validado e sem mutacao de tarefa, provider message, resposta real
de agente, runtime, comandos, gasto de token, prompt bruto, transcript completo,
secrets ou mutacao remota.
