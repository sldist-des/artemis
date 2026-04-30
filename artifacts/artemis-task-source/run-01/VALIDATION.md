# VALIDATION - ARTEMIS Task Source Run 01

## Comandos planejados

```bash
scripts/validate-artemis.sh
sh -n scripts/artemis-tasks.sh
scripts/artemis-tasks.sh
scripts/artemis-tasks.sh --output control-plane/tasks.json
jq '.tasks | length' control-plane/tasks.json
google-chrome --headless --disable-gpu --no-sandbox --window-size=1600,1000 --screenshot=/tmp/artemis-task-source-control-plane.png http://127.0.0.1:8123/control-plane/index.html
git diff --check
```

## Resultado

Passou.

## Evidencia

- `sh -n scripts/artemis-tasks.sh` passou.
- `scripts/artemis-tasks.sh` emitiu JSON valido.
- `scripts/artemis-tasks.sh --output control-plane/tasks.json` gerou o arquivo consumido pelo Control Plane.
- `jq '.tasks | length' control-plane/tasks.json` retornou `11`.
- Chrome headless renderizou `http://127.0.0.1:8123/control-plane/index.html` em `/tmp/artemis-task-source-control-plane.png`.
- O servidor HTTP local registrou `GET /control-plane/tasks.json`, confirmando o consumo do JSON.
- `scripts/validate-artemis.sh` passou.
- `git diff --check` passou.

## Observacoes

- Abrir o HTML diretamente por `file://` pode acionar fallback local por restricoes de `fetch` do navegador.
- O script nao escreve nos Exec Packs; ele apenas le `active/` e `done/` e escreve stdout ou o arquivo explicitamente passado por `--output`.
