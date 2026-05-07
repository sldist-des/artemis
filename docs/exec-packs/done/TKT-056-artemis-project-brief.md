# TKT-056 - Human-readable Project Brief do ARTEMIS Symphony

## Objetivo

Transformar o Project Operations Graph em um briefing humano, simples e
acionavel, sem criar nova fonte de verdade.

## Escopo

- Criar `scripts/artemis-project-brief.sh`.
- Gerar artifact `artifacts/artemis-project-brief/run-01/`.
- Documentar o contrato em
  `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_BRIEF.md`.
- Renderizar o briefing no Control Plane.
- Integrar o briefing ao Event Log, Validation Gate e validação canonica.

## Fora de escopo

- iniciar runtime, servidor persistente, banco de grafo, indexador ou agente;
- instalar dependencia;
- fazer escrita remota;
- transformar Control Plane ou Project Brief em fonte canonica;
- aprovar Human Gates automaticamente.

## Entrega

- `scripts/artemis-project-brief.sh`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_BRIEF.md`
- `artifacts/artemis-project-brief/run-01/project-brief.json`
- `artifacts/artemis-project-brief/run-01/PROJECT_BRIEF.md`
- Control Plane com `project-brief-section`

## Validacao esperada

```bash
scripts/artemis-project-brief.sh --artifact-root artifacts/artemis-project-brief/run-01 --json
scripts/artemis-validation-gate.sh --artifact-root artifacts/artemis-validation-gate/run-01 --json
scripts/validate-artemis.sh
git diff --check
```

## Handoff

O proximo corte e `TKT-058 - Supervised Agent Launch Contract do ARTEMIS
Symphony`, usando o modo guiado como entrada para lancamentos supervisionados.
