# TKT-078 - ARTEMIS Portal Runtime Session Contract

## Objetivo

Definir o contrato de Runtime Session do ARTEMIS Portal para vincular Workspace
Session, Budget Ledger, Credential Vault policy e Launcher Preflight a uma
sessao supervisionada antes de qualquer agente, comando ou gasto real.

## Resultado esperado

Um contrato verificavel deve definir runtime session record, lifecycle gates,
supervision policy, heartbeat, command boundary, transcript policy, stop rules,
evidencia e handoff sem iniciar runtime real.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_WORKSPACE_SESSION.md`
- `docs/portal/ARTEMIS_PORTAL_RUNTIME_SESSION.md`
- `scripts/artemis-portal-runtime-session.sh`
- `artifacts/artemis-portal-workspace-session/run-01/workspace-session-contract.json`
- `artifacts/artemis-agent-runtime-launcher-preflight/run-01/launcher-preflight.json`
- `artifacts/artemis-portal-credential-vault/run-01/credential-vault-contract.json`

## Escopo

- Definir Runtime Session como contrato pre-execution.
- Definir schema de runtime session record.
- Definir lifecycle gates.
- Definir supervision policy, heartbeat e transcript policy.
- Definir command boundary para impedir comandos ad hoc.
- Definir stop rules de segredo, budget, workspace, validacao e humano.
- Bloquear runtime, agent start, command execution, streaming e remote write
  neste corte.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Autenticar providers.
- Emitir vault lease real.
- Abrir socket ou stream.
- Iniciar agente real.
- Executar comando.
- Gastar tokens.
- Armazenar stdout/stderr bruto.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Runtime Session aprovado nao e permissao de comando.
- Command plan e execution gate continuam obrigatorios.
- Human Gate continua obrigatorio para execucao real e remote write.
- Runtime nao guarda segredo.
- Runtime nao guarda stdout/stderr bruto nem prompt completo.
- Todo estado futuro de runtime precisa gerar evento e evidencia.
- Stop humano e budget hard-stop nao podem ser ignorados.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-runtime-session.sh
scripts/artemis-portal-runtime-session.sh --artifact-root artifacts/artemis-portal-runtime-session/run-01 --json
python3 -m json.tool artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json
python3 -m json.tool artifacts/artemis-portal-runtime-session/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-runtime-session/run-01/runtime-session-contract.json`
- `artifacts/artemis-portal-runtime-session/run-01/RUNTIME_SESSION.md`
- `artifacts/artemis-portal-runtime-session/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Runtime Session estiver documentado,
artifactado, validado e sem auth real, lease real, socket, streaming, runtime,
agentes, comandos, gasto de token, stdout/stderr bruto ou mutacao remota.
