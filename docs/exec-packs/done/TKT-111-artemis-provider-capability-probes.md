# TKT-111 - ARTEMIS Provider Capability Probes

## Objetivo

Criar probes locais e seguros para identificar disponibilidade de CLIs de
provider e capacidades declaradas.

## Nivel ARTEMIS da execucao

Nivel 2 - governanca de runtime e provider readiness.

## Agentes envolvidos

- Codex executor: probes locais, artifacts, evento, grafo e validacao.
- Humano owner: autoridade futura para conectar auth real.

## Resultado esperado

O metodo consegue distinguir provider instalado, provider ausente e provider
experimental sem autenticar contas nem chamar APIs.

## Escopo

- Consumir `config/artemis-model-registry.json`.
- Detectar comandos locais declarados para Codex, Claude Code e Antigravity.
- Registrar versao local quando o CLI responder a `--version`.
- Emitir artifacts e evento canonico.
- Manter chamadas de API, auth, agentes, tokens e remoto bloqueados.

## Fora de escopo

- Login em providers.
- Teste de modelos reais.
- Leitura de billing.
- Inicio de agentes.
- Escrita de configuracao runtime.

## Arquivos

- `scripts/artemis-provider-capability-probes.sh`
- `artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json`
- `artifacts/artemis-provider-capability-probes/run-01/PROVIDER_CAPABILITY_PROBES.md`
- `artifacts/artemis-provider-capability-probes/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-provider-capability-probes.sh
scripts/artemis-provider-capability-probes.sh --artifact-root artifacts/artemis-provider-capability-probes/run-01 --json
python3 -m json.tool artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-provider-capability-probes/run-01/provider-capability-probes.json`
- `artifacts/artemis-provider-capability-probes/run-01/PROVIDER_CAPABILITY_PROBES.md`
- `artifacts/artemis-provider-capability-probes/run-01/events.json`

## Handoff

Handoff aceito quando os probes reportarem
`provider_capability_probes_ready`, com auth/API/tokens/remoto bloqueados e
estado local de cada provider registrado.
