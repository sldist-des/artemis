# TKT-075 - ARTEMIS Portal Run Assignment Contract

## Objetivo

Definir o contrato de Run Assignment do ARTEMIS Portal para vincular uma tarefa
do projeto a um perfil registrado antes de qualquer launcher, runtime, custo ou
comando real.

## Resultado esperado

Um contrato verificavel deve definir assignment record, campos obrigatorios,
campos proibidos, estados, gates, regras de selecao, policies obrigatorias,
stop rule e evidencia antes de passar uma tarefa ao launcher.

## Nivel ARTEMIS da execucao

Nivel 2 - seguranca operacional e arquitetura de portal.

## Agentes envolvidos

- Codex: implementacao, documentacao, validacao e handoff.

## Arquivos de contexto

- `docs/portal/ARTEMIS_PORTAL_AGENT_REGISTRY.md`
- `docs/portal/ARTEMIS_PORTAL_RUN_ASSIGNMENT.md`
- `scripts/artemis-portal-run-assignment.sh`
- `artifacts/artemis-portal-agent-registry/run-01/agent-registry-contract.json`
- `control-plane/tasks.json`

## Escopo

- Definir Run Assignment como contrato pre-launcher.
- Definir schema conceitual de assignment record.
- Definir campos proibidos para impedir secrets e output bruto de runtime.
- Definir state model e gates antes de launcher preflight.
- Definir regras de selecao de perfil.
- Definir policy bindings para budget, workspace, validation, Human Gate,
  credential lease e evidence.
- Gerar artifact local read-only com JSON, Markdown e evento canonico.

## Fora de escopo

- Autenticar providers.
- Emitir vault lease real.
- Iniciar agente real.
- Executar comando.
- Gastar tokens.
- Criar scheduler real.
- Fazer push, PR, deploy ou mutacao remota.

## Invariantes

- Assignment nao executa runtime.
- Assignment nao guarda segredo.
- Perfil escolhido deve existir no Agent Registry.
- Budget policy precede gasto.
- Credential lease policy precede runtime provider-backed.
- Workspace policy preserva um escritor por worktree.
- Validation policy precede Done.
- Human Gate precede remote write, provider auth, producao e runtime longo.

## Comandos de validacao

```bash
sh -n scripts/artemis-portal-run-assignment.sh
scripts/artemis-portal-run-assignment.sh --artifact-root artifacts/artemis-portal-run-assignment/run-01 --json
python3 -m json.tool artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json
python3 -m json.tool artifacts/artemis-portal-run-assignment/run-01/events.json
scripts/validate-artemis.sh
git diff --check
```

## Evidencias obrigatorias

- `artifacts/artemis-portal-run-assignment/run-01/run-assignment-contract.json`
- `artifacts/artemis-portal-run-assignment/run-01/RUN_ASSIGNMENT.md`
- `artifacts/artemis-portal-run-assignment/run-01/events.json`

## Criterio de handoff

Handoff aceito quando o contrato de Run Assignment estiver documentado,
artifactado, validado e sem provider auth, lease real, runtime, comandos, gasto
de token ou mutacao remota.
