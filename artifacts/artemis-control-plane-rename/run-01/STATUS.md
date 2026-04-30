# STATUS - ARTEMIS Control Plane Rename Run 01

## Estado

Concluido localmente; aguardando apenas push remoto quando a autenticacao GitHub estiver disponivel.

## Objetivo

Renomear a superficie visual para ARTEMIS Control Plane e remover referencias correntes ao nome antigo.

## Acoes realizadas

- Superficie visual movida para `control-plane/index.html`.
- Especificacao movida para `docs/control-plane/artemis-control-plane.md`.
- README, principios, validador e TKT-005 atualizados para a nova nomenclatura.
- Artifact do TKT-005 renomeado para `artifacts/artemis-control-plane/run-01`.
- Plano de orquestracao e TKT-006 atualizados para apontar para Control Plane.

## Validacao

- `scripts/validate-artemis.sh` passou.
- `git diff --check` passou.
- Chrome headless renderizou `control-plane/index.html` em `/tmp/artemis-control-plane.png`.
- Busca de nomenclatura corrente nao encontrou referencias conceituais ao nome antigo nos docs ativos.
