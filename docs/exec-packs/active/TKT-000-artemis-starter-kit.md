# TKT-000 - Montar starter kit ARTEMIS

## Objetivo

Transformar os documentos-base do ARTEMIS em uma estrutura pronta para aplicar em qualquer projeto, com templates, prompts e guia de uso.

## Resultado esperado

Um humano ou AI coder usando Codex/Claude Code deve conseguir copiar o kit para um projeto novo e iniciar o fluxo com Context Pack, agentes, evidencias e PR.

## Nivel ARTEMIS da execucao

Nivel 1 - Preparar, executar, revisar.

## Agentes envolvidos

- Context Curator: esta sessao, ao ler os documentos e montar o pacote.
- Implementer: esta sessao, ao criar templates e scripts.
- Reviewer: esta sessao, em revisao leve de estrutura e consistencia.
- Memory Keeper: artifacts finais desta rodada.

## Contexto minimo

Ler primeiro:

- `fluxo-artemis-claude-codex-v1.3.md`
- `artemis-arquitetura-agentes.md`
- `artemis-github-operating-model.md`

## Escopo

- Criar entrada curta do processo.
- Criar templates reutilizaveis.
- Criar prompts operacionais.
- Criar script de bootstrap conservador.
- Registrar evidencias da rodada.

## Fora de escopo

- Configurar GitHub real.
- Criar branch, PR ou ruleset, porque `/srv/veri` ainda nao e um repositorio Git.
- Instalar ferramentas externas.
- Consultar documentacao online nesta rodada.

## Invariantes

- ARTEMIS deve comecar simples e escalar somente quando houver ganho real.
- Um worktree deve ter um agente escritor principal.
- Toda tarefa relevante deve produzir evidencia.
- Arquivos de orientacao para agentes devem ser curtos e praticos.

## Ferramentas autorizadas

- Leitura local.
- Criacao de arquivos no workspace.
- Shell seguro para listar e validar estrutura.

## Ferramentas proibidas

- Deploy.
- Escrita em sistemas externos.
- Operacoes Git destrutivas.
- Instalacao de dependencias.

## Politica de permissao

Sem confirmacao: criar docs, templates e script local dentro de `/srv/veri`.

Com confirmacao: comandos destrutivos, rede, instalacao, escrita fora do workspace.

Nunca nesta tarefa: deploy, secrets, alteracao de producao.

## Comandos de validacao

```bash
find . -maxdepth 4 -type f | sort
sh -n scripts/bootstrap-artemis.sh
```

## Evidencia minima

- `artifacts/artemis-bootstrap/run-01/STATUS.md`
- `artifacts/artemis-bootstrap/run-01/FILES_CHANGED.md`
- `artifacts/artemis-bootstrap/run-01/VALIDATION.md`
- `artifacts/artemis-bootstrap/run-01/RISKS.md`
- `artifacts/artemis-bootstrap/run-01/HANDOFF.md`

## Escalonar para humano se

- For necessario escolher politica de GitHub real.
- For necessario definir nomes de organizacao, CODEOWNERS reais ou repositorios.
- For necessario sobrescrever arquivos existentes em projeto alvo.

## Entregaveis

- README e quickstart.
- Templates.
- Prompts.
- Bootstrap script.
- Artifacts da rodada.

