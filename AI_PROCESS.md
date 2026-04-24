# AI_PROCESS.md

Este repositorio segue ARTEMIS.

## Cadeia operacional

```text
Demanda humana
  -> Exec Pack
  -> Implementacao local
  -> Evidencias
  -> Revisao
  -> Commit Lore
  -> PR GitHub quando houver remoto
  -> Revisao humana
```

## Fonte de verdade

- Processo: `fluxo-artemis-claude-codex-v1.3.md`
- Agentes: `artemis-arquitetura-agentes.md` e `docs/agents/`
- GitHub: `artemis-github-operating-model.md`
- Contrato comum dos agentes: `AGENTS.md`
- Adaptador Claude Code: `CLAUDE.md`

## Exec Packs

Use:

```text
docs/exec-packs/
  backlog/
  active/
  done/
```

Cada tarefa relevante deve ter um Exec Pack com:

- objetivo;
- resultado esperado;
- nivel ARTEMIS;
- contexto minimo;
- escopo;
- fora de escopo;
- invariantes;
- comandos de validacao;
- evidencias obrigatorias;
- criterios de escalonamento.

## Artifacts

Use:

```text
artifacts/<ticket>/run-XX/
  STATUS.md
  VALIDATION.md
  HANDOFF.md
```

Adicione `FILES_CHANGED.md` e `RISKS.md` quando a tarefa justificar.

## Commits

Commits feitos por agente devem seguir o Lore Commit Protocol descrito no AGENTS.md raiz do ambiente.

Formato minimo:

```text
<intent line>

<contexto narrativo>

Constraint: <restricao>
Rejected: <alternativa rejeitada> | <motivo>
Confidence: <low|medium|high>
Scope-risk: <narrow|moderate|broad>
Directive: <aviso futuro>
Tested: <validacao>
Not-tested: <lacuna>
```

## Validacao canonica

```bash
scripts/validate-artemis.sh
```

## GitHub

Antes de push para remoto:

- revisar `.github/CODEOWNERS`;
- trocar placeholders por owners reais;
- definir branch protection/rulesets;
- configurar status checks do workflow CI.

