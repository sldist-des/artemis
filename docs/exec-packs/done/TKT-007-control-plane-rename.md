# TKT-007 - Renomear superficie visual para ARTEMIS Control Plane

## Objetivo

Alinhar a nomenclatura do metodo: a superficie visual deve ser tratada como ARTEMIS Control Plane.

## Resultado esperado

Arquivos e documentacao corrente devem usar `control-plane/` e ARTEMIS Control Plane. Referencias antigas podem permanecer apenas em artifacts historicos.

## Nivel ARTEMIS da execucao

Nivel 0 - ajuste de nomenclatura e estrutura.

## Agentes envolvidos

- Implementer: renomeia caminhos e textos.
- Reviewer: valida referencias ativas.
- Memory Keeper: registra evidencias.

## Contexto minimo

- `docs/orchestration/ARTEMIS_ORCHESTRATION_PLAN.md`
- `control-plane/index.html`
- `docs/control-plane/artemis-control-plane.md`
- `scripts/validate-artemis.sh`

## Escopo

- Mover a superficie visual para `control-plane/index.html`.
- Mover a especificacao para `docs/control-plane/artemis-control-plane.md`.
- Atualizar README, principios, validador e textos correntes.
- Atualizar o Exec Pack TKT-005 para a nomenclatura nova.
- Registrar artifacts.

## Fora de escopo

- Implementar daemon.
- Criar GitHub Pages.
- Integrar issues ou runners.
- Reescrever artifacts historicos.

## Invariantes

- Control Plane e superficie visual, nao fonte canonica.
- Exec Packs e artifacts continuam fonte documental.
- Nao quebrar validacao local.
- Nao introduzir dependencia.

## Ferramentas autorizadas

- Edicao local.
- `mv` local.
- Chrome headless.
- `scripts/validate-artemis.sh`.
- Git local.

## Ferramentas proibidas

- Deploy.
- Escrita remota.
- Dependencias npm.

## Comandos de validacao

```bash
scripts/validate-artemis.sh
git diff --check
google-chrome --headless --disable-gpu --no-sandbox --window-size=1600,1000 --screenshot=/tmp/artemis-control-plane.png file:///srv/veri/control-plane/index.html
rg -n "Kanban|kanban" README.md docs/control-plane docs/principles scripts docs/orchestration
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-rename/run-01/STATUS.md`
- `artifacts/artemis-control-plane-rename/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-rename/run-01/HANDOFF.md`

## Escalonar para humano se

- For necessario preservar URL publica antiga.
- For desejado manter um alias publico para o caminho antigo.

## Entregaveis

- Caminhos renomeados.
- Docs ajustadas.
- Validador ajustado.
- Commit local.
