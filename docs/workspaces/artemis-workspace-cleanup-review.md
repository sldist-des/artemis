# ARTEMIS Workspace Cleanup Review

Cleanup de workspace e uma decisao humana, nao uma rotina automatica.

O inventario de lifecycle pode indicar `review_ready`, mas esse estado significa apenas que ha evidencia suficiente para revisao. Ele nao autoriza remover worktree, branch ou lock.

## Protocolo

1. Gere inventario atualizado:

```bash
scripts/artemis-workspace-lifecycle.sh --artifact-root artifacts/artemis-workspace-lifecycle/run-01 --json
```

2. Gere o pacote de revisao:

```bash
scripts/artemis-workspace-cleanup-review.sh --artifact-root artifacts/artemis-workspace-cleanup-review/run-01 --json
```

3. Revise para cada ticket:

- `STATUS.md`, `VALIDATION.md` e `HANDOFF.md` do artifact root;
- lock local em `.artemis/locks/`;
- worktree registrado em `git worktree list --porcelain`;
- branch local integrada ao `HEAD` atual;
- worktree limpo.

4. Registre a decisao humana em `DECISION_TEMPLATE.md` antes de qualquer comando de cleanup.

## Estados

- `eligible_for_human_cleanup_approval`: o workspace esta apto a revisao humana para cleanup local.
- `defer_cleanup`: falta evidencia, ha branch nao integrada, worktree sujo ou divergencia local.

## Invariantes

- O script de revisao nunca remove worktree, lock ou branch.
- `pending` nao e aprovacao.
- Comandos de cleanup precisam aparecer explicitamente na decisao humana.
- Workspace sujo, branch nao integrada ou evidencia ausente interrompem o cleanup.
- Push, merge remoto e PR continuam fora deste protocolo.
