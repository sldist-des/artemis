# VALIDATION - ARTEMIS Control Plane Run 01

## Comandos planejados

```bash
scripts/validate-artemis.sh
git diff --check
google-chrome --headless --disable-gpu --screenshot=/tmp/artemis-control-plane.png file:///srv/veri/control-plane/index.html
```

## Resultado

Passou.

## Evidencia

- `scripts/validate-artemis.sh` retornou `ARTEMIS validation passed`.
- `git diff --check` executou sem erros.
- Chrome headless renderizou `control-plane/index.html` em desktop largo:
  - `/tmp/artemis-control-plane-wide.png`
- Chrome headless renderizou `control-plane/index.html` em viewport mobile:
  - `/tmp/artemis-control-plane-mobile.png`

## Observacoes

O Control Plane funciona abrindo diretamente o arquivo HTML. O estado dos cards e salvo no navegador com `localStorage`.
