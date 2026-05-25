# TKT-122 - ARTEMIS Operator Reference Intake

## Objetivo

Registrar ECC e gstack como referencias externas para a futura camada de
operadores ARTEMIS, preservando autoria, licenca, limites de seguranca e a
autoridade canonica do metodo.

## Nivel ARTEMIS da execucao

Nivel 1 - intake documental e artifact local, sem instalacao externa, sem
runtime, sem hooks, sem providers, sem secrets, sem tokens e sem escrita remota.

## Agentes envolvidos

- Codex executor: intake, docs, script, artifacts, grafo, validacao e commit.

## Resultado esperado

O ARTEMIS deve saber o que aprender de ECC e gstack, o que rejeitar, o que
recriar como contrato proprio e quais gates futuros precisam existir antes de
qualquer uso real.

## Escopo

- Criar `docs/references/ARTEMIS_OPERATOR_REFERENCE_INTAKE.md`.
- Criar `scripts/artemis-operator-reference-intake.sh`.
- Registrar fontes, licencas, capacidades, decisoes de adocao e caminhos
  rejeitados.
- Integrar o intake ao Event Log, Project Graph, README, AGENTS e validacao.

## Fora de escopo

- Vendorizar ECC ou gstack.
- Rodar instaladores externos.
- Copiar codigo, prompts, assets, marcas ou textos proprietarios.
- Ativar hooks, browser automation, CDP, MCP, shell amplo ou provider runtime.
- Criar configs reais de Claude Code, Codex, Antigravity CLI ou outros
  harnesses.
- Gastar tokens, autenticar providers ou escrever em estado remoto.

## Invariantes

- Referencia externa nao substitui autoridade ARTEMIS.
- Licenca permissiva nao elimina rastreabilidade, atribuicao e decisao de
  projeto.
- Toda capacidade futura precisa de preview, risco, validacao, rollback e Human
  Gate quando tocar runtime, auth, secrets, custo, browser, hooks ou remoto.
- Aprendizado de memoria deve nascer como candidato governado, nao como regra
  ativa automatica.

## Evidencias obrigatorias

- `scripts/artemis-operator-reference-intake.sh`
- `artifacts/artemis-operator-reference-intake/run-01/operator-reference-intake.json`
- `artifacts/artemis-operator-reference-intake/run-01/OPERATOR_REFERENCE_INTAKE.md`
- `artifacts/artemis-operator-reference-intake/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-operator-reference-intake.sh
scripts/artemis-operator-reference-intake.sh --artifact-root artifacts/artemis-operator-reference-intake/run-01 --json
python3 -m json.tool artifacts/artemis-operator-reference-intake/run-01/operator-reference-intake.json
python3 -m json.tool artifacts/artemis-operator-reference-intake/run-01/events.json
scripts/validate-artemis.sh
```

## Handoff

Handoff aceito quando `operator_reference_intake_ready` estiver registrado, com
ECC e gstack mapeados como referencias, licencas registradas, capacidades
futuras declaradas e instalacao externa bloqueada.
