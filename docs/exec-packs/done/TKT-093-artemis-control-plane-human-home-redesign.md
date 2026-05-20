# TKT-093 - ARTEMIS Control Plane Human Home Redesign

## Objetivo

Refazer a superficie visual do Control Plane para uma home operacional simples,
sem aba tecnica gigante, excesso de linhas ou leitura longa para o humano.

## Nivel ARTEMIS da execucao

Nivel 2 - experiencia visual principal do portal.

## Agentes envolvidos

- Codex executor: redesign visual, validacao e handoff.
- Humano owner: avaliacao de clareza e decisao futura de runtime/auth.

## Resultado esperado

A primeira tela mostra apenas estado atual, operacao e tres links de evidencia.
A auditoria tecnica continua disponivel nos artefatos e no DOM para validacao,
mas nao aparece como superficie normal do site.

## Escopo

- Reposicionar o Control Plane como home humana.
- Ocultar a aba tecnica completa da experiencia visual principal.
- Reduzir textos longos, chips, fontes e linhas tecnicas.
- Manter seletores e scripts existentes para validacao.
- Validar desktop e mobile com screenshots.

## Fora de escopo

- Remover artefatos tecnicos do repositorio.
- Alterar contratos de runtime.
- Conectar providers.
- Iniciar agentes.
- Executar comandos pelo painel.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `control-plane/index.html`
- `scripts/artemis-control-plane-external-project-registration-view.sh`
- `control-plane/tasks.json`
- `artifacts/artemis-control-plane-human-home-redesign/run-01/STATUS.md`
- `artifacts/artemis-control-plane-human-home-redesign/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-human-home-redesign/run-01/HANDOFF.md`

## Validacao

```bash
node -e "const fs=require('fs'); const html=fs.readFileSync('control-plane/index.html','utf8'); const match=html.match(/<script>([\s\S]*)<\/script>/); if(!match) throw new Error('script not found'); new Function(match[1]); console.log('inline script syntax ok');"
scripts/artemis-control-plane-runtime-gateway-view.sh --artifact-root artifacts/artemis-control-plane-runtime-gateway-view/run-01 --json
scripts/artemis-control-plane-local-project-connect-view.sh --artifact-root artifacts/artemis-control-plane-local-project-connect-view/run-01 --json
scripts/artemis-control-plane-external-project-registration-view.sh --artifact-root artifacts/artemis-control-plane-external-project-registration-view/run-01 --json
scripts/artemis-tasks.sh --output control-plane/tasks.json
scripts/artemis-event-log.sh --artifact-root artifacts/artemis-event-log-schema/run-01 --json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-human-home-redesign/run-01/STATUS.md`
- `artifacts/artemis-control-plane-human-home-redesign/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-human-home-redesign/run-01/HANDOFF.md`

## Handoff

Handoff aceito quando a tela inicial puder ser entendida em poucos segundos e a
auditoria tecnica nao competir com a operacao principal.
