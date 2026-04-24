# AI_PROCESS.md

Este projeto segue ARTEMIS.

## Cadeia operacional

```text
Issue ou Exec Pack
  -> Branch
  -> Worktree
  -> Implementacao
  -> Evidencias
  -> Revisao por IA
  -> Revisao humana
  -> PR/Merge
  -> Handoff
```

## Exec Packs

Local:

```text
docs/exec-packs/
  backlog/
  active/
  done/
```

Todo Exec Pack deve declarar:

- objetivo;
- resultado esperado;
- contexto minimo;
- escopo;
- fora de escopo;
- invariantes;
- comandos de validacao;
- evidencias obrigatorias;
- criterios de escalonamento.

## Artifacts

Use:

```text
artifacts/<ticket>/run-XX/
  STATUS.md
  FILES_CHANGED.md
  VALIDATION.md
  RISKS.md
  HANDOFF.md
```

## Niveis ARTEMIS

- Nivel 0: execucao simples.
- Nivel 1: Context Curator, Implementer, Reviewer.
- Nivel 2: subagentes especializados.
- Nivel 3: multi-worktree coordenado.
- Nivel 4: harness programavel.

