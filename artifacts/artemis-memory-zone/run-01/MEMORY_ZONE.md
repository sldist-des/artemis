# MEMORY ZONE

## Resultado

- Overall: `memory_zone_ready`.
- Reason: Human-AI Memory Zone contract is ready.

## Camadas

### human_vault

- Purpose: Notas, decisoes, runbooks e contexto editaveis por humanos e agentes.
- Format: `markdown_with_frontmatter`.
- Authority: `human_editable_git_versioned`.
- Runtime: `future_tolaria_compatible_vault`.

### project_memory

- Purpose: Estado operacional do projeto, decisoes, gates, exec packs e handoffs.
- Format: `artemis_artifacts_and_event_log`.
- Authority: `artifacts_are_evidence_git_is_memory`.
- Runtime: `current_repo`.

### derived_index

- Purpose: Indice incremental para busca semantica, grafo, freshness e lineage.
- Format: `future_cocoindex_dataflow`.
- Authority: `derived_read_model_not_source_of_truth`.
- Runtime: `future_optional_indexer`.

## Referencias

- Tolaria: https://github.com/refactoringhq/tolaria (`human_ai_vault_reference`).
- CocoIndex: https://github.com/cocoindex-io/cocoindex (`incremental_context_index_reference`).
