# ARTEMIS Model/API Governance

## Objetivo

Manter modelos, APIs, SDKs e CLIs como infraestrutura viva do metodo ARTEMIS.
O metodo deve rotear por capacidade e papel operacional, nao por nome fixo de
modelo.

## Principio

O ARTEMIS depende de papeis, capacidades, validacoes e gates. O modelo real e
um binding versionado que pode mudar quando houver evidencia.

## Contrato

- `config/artemis-model-registry.json` registra provedores, papeis de
  capacidade, bindings simbolicos e regras de migracao.
- `scripts/artemis-model-registry.sh` valida o registro local.
- `scripts/artemis-provider-capability-probes.sh` faz probes locais de CLI sem
  autenticar provider nem chamar API.
- `scripts/artemis-model-migration-gate.sh` bloqueia mudancas de default ate
  haver docs oficiais, probes, evals, custo e decisao humana.
- `scripts/artemis-provider-operational-evals.sh` define evals operacionais
  antes de promover modelo.
- `scripts/artemis-token-budget-policy.sh` fixa limites de token/custo por
  classe de tarefa.
- `scripts/artemis-model-docs-radar.sh` registra fontes oficiais, frescor
  esperado e evidencia de revisao antes de migracoes.

## Invariantes

- Nenhum nome de modelo vira autoridade canonica sozinho.
- Toda atualizacao de modelo/API precisa de fonte oficial atualizada.
- Toda migracao precisa de probe local, eval operacional e gate humano.
- Toda execucao com gasto precisa de budget policy antes do runtime.
- Nenhum script desta camada le secrets, autentica provider, inicia agentes,
  chama APIs, gasta tokens ou altera remoto.
- O Documentation Radar nao faz fetch externo sozinho; ele exige revisao
  explicita e artefato de evidencia antes de liberar um Change Intake.
