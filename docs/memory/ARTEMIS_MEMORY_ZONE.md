# ARTEMIS Memory Zone

ARTEMIS Memory Zone e a camada de memoria humano-AI do Symphony. Ela existe
para que humanos, Codex, Claude Code e futuros agentes compartilhem contexto,
decisoes, runbooks, evidencias e conhecimento operacional sem transformar chat
ou indice derivado em fonte de verdade.

## Inspiracao

Tolaria inspira a camada de vault humano-AI:

- files-first;
- git-first;
- offline-first;
- markdown com frontmatter;
- AI-first, mas nao AI-only.

CocoIndex inspira a camada de indice derivado:

- processamento incremental;
- freshness de contexto;
- lineage por transformacao;
- indices semanticos e grafos reconstruiveis;
- atualizacao por delta em vez de recomputacao total.

## Contrato ARTEMIS

- Markdown/Git e a memoria portavel.
- Artifacts ARTEMIS sao evidencia canonica.
- Event Log e a linha do tempo operacional.
- Indices derivados sao read models reconstruiveis.
- Secrets, tokens, credenciais e dados sensiveis ficam fora da memoria e dos
  indices por padrao.
- Agentes podem propor atualizacoes de memoria, mas alteracoes sensiveis passam
  por Human Gate.
- Nenhuma dependencia nova e instalada sem decisao explicita.

## Camadas

### Human Vault

Espaco editavel por humanos e agentes para notas, decisoes, runbooks, glossario,
contexto de projeto, diario operacional e documentacao leiga.

Formato planejado:

- markdown;
- frontmatter;
- links tipo wiki quando fizer sentido;
- versionamento Git;
- compatibilidade futura com Tolaria ou qualquer editor markdown.

### Project Memory

Memoria operacional que ja existe no ARTEMIS:

- Exec Packs;
- Validation Gate;
- Control Plane;
- Event Log;
- Handoff;
- artifacts.

### Derived Index

Indice reconstruivel para agentes consultarem contexto fresco:

- docs;
- codigo;
- artifacts;
- eventos;
- decisoes;
- handoffs;
- testes;
- relacoes do Project Operations Graph.

Essa camada pode ser implementada no futuro com CocoIndex, mas o contrato
ARTEMIS nao depende dele para funcionar.

## Uso futuro no painel

O Control Plane operacional deve usar a Memory Zone para responder:

- o que e este projeto;
- o que mudou recentemente;
- qual decisao explica este estado;
- qual agente trabalhou em que;
- o que esta bloqueado;
- qual contexto e seguro passar para cada agente;
- qual resumo leigo deve aparecer para operadores.

## Proximo corte

`TKT-054 - Project Operations Graph do ARTEMIS Symphony`
