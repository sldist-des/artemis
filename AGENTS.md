# AGENTS.md

Este repositorio mantem o metodo ARTEMIS: Arquitetura, Ritmo, Trabalho Estruturado, Memoria, Implementacao e Supervisao.

## Projeto

O objetivo deste repositorio e transformar o ARTEMIS em um kit operacional reutilizavel para humanos, Codex, Claude Code e futuros agentes de codigo.

## Fonte canonica para agentes

Este arquivo e a fonte canonica de orientacao operacional para agentes.

`CLAUDE.md` deve ser apenas um adaptador fino para Claude Code e deve apontar para este arquivo. Nao duplique regras entre `AGENTS.md` e `CLAUDE.md`; quando uma regra vale para Codex e Claude, ela pertence aqui.

## Documentos que agentes devem ler

- `README.md`
- `ARTEMIS_QUICKSTART.md`
- `ARTEMIS_WORKFLOW.md`
- `ARTEMIS_INTEGRATIONS.md`
- `fluxo-artemis-claude-codex-v1.3.md`
- `artemis-arquitetura-agentes.md`
- `artemis-github-operating-model.md`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH.md`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_GRAPH_VIEW.md`
- `docs/symphony/ARTEMIS_SYMPHONY_PROJECT_BRIEF.md`
- `docs/symphony/ARTEMIS_SYMPHONY_GUIDED_COLLABORATION.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_LAUNCH_CONTRACT.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_DRY_RUN.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_APPROVAL_GATE.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_DECISION_INTAKE.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_LAUNCHER_PREFLIGHT.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_LAUNCHER_COMMAND_PLAN.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_LAUNCHER_EXECUTION_GATE.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_LAUNCHER_SUPERVISED_EXECUTION.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_EXECUTION_RESULT_INTAKE.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_POST_EXECUTION_VALIDATION_GATE.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_COMPLETION_HANDOFF.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_COMPLETION_REVIEW_GATE.md`
- `docs/symphony/ARTEMIS_SYMPHONY_AGENT_RUNTIME_DONE_LEDGER.md`
- `docs/portal/ARTEMIS_PORTAL_AUTH_PLAN.md`
- `docs/portal/ARTEMIS_PORTAL_CREDENTIAL_VAULT.md`
- Exec Pack ativo em `docs/exec-packs/active/`

## Comandos canonicos

```bash
scripts/validate-artemis.sh
scripts/artemis-integrations.sh --project . --agent both
scripts/artemis-guided-collaboration.sh --json
scripts/artemis-agent-launch-contract.sh --json
scripts/artemis-agent-runtime-dry-run.sh --json
scripts/artemis-agent-runtime-approval-gate.sh --json
scripts/artemis-agent-runtime-decision-intake.sh --json
scripts/artemis-agent-runtime-launcher-preflight.sh --json
scripts/artemis-agent-runtime-launcher-command-plan.sh --json
scripts/artemis-agent-runtime-launcher-execution-gate.sh --json
scripts/artemis-agent-runtime-launcher-supervised-execution.sh --json
scripts/artemis-agent-runtime-execution-result-intake.sh --json
scripts/artemis-agent-runtime-post-execution-validation-gate.sh --json
scripts/artemis-agent-runtime-completion-handoff.sh --json
scripts/artemis-agent-runtime-completion-review-gate.sh --json
scripts/artemis-agent-runtime-done-ledger.sh --json
scripts/artemis-portal-auth-plan.sh --json
scripts/artemis-portal-credential-vault.sh --json
scripts/github-readiness.sh
sh -n scripts/bootstrap-artemis.sh
git status --branch --short --ignored
```

## Workflow ARTEMIS

- Toda tarefa relevante deve ter Exec Pack.
- Toda mudanca deve ser versionada em Git.
- Um agente escritor por worktree.
- Mudancas fora de escopo devem ser registradas e escaladas.
- Toda entrega deve incluir validacao e handoff.
- Commits devem seguir o Lore Commit Protocol quando forem feitos por agente.

## Referencias externas e inspiracao etica

- Agentes podem ler codigo publico de projetos de referencia para entender arquitetura, fluxo, UX, contratos, tradeoffs e padroes tecnicos.
- Ler codigo de referencia nao autoriza copiar implementacao, trechos substanciais, assets, marcas, textos proprietarios ou estrutura licenciada de forma incompatível.
- Aprendizados devem virar decisao propria do ARTEMIS: contrato, invariant, interface, teste, artefato ou implementacao original.
- Quando a licenca puder afetar o projeto, registre a referencia e escale antes de vendorizar codigo, instalar dependencia, portar modulo ou reproduzir estrutura interna.
- Intencao reta nao substitui rastreabilidade: cite a fonte, preserve autoria externa e deixe claro o que foi adotado, rejeitado e recriado.

## Review guidelines

- Trate vazamento de secrets como P0.
- Trate quebra de autenticacao/autorizacao como P0.
- Trate violacao de invariantes arquiteturais como P1.
- Trate mudanca de contrato publico sem documentacao como P1.
- Trate testes ausentes em codigo critico como P1.
- Ignore preferencias cosmeticas salvo quando contrariem padrao documentado.

## Escalar para humano

Escalar antes de:

- criar remoto GitHub;
- fazer push;
- alterar producao;
- tocar secrets;
- configurar owners, rulesets ou branch protection reais;
- introduzir nova dependencia;
- expandir escopo de forma relevante.
