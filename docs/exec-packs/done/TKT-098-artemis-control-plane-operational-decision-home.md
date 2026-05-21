# TKT-098 - ARTEMIS Control Plane Operational Decision Home

## Objetivo

Transformar a home simples do Control Plane em uma leitura operacional minima:
estado, proxima acao, arquivo a preencher e bloqueios reais.

## Nivel ARTEMIS da execucao

Nivel 2 - experiencia de portal, governanca de projeto e seguranca de runtime.

## Agentes envolvidos

- Codex executor: ajuste da home, script de validacao, artifacts e evento.
- Humano owner: leitor da proxima acao e autoridade para preencher decisao.

## Resultado esperado

A primeira tela mostra que a decisao esta pendente, aponta para o template de
decisao e explica que registro, troca de projeto e runtime continuam bloqueados.

## Escopo

- Consumir `project-registry-decision-intake.json`.
- Adicionar bloco operacional compacto na home.
- Validar proxima acao visivel.
- Validar link para template de decisao.
- Validar bloqueios visiveis.
- Emitir artifacts e evento canonico.

## Fora de escopo

- Registrar projeto externo.
- Preencher a decisao humana.
- Trocar projeto selecionado.
- Conectar auth de provider.
- Criar worktree.
- Iniciar runtime.
- Executar comandos.
- Gastar tokens.
- Fazer push, PR, deploy ou mutacao remota.

## Arquivos

- `docs/control-plane/ARTEMIS_CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md`
- `scripts/artemis-control-plane-operational-decision-home.sh`
- `control-plane/index.html`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/control-plane-operational-decision-home.json`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/STATUS.md`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/VALIDATION.md`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/HANDOFF.md`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/events.json`

## Validacao

```bash
sh -n scripts/artemis-control-plane-operational-decision-home.sh
scripts/artemis-control-plane-operational-decision-home.sh --artifact-root artifacts/artemis-control-plane-operational-decision-home/run-01 --json
python3 -m json.tool artifacts/artemis-control-plane-operational-decision-home/run-01/control-plane-operational-decision-home.json
python3 -m json.tool artifacts/artemis-control-plane-operational-decision-home/run-01/events.json
git diff --check
scripts/validate-artemis.sh
```

## Evidencias obrigatorias

- `artifacts/artemis-control-plane-operational-decision-home/run-01/control-plane-operational-decision-home.json`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/CONTROL_PLANE_OPERATIONAL_DECISION_HOME.md`
- `artifacts/artemis-control-plane-operational-decision-home/run-01/events.json`

## Handoff

Handoff aceito quando a home mostrar proxima acao, template de decisao e
bloqueios operacionais sem liberar registro, troca de projeto ou runtime.
