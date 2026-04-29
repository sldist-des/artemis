# ARTEMIS Kanban

The ARTEMIS Kanban is the visual control plane for the method.

## Purpose

The board shows the state of each meaningful ARTEMIS task from idea to archival. It is intentionally smaller than a full orchestrator: it lets the human architect see flow, evidence, and blocked decisions without requiring a daemon, database, issue tracker integration, or app-server client.

## Reference cuts from OpenAI materials

From Codex app-server, ARTEMIS borrows the idea that rich clients should model work as durable threads, bounded turns, and observable items. App-server also emphasizes streamed events and approval surfaces for commands and file changes.

From Symphony, ARTEMIS borrows the idea that the task board is the control plane, tasks are a state machine, and each active unit of work should map to an isolated workspace with visible status and evidence.

ARTEMIS deliberately does not implement the full Symphony daemon yet. The first version is a static board that can later be connected to GitHub Issues, Exec Packs, or Codex app-server events.

Sources:

- https://developers.openai.com/codex/app-server
- https://openai.com/index/open-source-codex-orchestration-symphony/

## Columns

| Column | Meaning | Exit condition |
|---|---|---|
| Intake | Raw idea or request | Intent is clear enough to create an Exec Pack |
| Context | Context Pack / Exec Pack preparation | Scope, risks, validation and evidence are defined |
| Ready | Ready for agent or human executor | Workspace/branch strategy and owner are known |
| Executing | Implementation or investigation in progress | Diff, docs or investigation result exists |
| Review | AI or technical review | Findings addressed or accepted |
| Human | Human architecture/product decision | Human approves, rejects or splits follow-up |
| Done | Archived and evidenced | Handoff exists and task is no longer active |

## Card contract

Each card should show:

- ticket id;
- title;
- owner;
- risk;
- current next action;
- evidence links;
- principle tags.

## First implementation

`kanban/index.html` is self-contained and can be opened directly in a browser. It persists local card moves in `localStorage` and includes a reset action.

No backend is introduced in this phase.
