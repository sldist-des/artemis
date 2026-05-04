# ARTEMIS Workflow

Este arquivo define o contrato operacional do ARTEMIS. Ele deve ser lido por humanos, Codex, Claude Code e futuros runners antes de executar tarefas relevantes.

O workflow e propositalmente terminal-first: o Control Plane mostra estado, mas Git, Exec Packs, artifacts e validacao continuam sendo a fonte de verdade.

## Unidade de trabalho

Toda tarefa relevante deve ter um Exec Pack.

O Exec Pack define:

- intencao;
- escopo;
- fora de escopo;
- invariantes;
- ferramentas permitidas e proibidas;
- comandos de validacao;
- evidencias obrigatorias;
- criterio de handoff.

Artifacts registram o que aconteceu durante a execucao. Commits registram decisoes duraveis pelo Lore Commit Protocol.

## Estados oficiais

| Estado | Significado | Entrada minima | Saida esperada |
|---|---|---|---|
| Intake | Pedido bruto ainda sem contrato | titulo e intencao | decisao de criar ou rejeitar Exec Pack |
| Context | Contexto em preparo | pedido, referencias e risco inicial | Exec Pack completo |
| Ready | Tarefa pronta para execucao | escopo, validacao, owner e artifacts previstos | workspace ou branch definido |
| Running | Agente ou humano executando | workspace, runner e comandos autorizados | diff, logs e evidencias parciais |
| Validating | Gates em execucao | diff e comandos definidos | resultados de validacao |
| Review | Revisao tecnica ou IA | diff, evidencias e riscos | achados resolvidos ou escalados |
| Human Gate | Decisao humana necessaria | motivo claro e opcoes | aprovar, rejeitar, dividir ou desbloquear |
| Handoff | Entrega registrada | validacao, revisao e decisao | artifact final e commit quando aplicavel |
| Done | Trabalho arquivado | handoff completo | nenhum |
| Blocked | Trabalho impedido | causa, impacto e proxima acao | remover bloqueio ou cancelar |

## Elegibilidade para execucao

Uma tarefa pode sair de `Ready` para `Running` somente quando:

- existe Exec Pack;
- o escopo esta claro;
- o owner esta definido;
- comandos de validacao estao listados;
- riscos de segredo, producao, permissao ou remoto foram avaliados;
- nao ha mudanca fora de escopo pendente sem registro.

Se qualquer item acima faltar, a tarefa volta para `Context` ou vai para `Human Gate`.

## Regras de dispatch

Dispatch e a decisao de iniciar ou nao um runner.

Ordem padrao:

1. Humano ou agente cria/ajusta Exec Pack.
2. ARTEMIS avalia elegibilidade.
3. Se elegivel, seleciona runner.
4. Runner executa em workspace controlado.
5. Validacao roda antes de handoff.
6. Revisao decide se volta para `Running`, vai para `Human Gate` ou segue para `Handoff`.

Nenhum runner deve iniciar quando:

- a tarefa toca secrets;
- a tarefa altera producao;
- a tarefa exige push, merge, branch protection ou owner real sem autorizacao humana;
- o escopo e materialmente ambiguo;
- validacao minima nao existe;
- ha risco de sobrescrever trabalho humano nao compreendido.

## Matriz de runners

| Runner | Uso principal | Pode executar | Deve parar em Human Gate quando |
|---|---|---|---|
| Humano | decisao, merge, credenciais, producao | qualquer tarefa autorizada | risco precisa ser reavaliado |
| Codex CLI | implementacao local, refactor, validacao | tarefas com escopo e comandos claros | push, segredo, producao, regra remota ou decisao de produto |
| Codex app-server | runtime rico futuro | captura de eventos, threads, approvals | terminal override for necessario |
| Claude Code | runner paralelo futuro | implementacao ou revisao por contrato comum | hooks apontarem risco ou permissao pendente |
| GitHub Actions | validacao remota futura | checks automatizados | falha exigir decisao humana |

Codex e Claude seguem `AGENTS.md`. `CLAUDE.md` deve continuar sendo apenas adaptador fino.

## Regras de parada

Um runner deve parar quando:

- validacao falha e nao ha correcao obvia dentro do escopo;
- precisa de permissao humana;
- detecta secret;
- detecta alteracao fora de escopo;
- encontra conflito com mudanca humana;
- precisa mudar arquitetura alem do Exec Pack;
- a tarefa foi concluida e o handoff foi registrado.

Parar nao e falhar. Parar com motivo claro e uma transicao valida para `Human Gate`, `Blocked`, `Review` ou `Handoff`.

## Validation Gate

Todo handoff deve registrar o que foi validado.

Comandos canonicos deste repositorio:

```bash
scripts/validate-artemis.sh
scripts/github-readiness.sh
sh -n scripts/bootstrap-artemis.sh
git status --branch --short --ignored
```

Para projetos alvo, acrescente os comandos nativos do projeto:

- lint;
- typecheck;
- testes unitarios;
- build;
- e2e/smoke;
- screenshot ou visual QA para UI;
- security review quando houver superficie sensivel.

Falha de validacao impede `Done`. A tarefa deve ir para `Running`, `Review` ou `Blocked`.

## Evidencia obrigatoria

Cada execucao relevante deve produzir artifacts:

```text
artifacts/<slug>/run-<nn>/STATUS.md
artifacts/<slug>/run-<nn>/VALIDATION.md
artifacts/<slug>/run-<nn>/HANDOFF.md
```

`STATUS.md` registra estado e acoes.
`VALIDATION.md` registra comandos, resultados e gaps.
`HANDOFF.md` registra entrega, riscos e proxima acao.

Screenshots, logs, diffs e outputs extensos podem ser anexados no mesmo diretorio quando forem necessarios para provar o resultado.

## Politica de escalonamento humano

Escalar antes de:

- criar remoto GitHub;
- fazer push;
- alterar producao;
- tocar secrets;
- configurar owners, rulesets ou branch protection reais;
- introduzir nova dependencia;
- expandir escopo de forma relevante;
- aceitar mudanca de contrato publico;
- ignorar falha de validacao.

O escalonamento deve incluir:

- o que esta bloqueado;
- por que o agente nao deve decidir sozinho;
- opcoes concretas;
- efeito de cada opcao.

## Git e commits

Toda mudanca deve ser versionada.

Commits feitos por agentes devem seguir o Lore Commit Protocol de `AGENTS.md`: linha de intencao, contexto e trailers como `Constraint`, `Rejected`, `Confidence`, `Scope-risk`, `Directive`, `Tested` e `Not-tested` quando agregarem valor.

Push, merge e configuracoes remotas exigem permissao humana e credenciais validas.

## Control Plane

O Control Plane mostra estado operacional. Ele nao substitui Exec Packs, artifacts, Git ou validacao.

O task source local e gerado por:

```bash
scripts/artemis-tasks.sh --output control-plane/tasks.json
```

Esse script le Exec Packs de `docs/exec-packs/active/` e `docs/exec-packs/done/` sem alterar os arquivos de origem. O Control Plane pode consumir `control-plane/tasks.json` quando servido por HTTP e deve tratar qualquer movimento manual como visualizacao temporaria.

Antes de iniciar qualquer runner, simule a decisao de dispatch:

```bash
scripts/artemis-dry-run.sh
scripts/artemis-dry-run.sh --json
```

O dry-run nunca inicia agentes, nao cria worktrees e nao altera Exec Packs. Ele classifica tarefas como `eligible`, `blocked`, `human_gate` ou `done` e inclui o plano de workspace quando a tarefa for elegivel.

Antes de executar uma tentativa, verifique o workspace planejado:

```bash
scripts/artemis-workspace.sh
scripts/artemis-workspace.sh --ticket TKT-020 --json
```

O Workspace Manager calcula branch, worktree, lock, artifact root e dono escritor sem criar worktree no modo padrao. Lock existente, worktree existente ou branch ocupada exigem Human Gate. O contrato detalhado vive em `docs/workspaces/artemis-workspace-manager.md`.

Para materializar explicitamente um workspace local:

```bash
scripts/artemis-workspace.sh --ticket TKT-021 --artifact-root artifacts/artemis-workspace-materialization/run-01 --materialize
```

Esse modo cria branch, worktree e lock locais, registra `materialization.json` e `MATERIALIZATION.md`, e nao inicia agentes automaticamente.

Para inventariar workspaces locais antes de qualquer decisao de limpeza:

```bash
scripts/artemis-workspace-lifecycle.sh
scripts/artemis-workspace-lifecycle.sh --artifact-root artifacts/artemis-workspace-lifecycle/run-01 --json
```

O inventario e read-only. Ele lista locks, worktrees, branches, artifact roots, limpeza pendente e criterio de revisao. `review_ready` nao autoriza limpeza automatica; significa apenas que o workspace pode ir para revisao humana antes de remover worktree ou lock.

Para preparar o pacote de decisao humana de cleanup:

```bash
scripts/artemis-workspace-cleanup-review.sh --artifact-root artifacts/artemis-workspace-cleanup-review/run-01 --json
```

Esse comando gera `cleanup-review.json`, `CLEANUP_REVIEW.md` e `DECISION_TEMPLATE.md`. Ele nunca executa `git worktree remove`, `rm` ou `git branch -d`; apenas lista comandos que podem ser aprovados explicitamente por humano.

Para validar o contrato da decisao humana:

```bash
scripts/artemis-human-cleanup-approval-contract.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-human-cleanup-approval-contract/run-01 --json
```

Decisoes validas sao `pending`, `approved`, `deferred` e `rejected`. `approved` exige `decided_by`, `decided_at` em ISO-8601, `reason` e todos os comandos exatamente iguais a `commands_after_approval`. Aprovacao parcial nao executa cleanup; registre como `deferred` com razao.

Para gerar fixtures sinteticas de decisao humana:

```bash
scripts/artemis-human-decision-fixtures.sh --artifact-root artifacts/artemis-human-decision-fixtures/run-01 --json
```

As fixtures cobrem aprovacao exata, deferimento, rejeicao, aprovacao parcial invalida e metadata ausente. Elas servem para validar contrato e dry-run; nao devem ser usadas com `--execute`.

Para preparar um pacote real preenchivel, mantendo todas as decisoes abertas:

```bash
scripts/artemis-real-cleanup-decision-package.sh --source artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-real-cleanup-decision-package/run-01 --json
```

Esse pacote grava `real-cleanup-decision.json`, instrucoes de preenchimento e comandos de validacao. Ele nao aprova cleanup e nao emite comando com `--execute`.

Para orientar o preenchimento humano:

```bash
artifacts/artemis-assisted-human-decision-runbook/run-01/RUNBOOK.md
```

O runbook explica quando usar `approved`, `deferred` e `rejected`, como preencher metadata humana e como copiar comandos exatos sem executar cleanup.

Para validar que o runbook nao divergiu do pacote real:

```bash
scripts/artemis-human-decision-runbook-consistency.sh --artifact-root artifacts/artemis-human-decision-runbook-consistency/run-01 --json
```

Para consolidar a camada de decisao humana como checkpoint local:

```bash
scripts/artemis-human-decision-release-checkpoint.sh --artifact-root artifacts/artemis-human-decision-release-checkpoint/run-01 --json
```

Esse checkpoint e read-only. Ele confirma evidencias, Human Gate, Control Plane e Validation Gate, mas nao preenche decisao humana e nao executa cleanup.

Para fazer o intake read-only de uma decisao humana preenchida:

```bash
scripts/artemis-human-decision-intake.sh --artifact-root artifacts/artemis-human-decision-intake/run-01 --json
```

O intake reaproveita o contrato humano e o dry-run de cleanup para classificar cada workspace como `approved_ready`, `deferred`, `rejected`, `pending` ou `invalid`. `approved_ready` ainda nao executa nada; apenas permite um corte futuro de executor supervisionado.

Para validar uma decisao humana ja preenchida sem executar cleanup:

```bash
scripts/artemis-approved-workspace-cleanup.sh --decision artifacts/artemis-workspace-cleanup-review/run-01/cleanup-review.json --artifact-root artifacts/artemis-approved-workspace-cleanup/run-01 --json
```

O modo padrao e dry-run. `pending`, `deferred`, comandos fora da allowlist ou lista de comandos diferente do pacote de revisao param em Human Gate. Execucao real exige `--execute` e continua restrita a comandos locais aprovados explicitamente.

Para registrar o estado final local dos workspaces:

```bash
scripts/artemis-workspace-runtime-handoff.sh --artifact-root artifacts/artemis-workspace-runtime-handoff/run-01 --json
```

Esse handoff e read-only e consolida `cleaned`, `kept`, `pending`, `approved_ready`, `deferred`, `rejected` ou `needs_decision` usando o inventario, o contrato de decisao e o resultado do executor aprovado. `approved_ready` nao significa limpo; significa que a decisao e valida, mas o executor ainda nao registrou execucao.

Para preparar uma execucao local supervisionada, use:

```bash
scripts/artemis-runner.sh --ticket TKT-000 --command "scripts/validate-artemis.sh"
scripts/artemis-runner.sh --ticket TKT-000 --command "scripts/validate-artemis.sh" --execute
scripts/artemis-runner.sh --ticket TKT-022 --command "pwd" --execute --use-workspace
scripts/artemis-runner.sh --ticket TKT-023 --command "pwd" --execute --use-workspace --attempt-purpose retry --retry-of <attempt-id>
```

Sem `--execute`, o runner apenas registra o plano. Com `--execute`, ele roda o comando depois de validar elegibilidade, readiness de workspace e bloquear comandos remotos, destrutivos ou de deploy. Com `--use-workspace`, ele exige worktree e lock materializados para o ticket e executa com `cwd` no worktree. `--attempt-purpose` e `--retry-of` registram o papel da tentativa dentro de um loop de validacao/fix. Cada tentativa registra `workspace.json`.

Cada tentativa tambem registra `events.json` com eventos canonicos:

- `runner.attempt_planned`;
- `runner.attempt_started`, quando `--execute` for usado;
- `runner.attempt_completed`.

Esses eventos sao observacionais e apontam para `dry-run.json`, `workspace.json`, comando, resultado, `execution_cwd`, `attempt_purpose` e `retry_of`.

Antes de mover uma tarefa para Handoff ou Done, execute o Validation Gate:

```bash
scripts/artemis-validation-gate.sh
scripts/artemis-validation-gate.sh --json
```

O gate retorna `passed`, `failed` ou `human_gate`. Resultado `failed` impede Done. Resultado `human_gate` exige decisao humana documentada.

GitHub Issues sao fonte complementar de intencao, nao substituem Exec Packs:

```bash
scripts/artemis-github-issues.sh
scripts/artemis-github-issues.sh --json
```

O adapter e read-only. Se `gh auth`, CODEOWNERS, labels ou rulesets estiverem pendentes, o resultado deve ser `human_gate`.

Codex app-server e fonte futura de eventos ricos, nao substitui controle terminal-first:

```bash
scripts/artemis-codex-app-server.sh
scripts/artemis-codex-app-server.sh --json
```

O adapter e read-only. Ele verifica disponibilidade local do protocolo, gera contrato ARTEMIS e mapeia `thread`, `turn`, `item`, approvals e notifications para tarefa, tentativa, evento, Human Gate e Control Plane. Nao inicia daemon, nao abre WebSocket e nao altera auth/config/plugins/arquivos remotos.

Claude Code e runner futuro de mesmo nivel, mas segue `AGENTS.md` como fonte canonica:

```bash
scripts/artemis-claude-code.sh
scripts/artemis-claude-code.sh --json
```

O adapter e read-only. Ele verifica disponibilidade local da CLI, auth, agents e flags relevantes, e mapeia headless runs, `json`/`stream-json`, hooks, subagents e tool events para tentativa, evento, Human Gate e evidencia ARTEMIS. Nao executa `claude -p`, nao habilita remote control, nao altera settings, agents, hooks, MCP, arquivos ou Git.

Eventos ARTEMIS usam envelope canonico versionado:

```bash
scripts/artemis-event-log.sh
scripts/artemis-event-log.sh --json
```

O schema vive em `docs/schemas/artemis-event.schema.json` e `docs/schemas/artemis-event-log.schema.json`. O envelope comum registra produtor, sujeito, runner, estado, gate, severidade, evidencia, links e payload. Campos especificos de GitHub, Codex app-server ou Claude Code ficam em `payload`, para que o Control Plane consuma eventos sem virar fonte canonica.

Adapters devem emitir eventos canonicos junto com seus JSONs especificos:

```text
artifacts/<adapter>/run-<nn>/events.json
```

`events.json` e um artifact de interoperabilidade. Ele nao substitui `STATUS.md`, `VALIDATION.md`, `HANDOFF.md`, o JSON especifico do adapter, Exec Packs ou Git.

## Completion checklist

Antes de mover uma tarefa para `Done`, confirme:

- Exec Pack existe e foi respeitado;
- diff esta dentro do escopo;
- validacao foi executada;
- falhas ou gaps foram registrados;
- artifacts existem;
- handoff registra riscos e proxima acao;
- commit foi criado quando houve mudanca versionavel;
- pendencias humanas foram separadas de pendencias tecnicas.
