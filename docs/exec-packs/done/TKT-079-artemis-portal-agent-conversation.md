# TKT-079 - ARTEMIS Portal Agent Conversation Contract

## Objetivo

Definir o contrato de Agent Conversation do ARTEMIS Portal para mapear mensagens
humanas, respostas de agentes, atualizacoes de tarefa e eventos de runtime em
uma superficie de conversa segura, sem iniciar runtime nem executar comandos.

## Resultado esperado

Um contrato verificavel deve definir message record, sender types, message
kinds, intent policy, redaction policy, routing policy, event bridge, evidencia
e handoff sem enviar mensagens para providers nem guardar prompt bruto.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_RUNTIME_SESSION.md`
- `docs/portal/ARTEMIS_PORTAL_AGENT_CONVERSATION.md`
- `scripts/artemis-portal-agent-conversation.sh`
- `artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json`

## Escopo

- Definir Agent Conversation como contrato de interface e eventos.
- Definir schema de message record.
- Definir sender types, message kinds e intents permitidos.
- Definir intents que exigem gate separado.
- Definir redaction policy para bloquear prompt bruto, secrets e output bruto.
- Definir routing policy para tarefa, status, validacao, Human Gate e stop.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Enviar mensagem para provider.
- Receber resposta real de agente.
- Abrir socket ou stream.
- Iniciar agente real.
- Executar comando.
- Gastar tokens.
- Guardar prompt bruto ou transcript completo.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Conversa aprovada nao e permissao de execucao.
- Command plan e execution gate continuam obrigatorios.
- Human Gate continua obrigatorio para execucao, remote write, segredo e budget.
- Prompt bruto e transcript completo nao entram em artifact git.
- Resposta de agente persistida deve ser resumida ou redigida.
- Stop request tem prioridade sobre novas acoes de agente.
- Mensagem com impacto em tarefa gera evento e evidencia.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-agent-conversation.sh
scripts/artemis-portal-agent-conversation.sh --artifact-root artifacts/artemis-portal-agent-conversation/run-01 --json
python3 -m json.tool artifacts/artemis-portal-agent-conversation/run-01/agent-conversation-contract.json
python3 -m json.tool artifacts/artemis-portal-agent-conversation/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-agent-conversation/run-01/agent-conversation-contract.json`
- `artifacts/artemis-portal-agent-conversation/run-01/AGENT_CONVERSATION.md`
- `artifacts/artemis-portal-agent-conversation/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Agent Conversation estiver documentado,
artifactado, validado e sem provider message, resposta real de agente, socket,
streaming, runtime, comandos, gasto de token, prompt bruto, transcript completo
ou mutacao remota.
