# TKT-044 - Control Plane do ARTEMIS Symphony Bridge

## Objetivo

Expor no Control Plane as evidencias do ARTEMIS Symphony Kernel, Bridge e runner supervisionado.

## Resultado esperado

O Control Plane deve mostrar uma faixa observacional com status, fatos e links para artifacts reais do kernel, bridge, tentativa do runner e Validation Gate, sem virar fonte canonica.

## Nivel ARTEMIS da execucao

Nivel 1 - visualizacao local read-only.

## Agentes envolvidos

- Designer: define composicao compacta para evidencias Symphony.
- Implementer: atualiza `control-plane/index.html`.
- Reviewer: valida que a UI apenas aponta para artifacts.
- Memory Keeper: registra evidencia e handoff.

## Contexto minimo

- `control-plane/index.html`
- `artifacts/artemis-symphony-kernel/run-01/`
- `artifacts/artemis-symphony-bridge/run-01/`
- `artifacts/artemis-validation-gate/run-01/`

## Escopo

- Adicionar secao visual `ARTEMIS Symphony`.
- Mostrar Kernel, Bridge, Runner e Validation.
- Linkar artifacts reais.
- Preservar Control Plane como superficie observacional.
- Atualizar validacoes locais.

## Fora de escopo

- Daemon.
- Execucao de runner.
- Alterar fonte canonica de tarefas.
- Criar backend para o Control Plane.
- Push, PR, merge ou cleanup.

## Invariantes

- Exec Packs e artifacts continuam canonicos.
- Control Plane nao escreve estado canonico.
- A secao Symphony deve indicar `commands=0` para o runner plan-only.
- Human Gates continuam visiveis como estado, nao resolvidos pela UI.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
google-chrome --headless --disable-gpu --no-sandbox --window-size=1600,1000 --screenshot=/tmp/artemis-tkt044-control-plane.png http://127.0.0.1:8145/control-plane/
```

## Evidencias obrigatorias

- `artifacts/artemis-symphony-control-plane/run-01/STATUS.md`
- `artifacts/artemis-symphony-control-plane/run-01/VALIDATION.md`
- `artifacts/artemis-symphony-control-plane/run-01/HANDOFF.md`
