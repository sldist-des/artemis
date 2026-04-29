# VALIDATION - ARTEMIS Kanban Run 01

## Comandos planejados

```bash
scripts/validate-artemis.sh
git diff --check
google-chrome --headless --disable-gpu --screenshot=/tmp/artemis-kanban.png file:///srv/veri/kanban/index.html
```

## Resultado

Passou.

## Evidencia

- `scripts/validate-artemis.sh` retornou `ARTEMIS validation passed`.
- `git diff --check` executou sem erros.
- Chrome headless renderizou `kanban/index.html` em desktop largo:
  - `/tmp/artemis-kanban-wide.png`
- Chrome headless renderizou `kanban/index.html` em viewport mobile:
  - `/tmp/artemis-kanban-mobile.png`

## Observacoes

O Kanban funciona abrindo diretamente o arquivo HTML. O estado dos cards e salvo no navegador com `localStorage`.
