# TKT-071 - ARTEMIS portable integration

## Objetivo

Facilitar a aplicacao do ARTEMIS em qualquer projeto com uma entrada parecida
com ferramentas modernas de agentes: comando unico, perfis de instalacao,
blocos prontos para Codex/Claude e verificacao simples.

## Resultado esperado

Um humano deve conseguir instalar ARTEMIS em modo leve ou completo, gerar blocos
de entrada para Codex CLI e Claude Code, e abrir o Control Plane local quando o
perfil completo for escolhido.

## Nivel ARTEMIS da execucao

Nivel 1 - ajuste de metodo, scripts e documentacao.

## Agentes envolvidos

- Codex: implementacao, validacao e handoff.

## Arquivos de contexto

- `scripts/bootstrap-artemis.sh`
- `scripts/artemis-integrations.sh`
- `ARTEMIS_INTEGRATIONS.md`
- `ARTEMIS_APPLY.md`
- `README.md`

## Escopo

- Adicionar `--profile lite|full` ao bootstrap.
- Instalar guias canonicos que o template `AGENTS.md` ja referencia.
- Criar helper para imprimir blocos de entrada para Codex e Claude Code.
- Documentar o caminho de integracao portavel.

## Fora de escopo

- Criar servidor MCP/REST real.
- Instalar dependencias externas.
- Iniciar Codex, Claude Code, app-server, daemon ou runners reais.
- Copiar codigo de projetos externos.

## Invariantes

- `AGENTS.md` continua fonte canonica comum.
- `CLAUDE.md` continua adaptador fino.
- Bootstrap nao sobrescreve arquivos existentes.
- `full` adiciona superficie visual local, mas nao substitui Git, Exec Packs,
  artifacts e validacao como fonte de verdade.

## Comandos de validacao

```bash
sh -n scripts/bootstrap-artemis.sh
sh -n scripts/artemis-integrations.sh
scripts/artemis-integrations.sh --project /tmp/example --agent both
scripts/artemis-integrations.sh --project /tmp/example --agent codex --format json
scripts/bootstrap-artemis.sh --profile lite /tmp/artemis-bootstrap-lite
scripts/bootstrap-artemis.sh --profile full /tmp/artemis-bootstrap-full
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `scripts/artemis-integrations.sh`
- `ARTEMIS_INTEGRATIONS.md`
- `docs/exec-packs/done/TKT-071-artemis-portable-integration.md`

## Criterio de handoff

Handoff aceito quando os perfis instalam os arquivos esperados, os blocos de
integracao sao gerados em Markdown e JSON, e a validacao do repositorio passa.
