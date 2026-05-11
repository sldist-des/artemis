# ARTEMIS AGENT LAUNCH CONTRACT HANDOFF

O contrato supervisionado de lancamento de agentes esta pronto como superficie read-only. A partir dele o painel sabe o que precisa existir antes de acionar Codex app-server, Claude Code ou outro runtime.

Proximo corte:

- Implementar `TKT-062 - Agent Runtime Launcher Preflight do ARTEMIS Symphony`.
- Usar o Agent Runtime Decision Intake como entrada obrigatoria antes de qualquer launcher real.
