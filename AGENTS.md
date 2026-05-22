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
- `docs/portal/ARTEMIS_PORTAL_AGENT_REGISTRY.md`
- `docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md`
- `docs/portal/ARTEMIS_PORTAL_BUDGET_LEDGER.md`
- `docs/portal/ARTEMIS_PORTAL_WORKSPACE_SESSION.md`
- `docs/portal/ARTEMIS_PORTAL_RUNTIME_SESSION.md`
- `docs/portal/ARTEMIS_PORTAL_AGENT_CONVERSATION.md`
- `docs/portal/ARTEMIS_PORTAL_TASK_CONTROL_SURFACE.md`
- `docs/portal/ARTEMIS_PORTAL_VALIDATION_EVIDENCE_SURFACE.md`
- `docs/portal/ARTEMIS_PORTAL_HUMAN_ACCEPTANCE_SURFACE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_SELECTOR_REGISTRY_INTAKE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_HUMAN_REVIEW_GATE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_DECISION_INTAKE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_GATE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_APPROVED_DECISION_FIXTURE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_PLAN.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_EXECUTION_GATE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_DRY_RUN.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_PACKAGE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVAL_INTAKE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_APPROVED_WRITE_FIXTURE.md`
- `docs/portal/ARTEMIS_PORTAL_PROJECT_REGISTRY_REGISTRATION_WRITE_GATE.md`
- `docs/portal/ARTEMIS_PORTAL_LOCAL_PROJECT_CONNECT.md`
- `docs/portal/ARTEMIS_PORTAL_EXTERNAL_PROJECT_REGISTRATION.md`
- `docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY.md`
- `docs/portal/ARTEMIS_PORTAL_RUNTIME_GATEWAY_SERVICE.md`
- `docs/control-plane/ARTEMIS_CONTROL_PLANE_PROJECT_REGISTRY_HOME_STATE.md`
- `docs/control-plane/ARTEMIS_CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md`
- `docs/models/ARTEMIS_MODEL_API_GOVERNANCE.md`
- `docs/principles/ARTEMIS_SOCRATIC_LOGIC.md`
- `docs/principles/ARTEMIS_SOCRATIC_APPLICATION_GATE.md`
- `docs/agents/ARTEMIS_SUBAGENT_SOCRATIC_ROUTER.md`
- `docs/agents/ARTEMIS_SUBAGENT_CONFIG_GENERATOR.md`
- Exec Pack ativo em `docs/exec-packs/active/`

## Comandos canonicos

```bash
scripts/validate-artemis.sh
scripts/artemis-integrations.sh --project . --agent both
scripts/artemis-guided-collaboration.sh --json
scripts/artemis-socratic-logic.sh --json
scripts/artemis-socratic-application-gate.sh --json
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
scripts/artemis-subagent-socratic-router.sh --json
scripts/artemis-subagent-config-generator.sh --json
scripts/artemis-portal-auth-plan.sh --json
scripts/artemis-portal-credential-vault.sh --json
scripts/artemis-portal-agent-registry.sh --json
scripts/artemis-portal-run-assignment.sh --json
scripts/artemis-portal-budget-ledger.sh --json
scripts/artemis-portal-workspace-session.sh --json
scripts/artemis-portal-runtime-session.sh --json
scripts/artemis-portal-agent-conversation.sh --json
scripts/artemis-portal-task-control-surface.sh --json
scripts/artemis-portal-validation-evidence-surface.sh --json
scripts/artemis-portal-human-acceptance-surface.sh --json
scripts/artemis-portal-project-selector.sh --json
scripts/artemis-portal-project-selector-registry-intake.sh --json
scripts/artemis-portal-project-registry-human-review-gate.sh --json
scripts/artemis-portal-project-registry-decision-intake.sh --json
scripts/artemis-portal-project-registry-registration-gate.sh --json
scripts/artemis-portal-project-registry-approved-decision-fixture.sh --json
scripts/artemis-portal-project-registry-registration-plan.sh --json
scripts/artemis-portal-project-registry-registration-execution-gate.sh --json
scripts/artemis-portal-project-registry-registration-dry-run.sh --json
scripts/artemis-portal-project-registry-registration-approval-package.sh --json
scripts/artemis-portal-project-registry-registration-approval-intake.sh --json
scripts/artemis-portal-project-registry-registration-approved-write-fixture.sh --json
scripts/artemis-portal-project-registry-registration-write-gate.sh --json
scripts/artemis-model-registry.sh --json
scripts/artemis-provider-capability-probes.sh --json
scripts/artemis-model-migration-gate.sh --json
scripts/artemis-provider-operational-evals.sh --json
scripts/artemis-token-budget-policy.sh --json
scripts/artemis-model-docs-radar.sh --json
scripts/artemis-model-change-intake.sh --json
scripts/artemis-model-review-fixture.sh --json
scripts/artemis-model-review-gate.sh --json
scripts/artemis-model-review-decision-intake.sh --json
scripts/artemis-portal-local-project-connect.sh --project . --json
scripts/artemis-portal-external-project-registration.sh --json
scripts/artemis-portal-runtime-gateway.sh --json
scripts/artemis-portal-runtime-gateway-service.sh --json
scripts/artemis-control-plane-external-project-registration-view.sh --json
scripts/artemis-control-plane-local-project-connect-view.sh --json
scripts/artemis-control-plane-runtime-gateway-view.sh --json
scripts/artemis-control-plane-project-registry-home-state.sh --json
scripts/artemis-control-plane-operational-decision-home.sh --json
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
