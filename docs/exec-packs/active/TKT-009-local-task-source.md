# TKT-009 - Criar task source local para Exec Packs

## Objetivo

Criar uma fonte local de tarefas que leia Exec Packs e artifacts para alimentar o ARTEMIS Control Plane sem daemon.

## Resultado esperado

Um comando local gera JSON com tarefas, estados, owners, riscos, evidencias e caminhos dos Exec Packs.

## Nivel ARTEMIS da execucao

Nivel 1 - automacao local sem dispatch de runners.

## Agentes envolvidos

- Architect: define contrato JSON minimo.
- Implementer: cria script local.
- Reviewer: valida que o script nao escreve em tarefas.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `control-plane/index.html`
- `docs/exec-packs/active/`
- `docs/exec-packs/done/`
- `artifacts/`

## Escopo

- Criar `scripts/artemis-tasks.sh` ou equivalente.
- Gerar JSON estatico a partir de Exec Packs locais.
- Detectar artifacts existentes.
- Preparar o Control Plane para consumir esse JSON.

## Fora de escopo

- Daemon.
- Dispatch de agentes.
- GitHub Issues.
- Escrita automatica em Exec Packs.
- Mudanca remota.

## Invariantes

- O script deve ser read-only sobre Exec Packs.
- O Control Plane continua sendo visualizacao.
- Exec Packs e artifacts continuam fonte documental.
- Sem novas dependencias.

## Validacao prevista

```bash
scripts/validate-artemis.sh
sh -n scripts/artemis-tasks.sh
scripts/artemis-tasks.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-task-source/run-01/STATUS.md`
- `artifacts/artemis-task-source/run-01/VALIDATION.md`
- `artifacts/artemis-task-source/run-01/HANDOFF.md`
