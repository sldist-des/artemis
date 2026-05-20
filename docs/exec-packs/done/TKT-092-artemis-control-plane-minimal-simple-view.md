# TKT-092 - ARTEMIS Control Plane Minimal Simple View

## Objetivo

Reduzir a quantidade de informacao visivel no modo simples do Control Plane,
removendo altura visual excessiva, linhas grandes e detalhe de auditoria da
primeira leitura.

## Nivel ARTEMIS da execucao

Nivel 2 - superficie visual de portal e leitura operacional.

## Agentes envolvidos

- Codex executor: corte visual, validacao e handoff.
- Humano owner: avaliacao de clareza do painel.

## Resultado esperado

O modo simples mostra apenas resumo, operacao e acesso a visao tecnica completa.
Explicacoes, fontes, listas auxiliares e chips de providers saem da primeira
leitura.

## Escopo

- Compactar o cabecalho.
- Ocultar principios, subtitulo longo, paineis auxiliares, fontes e chips no
  modo simples.
- Transformar status e operacao em linhas baixas.
- Preservar seletores, loaders e contratos usados pelos scripts.
- Validar desktop e mobile por screenshot.

## Fora de escopo

- Redesenhar a visao tecnica completa.
- Alterar contratos de runtime.
- Conectar auth.
- Iniciar agentes.
- Executar comandos pelo painel.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `control-plane/index.html`
- `scripts/artemis-control-plane-external-project-registration-view.sh`
- `control-plane/tasks.json`
- `artifacts/artemis-control-plane-minimal-simple-view/run-01/STATUS.md`
- `artifacts/artemis-control-plane-minimal-simple-view/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-minimal-simple-view/run-01/HANDOFF.md`

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

- `artifacts/artemis-control-plane-minimal-simple-view/run-01/STATUS.md`
- `artifacts/artemis-control-plane-minimal-simple-view/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-minimal-simple-view/run-01/HANDOFF.md`

## Handoff

Handoff aceito quando a primeira tela nao parecer uma auditoria tecnica e a
visao completa continuar disponivel sob demanda.
