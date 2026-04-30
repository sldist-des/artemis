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

O dry-run nunca inicia agentes, nao cria worktrees e nao altera Exec Packs. Ele apenas classifica tarefas como `eligible`, `blocked`, `human_gate` ou `done`.

Para preparar uma execucao local supervisionada, use:

```bash
scripts/artemis-runner.sh --ticket TKT-000 --command "scripts/validate-artemis.sh"
scripts/artemis-runner.sh --ticket TKT-000 --command "scripts/validate-artemis.sh" --execute
```

Sem `--execute`, o runner apenas registra o plano. Com `--execute`, ele roda o comando depois de validar elegibilidade e bloquear comandos remotos, destrutivos ou de deploy.

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
