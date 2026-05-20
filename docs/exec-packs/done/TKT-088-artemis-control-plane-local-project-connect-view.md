# TKT-088 - ARTEMIS Control Plane Local Project Connect View

## Objetivo

Renderizar no Control Plane o projeto conectado pelo terminal e os fornecedores
locais detectados antes de qualquer rota de operador ou runtime.

## Nivel ARTEMIS da execucao

Nivel 2 - superficie visual de portal, estado read-only e seguranca de runtime.

## Agentes envolvidos

- Codex executor: implementacao visual, script de validacao, artifacts e
  validacao.
- Humano owner: autoridade futura para registrar projetos externos, conectar
  providers e liberar runtime real.

## Resultado esperado

O Control Plane mostra que `/srv/veri` foi conectado pelo terminal, que o
navegador nao tem acesso de filesystem, e que Codex, Claude Code e Antigravity
CLI podem ser detectados localmente sem significar auth ou permissao de runtime.

## Escopo

- Renderizar bloco "Projeto local" no modo simples.
- Consumir artifact `local-project-connect.json`.
- Mostrar caminho do projeto, fonte, acesso browser e runtime.
- Mostrar fornecedores detectados: Codex, Claude Code e Antigravity CLI.
- Manter auth, runtime, comandos, tokens e remoto bloqueados.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Criar seletor real de projetos externos.
- Publicar pacote npm.
- Autenticar providers.
- Iniciar app-server, SDK ou CLI.
- Enviar prompt para provider.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `control-plane/index.html`
- `scripts/artemis-control-plane-local-project-connect-view.sh`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/control-plane-local-project-connect-view.json`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/CONTROL_PLANE_LOCAL_PROJECT_CONNECT_VIEW.md`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/STATUS.md`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/HANDOFF.md`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-control-plane-local-project-connect-view.sh
scripts/artemis-control-plane-local-project-connect-view.sh --artifact-root artifacts/artemis-control-plane-local-project-connect-view/run-01 --json
python3 -m json.tool artifacts/artemis-control-plane-local-project-connect-view/run-01/control-plane-local-project-connect-view.json
python3 -m json.tool artifacts/artemis-control-plane-local-project-connect-view/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-local-project-connect-view/run-01/control-plane-local-project-connect-view.json`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/CONTROL_PLANE_LOCAL_PROJECT_CONNECT_VIEW.md`
- `artifacts/artemis-control-plane-local-project-connect-view/run-01/events.json`

## Handoff

Handoff aceito quando o Control Plane mostrar projeto conectado e fornecedores
detectados sem sugerir runtime liberado, preservando auth, agentes, comandos,
tokens e remoto bloqueados.
