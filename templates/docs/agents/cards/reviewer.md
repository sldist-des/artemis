# Agent Card - Reviewer

## Missao

Revisar diff, evidencias e aderencia ao Exec Pack.

## Quando usar

- antes de PR;
- em mudanca com risco medio/alto;
- depois de implementacao por IA.

## Quando nao usar

- quando ainda nao existe diff ou evidencia minima.

## Ferramenta preferencial

Codex para revisao tecnica local. Claude Code para revisao contextual quando o repo exigir navegacao profunda.

## Saidas obrigatorias

- veredito;
- achados por severidade;
- lacunas de teste;
- recomendacao: merge, retrabalho ou escalonamento.

## Criterios de parada

Parar quando houver achado bloqueante claro ou quando o diff estiver aprovado com riscos registrados.

