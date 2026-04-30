# TKT-012 - Criar Validation Gate forte

## Objetivo

Criar um gate local que consolide validacoes obrigatorias antes de qualquer tarefa seguir para Handoff ou Done.

## Resultado esperado

Um comando local executa os checks canonicos do ARTEMIS, registra resultado estruturado e diferencia falha tecnica de Human Gate.

## Nivel ARTEMIS da execucao

Nivel 2 - qualidade automatizada com evidencia.

## Agentes envolvidos

- Architect: define contrato do gate.
- Implementer: cria comando de validacao consolidada.
- Reviewer: valida cobertura e falhas.
- Memory Keeper: registra artifacts.

## Contexto minimo

- `ARTEMIS_WORKFLOW.md`
- `scripts/validate-artemis.sh`
- `scripts/artemis-dry-run.sh`
- `scripts/artemis-runner.sh`
- `artifacts/`

## Escopo

- Criar comando de Validation Gate.
- Executar checks canonicos do repositorio.
- Registrar resultado em artifact.
- Separar erro tecnico de Human Gate.
- Integrar com runner local supervisionado.

## Fora de escopo

- CI remoto.
- GitHub branch protection.
- Testes de projetos externos.
- Merge ou push automatico.

## Invariantes

- Falha de validacao impede Done.
- Human Gate nao pode ser ignorado.
- Gate deve produzir evidencia.
- Sem novas dependencias.

## Validacao prevista

```bash
scripts/validate-artemis.sh
scripts/artemis-dry-run.sh
scripts/artemis-runner.sh --ticket TKT-012 --command "scripts/validate-artemis.sh"
```

## Evidencias obrigatorias

- `artifacts/artemis-validation-gate/run-01/STATUS.md`
- `artifacts/artemis-validation-gate/run-01/VALIDATION.md`
- `artifacts/artemis-validation-gate/run-01/HANDOFF.md`
