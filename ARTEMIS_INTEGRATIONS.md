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
