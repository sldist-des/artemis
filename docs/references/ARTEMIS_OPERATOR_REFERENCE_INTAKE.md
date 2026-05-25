# ARTEMIS Operator Reference Intake

Este documento registra como ARTEMIS usa ECC e gstack como referencias externas
para elevar o metodo, sem copiar implementacao, instalar ferramentas, ativar
hooks ou mudar a autoridade do repositorio.

## Referencias

- ECC: https://github.com/affaan-m/ECC
- gstack: https://github.com/garrytan/gstack

Ambos foram verificados como repositorios publicos com licenca MIT em
2026-05-25. A licenca permite uso amplo, mas este corte ainda e apenas intake:
nenhum codigo, asset, prompt, marca, instalador, hook ou configuracao externa e
copiado para ARTEMIS.

## Como aplicar no ARTEMIS

ECC inspira a camada de harness: capacidades, skills, memoria, aprendizado,
seguranca, hooks, pesquisa, status e instalacao seletiva.

gstack inspira a camada de operadores: revisao de produto, engenharia, design,
QA, release, documentacao, seguranca, memoria de dominio e comandos
deny-default.

ARTEMIS combina os dois como `Operator Layer`:

- `Operator Capability Registry`: lista capacidades, providers, riscos,
  validacoes e Human Gates.
- `Operator Routing Gate`: escolhe qual operador deve agir antes de abrir lane
  real.
- `Operator Memory Learning Gate`: promove aprendizados apenas depois de
  evidencia repetida.
- `Operator Tool Security Gate`: bloqueia hooks, browser, CDP, MCP e shell
  amplo ate existir preview, allowlist, rollback e aprovacao.
- `Operator Status Snapshot`: cria handoff portavel a partir de Exec Packs,
  Event Log, Project Graph e Validation Gate.

## Limites

- ECC e gstack sao referencias, nao autoridade.
- `AGENTS.md`, Git, Exec Packs, Event Log, Validation Gate e Human Gates
  continuam canonicos.
- Instaladores externos, hooks, browser automation, auth, secrets, runtime,
  token spend e escrita remota continuam bloqueados sem Human Gate.
- Se no futuro qualquer componente externo for usado, ele precisa de preview de
  arquivos, escopo, licenca, rollback e validacao antes da instalacao.

## Comando canonico

```bash
scripts/artemis-operator-reference-intake.sh --json
```

Artefatos esperados:

- `artifacts/artemis-operator-reference-intake/run-01/operator-reference-intake.json`
- `artifacts/artemis-operator-reference-intake/run-01/OPERATOR_REFERENCE_INTAKE.md`
- `artifacts/artemis-operator-reference-intake/run-01/STATUS.md`
- `artifacts/artemis-operator-reference-intake/run-01/VALIDATION.md`
- `artifacts/artemis-operator-reference-intake/run-01/HANDOFF.md`
- `artifacts/artemis-operator-reference-intake/run-01/events.json`
