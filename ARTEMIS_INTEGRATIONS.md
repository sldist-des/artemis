# ARTEMIS Integrations

Este guia e a entrada rapida para conectar um projeto ARTEMIS em Codex CLI,
Claude Code e futuras superficies MCP/REST.

## Instalar em um projeto

Perfil leve:

```bash
scripts/bootstrap-artemis.sh --profile lite /caminho/do/projeto
```

Perfil completo local:

```bash
scripts/bootstrap-artemis.sh --profile full /caminho/do/projeto
```

`lite` instala o contrato comum, templates, guias e helper de integracao.
`full` adiciona Control Plane local e geracao de `control-plane/tasks.json`.

## Verificar

No projeto alvo:

```bash
test -f AGENTS.md && test -f CLAUDE.md && test -f ARTEMIS_WORKFLOW.md && test -d docs/exec-packs/active && test -d artifacts
scripts/artemis-integrations.sh --project . --agent both
```

## Codex CLI

```bash
cd /caminho/do/projeto
codex
```

Cole:

```text
Leia AGENTS.md, ARTEMIS_WORKFLOW.md, ARCHITECTURE.md, AI_PROCESS.md e o Exec Pack ativo em docs/exec-packs/active/. Execute apenas o escopo do Exec Pack, registre validacao, riscos e handoff. Nao faca push, merge, producao, secrets ou mudanca fora de escopo sem Human Gate.
```

## Claude Code

```bash
cd /caminho/do/projeto
claude
```

Cole:

```text
Leia CLAUDE.md primeiro. Depois siga AGENTS.md como fonte canonica comum. Trabalhe somente pelo Exec Pack ativo, apresente plano curto quando a tarefa nao for trivial, registre validacao e termine com handoff claro.
```

## Control Plane local

Quando instalado com `--profile full`:

```bash
scripts/artemis-tasks.sh --output control-plane/tasks.json
python3 -m http.server 4173
```

Abra:

```text
http://127.0.0.1:4173/control-plane/
```

## MCP e REST

ARTEMIS ainda nao deve fingir que possui MCP/REST de runtime quando o contrato
real ainda nao existe. O padrao de integracao sera:

- um servidor unico por workspace ou organizacao;
- ferramentas MCP para ler Exec Packs, eventos, grafo, memoria e gates;
- REST para runners que nao falam MCP;
- health check local;
- viewer local;
- nenhuma execucao remota sem Human Gate.

Esse e o proximo nivel depois do bootstrap portavel.

## Portal futuro

O portal proprio do ARTEMIS deve separar tres camadas de autenticacao:

- auth do portal para humano, time, role e sessao;
- auth dos provedores como OpenAI/Codex, Anthropic/Claude e GitHub;
- auth do projeto/runtime para repositorio, worktree, infra, secrets e deploy.

O plano canonico esta em `docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md` e pode ser
gerado como artifact por:

```bash
scripts/artemis-portal-auth-plan.sh --json
```

Antes de qualquer token real, o portal tambem precisa do contrato do Credential
Vault:

```bash
docs/portal/ARTEMIS_PORTAL_CREDENTIAL_VAULT.md
scripts/artemis-portal-credential-vault.sh --json
```

Depois do vault, o portal precisa do Agent Registry para escolher perfis de
Codex, Claude Code e verificadores por capability, budget, workspace e gate:

```bash
docs/portal/ARTEMIS_PORTAL_AGENT_REGISTRY.md
scripts/artemis-portal-agent-registry.sh --json
```

Depois do registry, o portal precisa do Run Assignment para vincular uma tarefa
a um perfil registrado antes de qualquer launcher ou runtime:

```bash
docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md
scripts/artemis-portal-run-assignment.sh --json
```

Depois do assignment, o portal precisa do Budget and Cost Ledger para vincular
limites de tokens, custo, duracao, agentes e hard stops antes de qualquer gasto:

```bash
docs/portal/ARTEMIS_PORTAL_BUDGET_LEDGER.md
scripts/artemis-portal-budget-ledger.sh --json
```

Depois do budget ledger, o portal precisa do Workspace Session para vincular
assignment e budget a projeto, worktree, branch policy, writer lock e escopo de
escrita antes de qualquer launcher:

```bash
docs/portal/ARTEMIS_PORTAL_WORKSPACE_SESSION.md
scripts/artemis-portal-workspace-session.sh --json
```

Depois do workspace session, o portal precisa do Runtime Session para vincular
workspace, budget, lease policy e launcher preflight a uma sessao supervisionada
antes de qualquer agente real:

```bash
docs/portal/ARTEMIS_PORTAL_RUNTIME_SESSION.md
scripts/artemis-portal-runtime-session.sh --json
```

Depois do runtime session, o portal precisa do Agent Conversation para registrar
mensagens humanas, respostas resumidas de agentes, intents, redaction, eventos e
gates sem transformar conversa em execucao automatica:

```bash
docs/portal/ARTEMIS_PORTAL_AGENT_CONVERSATION.md
scripts/artemis-portal-agent-conversation.sh --json
```

Depois do agent conversation, o portal precisa do Task Control Surface para
converter intents em controles visiveis de tarefa sem mutar estado canonico,
iniciar runtime ou executar comandos sem gates separados:

```bash
docs/portal/ARTEMIS_PORTAL_TASK_CONTROL_SURFACE.md
scripts/artemis-portal-task-control-surface.sh --json
```
