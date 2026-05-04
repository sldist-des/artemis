# ARTEMIS

ARTEMIS e um metodo operacional para trabalhar com agentes de IA em projetos de software sem perder arquitetura, rastreabilidade e controle humano.

Significado operacional:

```text
Arquitetura, Ritmo, Trabalho Estruturado, Memoria, Implementacao e Supervisao
```

Regra central:

> O humano governa. O contexto prepara. O agente executa. Outro agente critica. O repositorio preserva a memoria.

## Para que serve

Use ARTEMIS quando um projeto vai receber trabalho de Claude Code, Codex ou outros agentes de codigo e precisa de:

- escopo claro antes de implementar;
- worktrees e branches separados por tarefa;
- evidencias de validacao;
- revisao humana orientada por contrato;
- documentacao curta que sobreviva entre sessoes;
- um processo aplicavel tanto ao humano quanto ao AI coder.

## Documentos-base

- `fluxo-artemis-claude-codex-v1.3.md`: processo completo.
- `artemis-arquitetura-agentes.md`: arquitetura universal de agentes.
- `artemis-github-operating-model.md`: modelo operacional com GitHub.

## Starter kit

O diretorio `templates/` contem arquivos prontos para copiar para qualquer projeto:

- `AGENTS.md`
- `CLAUDE.md`
- `ARCHITECTURE.md`
- `AI_PROCESS.md`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/artemis_task.yml`
- `.github/CODEOWNERS`
- `docs/exec-packs/TEMPLATE.md`
- `docs/invariants/core.md`
- `docs/agents/*`

O diretorio `prompts/` contem prompts prontos para:

- `context-curator.md`
- `implementer.md`
- `reviewer.md`

## Guia canonico de agentes

Use `AGENTS.md` como fonte canonica para Codex, Claude Code e outros agentes.

Use `CLAUDE.md` apenas como adaptador fino para Claude Code, apontando para `AGENTS.md` e registrando somente diferencas especificas do runtime Claude.

## Workflow operacional

Use `ARTEMIS_WORKFLOW.md` como contrato de execucao: estados, dispatch, regras de parada, validation gates, evidencias e escalonamento humano.

## ARTEMIS Control Plane

O ARTEMIS agora inclui uma primeira superficie visual local:

```text
control-plane/index.html
```

Abra esse arquivo no navegador para acompanhar o fluxo por estados: intake, contexto, pronto, execucao, revisao, decisao humana e concluido. Quando servido por HTTP, ele tenta carregar `control-plane/tasks.json`; quando aberto diretamente sem acesso ao JSON, usa o seed local e `localStorage`.

Quando servido por HTTP, o Control Plane tambem tenta carregar o event log local em `artifacts/artemis-event-log-schema/run-01/event-log.example.json` e renderiza uma timeline read-only de eventos, estados, produtores e evidencias. A timeline nao altera estado canonico.

Gere a fonte local de tarefas com:

```bash
scripts/artemis-tasks.sh --output control-plane/tasks.json
```

Simule dispatch sem iniciar agentes com:

```bash
scripts/artemis-dry-run.sh
```

Verifique o workspace planejado antes de executar:

```bash
scripts/artemis-workspace.sh --ticket TKT-020
```

Materialize um workspace apenas com flag explicita:

```bash
scripts/artemis-workspace.sh --ticket TKT-021 --artifact-root artifacts/artemis-workspace-materialization/run-01 --materialize
```

Prepare ou execute uma tentativa local supervisionada com:

```bash
scripts/artemis-runner.sh --ticket TKT-000 --command "scripts/validate-artemis.sh"
scripts/artemis-runner.sh --ticket TKT-000 --command "scripts/validate-artemis.sh" --execute
```

Cada tentativa registra `dry-run.json`, `workspace.json`, `COMMAND.txt`, `RESULT.md` e `events.json`.

Rode o Validation Gate antes de handoff:

```bash
scripts/artemis-validation-gate.sh
```

Verifique o adapter read-only de GitHub Issues com:

```bash
scripts/artemis-github-issues.sh
```

Verifique o contrato read-only do Codex app-server com:

```bash
scripts/artemis-codex-app-server.sh
```

Verifique o contrato read-only do Claude Code com:

```bash
scripts/artemis-claude-code.sh
```

Gere um event log ARTEMIS local de exemplo com:

```bash
scripts/artemis-event-log.sh
```

Adapters tambem registram `events.json` nos seus artifacts quando executados com `--artifact-root`.

## Como aplicar em um projeto

1. Copie os templates para a raiz do projeto alvo.
2. Edite `AGENTS.md` e `ARCHITECTURE.md` com o contexto real do projeto; ajuste `CLAUDE.md` somente se houver diferencas especificas do Claude Code.
3. Crie um Exec Pack em `docs/exec-packs/active/` para cada tarefa relevante.
4. Trabalhe em branch e worktree isoladas.
5. Rode validacoes e registre evidencias.
6. Abra PR com o template ARTEMIS.
7. Solicite revisao de IA e revisao humana.
8. Depois do merge, mova o Exec Pack para `done/` e registre handoff.

## Bootstrap rapido

```bash
./scripts/bootstrap-artemis.sh /caminho/do/projeto
```

O script copia o kit base sem sobrescrever arquivos existentes. Revise manualmente os arquivos criados antes de usar em producao.
