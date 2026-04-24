# CLAUDE.md

Este projeto usa ARTEMIS.

Leia e siga primeiro:

- `AGENTS.md`
- Exec Pack ativo em `docs/exec-packs/active/`

## Papel deste arquivo

Este arquivo e apenas um adaptador para Claude Code. As regras compartilhadas entre Codex e Claude pertencem a `AGENTS.md`.

Nao duplique aqui workflow, arquitetura, criterios de review ou politicas gerais. Se uma regra vale para todos os agentes, atualize `AGENTS.md`.

## Especifico para Claude Code

- Use este arquivo como ponte de entrada para encontrar `AGENTS.md`.
- Antes de implementar, apresente plano curto, riscos e validacoes quando a tarefa nao for trivial.
- Use subagents, hooks e skills somente quando reduzirem risco, ruido ou tempo total.
- Termine sessoes longas com handoff claro.
- Nao altere escopo fora do Exec Pack sem registrar e escalar.

