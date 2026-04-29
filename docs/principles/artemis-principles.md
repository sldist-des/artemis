# ARTEMIS Principles

ARTEMIS should stay small enough to operate and complete enough to trust.

## 1. Simples

The method must minimize moving parts.

- One canonical agent contract: `AGENTS.md`.
- One execution contract per task: Exec Pack.
- One visible state model: Kanban.
- One evidence path per run: `artifacts/<ticket>/run-XX/`.

Simplicity does not mean weak process. It means the next action is obvious.

## 2. State-of-the-art

ARTEMIS should track current agentic engineering practice without copying tool complexity blindly.

Adopt from Codex app-server:

- threads as durable work conversations;
- turns as bounded execution attempts;
- items as observable units of work;
- streamed events for status visibility;
- explicit approval surfaces for commands and file changes.

Adopt from Symphony:

- task board as control plane;
- issue/task state as state machine;
- per-task isolated workspace;
- bounded concurrency;
- observability and restart recovery.

## 3. Completude

No work is complete just because code changed.

A task is complete only when it has:

- intent;
- context;
- scope;
- execution;
- validation;
- evidence;
- review;
- handoff;
- archival.

## 4. Human-governed autonomy

The human defines architecture, risk, priorities, and merge. Agents prepare, execute, review, and preserve memory inside explicit contracts.

## 5. Evidence-first trust

Every ARTEMIS state should answer:

- What is the task?
- Who or what owns the next move?
- What evidence exists?
- What blocks progress?
- What decision is needed?
