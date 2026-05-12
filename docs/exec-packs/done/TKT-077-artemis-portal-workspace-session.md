# TKT-077 - ARTEMIS Portal Workspace Session Contract

## Objetivo

Definir o contrato de Workspace Session do ARTEMIS Portal para vincular um Run
Assignment e Budget Ledger a um projeto, worktree, branch policy, writer lock e
escopo de escrita antes de qualquer launcher, runtime ou mutacao remota.

## Resultado esperado

Um contrato verificavel deve definir session record, workspace policies, writer
lock, allowed write roots, forbidden paths, dirty-worktree policy, branch policy,
release policy, evidencia e handoff sem criar worktree real nem executar agente.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md`
- `docs/portal/ARTEMIS_PORTAL_BUDGET_LEDGER.md`
- `docs/portal/ARTEMIS_PORTAL_WORKSPACE_SESSION.md`
- `scripts/artemis-portal-workspace-session.sh`
- `artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json`
- `artifacts/artemis-portal-budget-ledger/run-01/budget-ledger-contract.json`

## Escopo

- Definir Workspace Session como contrato pre-launcher.
- Definir schema de session record.
- Definir workspace policies iniciais para escritor unico e revisao read-only.
- Definir writer lock, branch policy, dirty-worktree policy e release policy.
- Definir allowed write roots e forbidden paths.
- Bloquear remote write, branch change, worktree creation e runtime neste corte.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Criar worktree real.
- Trocar branch.
- Autenticar providers.
- Emitir vault lease real.
- Iniciar agente real.
- Executar comando.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Workspace aprovado nao e permissao de execucao.
- Um worktree pode ter no maximo um agente escritor.
- Verificador nao compartilha sessao de escrita com implementador.
- Dirty worktree precisa ser detectado antes de launch.
- Paths proibidos nao podem ser escritos por agentes.
- Remote write segue bloqueado por padrao.
- Session record nao guarda segredo.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-workspace-session.sh
scripts/artemis-portal-workspace-session.sh --artifact-root artifacts/artemis-portal-workspace-session/run-01 --json
python3 -m json.tool artifacts/artemis-portal-workspace-session/run-01/workspace-session-contract.json
python3 -m json.tool artifacts/artemis-portal-workspace-session/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-workspace-session/run-01/workspace-session-contract.json`
- `artifacts/artemis-portal-workspace-session/run-01/WORKSPACE_SESSION.md`
- `artifacts/artemis-portal-workspace-session/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Workspace Session estiver documentado,
artifactado, validado e sem worktree real, branch change, provider auth, lease
real, runtime, comandos, gasto de token ou mutacao remota.
