# TKT-005 - Implementar ARTEMIS Control Plane

## Objetivo

Criar a primeira superficie visual do metodo ARTEMIS: um Control Plane local, simples, state-of-the-art e completo o suficiente para orientar humano e agentes.

## Resultado esperado

Um arquivo `control-plane/index.html` deve abrir diretamente no navegador, mostrar os estados ARTEMIS, permitir mover cards e preservar o estado localmente.

## Nivel ARTEMIS da execucao

Nivel 1 - preparar, executar e revisar com evidencia.

## Agentes envolvidos

- Context Curator: corta o escopo a partir das referencias OpenAI.
- Implementer: cria Control Plane, docs e principios.
- Reviewer: valida estrutura, HTML e scripts.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `AGENTS.md`
- `AI_PROCESS.md`
- `docs/principles/artemis-principles.md`
- `docs/control-plane/artemis-control-plane.md`
- Referencias oficiais:
  - https://developers.openai.com/codex/app-server
  - https://openai.com/index/open-source-codex-orchestration-symphony/

## Escopo

- Criar Control Plane visual estatico.
- Criar principios ARTEMIS.
- Documentar o corte arquitetural do Control Plane.
- Atualizar README e validacao.
- Registrar artifacts.

## Fora de escopo

- Criar daemon Symphony.
- Integrar GitHub Issues automaticamente.
- Integrar Codex app-server em tempo real.
- Criar backend, banco ou dependencia frontend.
- Publicar GitHub Pages nesta rodada.

## Invariantes

- Sem novas dependencias.
- Abrir via arquivo local deve funcionar.
- O Control Plane e superficie visual, nao fonte canonica de execucao.
- Exec Packs e artifacts continuam sendo fonte documental.

## Ferramentas autorizadas

- Edicao local.
- Browser headless para screenshot, se disponivel.
- `scripts/validate-artemis.sh`.
- Git local.

## Ferramentas proibidas

- Deploy.
- Backend persistente.
- Dependencias npm.
- Escrita remota GitHub.

## Comandos de validacao

```bash
scripts/validate-artemis.sh
git diff --check
google-chrome --headless --disable-gpu --screenshot=/tmp/artemis-control-plane.png file:///srv/veri/control-plane/index.html
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane/run-01/STATUS.md`
- `artifacts/artemis-control-plane/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane/run-01/HANDOFF.md`

## Escalonar para humano se

- For desejado transformar o Control Plane em app com backend.
- For necessario escolher uma identidade visual diferente.
- For desejado publicar publicamente.

## Entregaveis

- `control-plane/index.html`
- docs de principios e Control Plane
- validacao atualizada
- artifacts e commit local
