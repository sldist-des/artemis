# VALIDATION - Agent Guide Canon Run 01

## Comandos planejados

```bash
rg -n "AGENTS.md|CLAUDE.md" README.md ARTEMIS_QUICKSTART.md templates/CLAUDE.md AGENTS.md CLAUDE.md
git diff --check
```

## Resultado

Passou.

## Evidencia

- `rg -n "AGENTS.md|CLAUDE.md" README.md ARTEMIS_QUICKSTART.md templates/CLAUDE.md AGENTS.md CLAUDE.md` confirmou referencias coerentes.
- `git diff --check` executou sem erros.
- `git status --short` confirmou apenas arquivos desta rodada como alterados.
