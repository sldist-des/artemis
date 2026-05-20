# TKT-091 - ARTEMIS Control Plane Compact Operations View

## Objetivo

Reduzir a altura da visao simples do Control Plane sem remover o estado
operacional necessario para entender projeto local, registro externo e Runtime
Gateway.

## Nivel ARTEMIS da execucao

Nivel 2 - superficie visual de portal, leitura operacional e seguranca de
runtime.

## Agentes envolvidos

- Codex executor: simplificacao visual, atualizacao de seletores, artifacts e
  validacao.
- Humano owner: avaliacao visual do painel e aceite futuro de projetos,
  runtime, auth e custos.

## Resultado esperado

O Control Plane deixa de empilhar tres secoes grandes e passa a mostrar uma
faixa compacta de operacao, preservando leitura de projeto, providers,
candidatos, runtime, comandos, tokens e fontes de evidencia.

## Escopo

- Compactar os blocos de projeto local, registro externo e Runtime Gateway em
  uma unica secao "Operacao".
- Manter loaders, source URLs e renderizadores existentes.
- Trocar cards verbosos por chips curtos no modo simples.
- Atualizar scripts de validacao para os novos seletores compactos.
- Manter execucao real, auth, agentes, comandos, tokens e remoto bloqueados.

## Fora de escopo

- Aprovar projeto externo.
- Implementar troca real de projeto.
- Conectar auth de Codex, Claude Code ou Antigravity CLI.
- Iniciar app-server, SDK ou CLI.
- Enviar prompts para operadores.
- Executar comandos pelo painel.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `control-plane/index.html`
- `scripts/artemis-control-plane-local-project-connect-view.sh`
- `scripts/artemis-control-plane-external-project-registration-view.sh`
- `scripts/artemis-control-plane-runtime-gateway-view.sh`
- `artifacts/artemis-control-plane-compact-operations-view/run-01/STATUS.md`
- `artifacts/artemis-control-plane-compact-operations-view/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-compact-operations-view/run-01/HANDOFF.md`

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

- `artifacts/artemis-control-plane-compact-operations-view/run-01/STATUS.md`
- `artifacts/artemis-control-plane-compact-operations-view/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-compact-operations-view/run-01/HANDOFF.md`

## Handoff

Handoff aceito quando a visao simples couber como leitura operacional compacta,
sem perder os sinais de projeto, registro, runtime e bloqueios de seguranca.
