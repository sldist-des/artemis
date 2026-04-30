# VALIDATION - ARTEMIS Control Plane Rename Run 01

## Comandos planejados

```bash
scripts/validate-artemis.sh
git diff --check
google-chrome --headless --disable-gpu --no-sandbox --window-size=1600,1000 --screenshot=/tmp/artemis-control-plane.png file:///srv/veri/control-plane/index.html
rg -n "Kanban|kanban" README.md docs/control-plane docs/principles scripts docs/orchestration
```

## Resultado

Passou.

## Evidencia

- `scripts/validate-artemis.sh` retornou `ARTEMIS validation passed`.
- `git diff --check` executou sem erros.
- `rg -n "Kanban|kanban" README.md docs/control-plane docs/principles scripts docs/orchestration` nao retornou ocorrencias.
- Chrome headless gerou `/tmp/artemis-control-plane.png` para `file:///srv/veri/control-plane/index.html`.

## Observacoes

- `control-plane/index.html` mantem uma chave legada de `localStorage` para migrar estados salvos por navegadores que usaram a versao anterior.
