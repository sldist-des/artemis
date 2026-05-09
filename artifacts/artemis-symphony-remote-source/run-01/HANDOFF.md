# HANDOFF

## Estado

Fonte remota supervisionada esta `human_gate`. Ela gera intake e evidencia local, nao autoridade de execucao.

## Proximo corte

- Implementar `TKT-061 - Agent Runtime Decision Intake do ARTEMIS Symphony`.
- Revisar itens remotos antes de promover para fila/service.
- Exigir Exec Pack local e decisao humana quando houver escrita remota, PR, merge ou deploy.

## Nao fazer

- Nao executar runner automaticamente a partir de issue.
- Nao escrever labels, comentarios, PRs ou branches remotos.
- Nao substituir Exec Pack por metadados remotos.
