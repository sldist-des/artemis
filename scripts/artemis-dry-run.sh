#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

input="control-plane/tasks.json"
format="text"
generated=""

usage() {
  echo "usage: scripts/artemis-dry-run.sh [--input path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input)
      input="${2:-}"
      if [ -z "$input" ]; then
        usage
        exit 2
      fi
      shift 2
      ;;
    --json)
      format="json"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [ ! -f "$input" ]; then
  generated=$(mktemp "${TMPDIR:-/tmp}/artemis-dry-run.XXXXXX.json")
  scripts/artemis-tasks.sh >"$generated"
  input="$generated"
fi

python3 - "$input" "$format" <<'PY'
import json
import re
import sys

input_path = sys.argv[1]
output_format = sys.argv[2]

with open(input_path, "r", encoding="utf-8") as handle:
    payload = json.load(handle)

tasks = payload.get("tasks", [])
if not isinstance(tasks, list):
    raise SystemExit("task source JSON must contain a tasks array")

HUMAN_GATE_TERMS = (
    "push",
    "merge",
    "remoto",
    "remote",
    "github",
    "branch protection",
    "ruleset",
    "rulesets",
    "owner real",
    "owners reais",
    "secret",
    "secrets",
    "producao",
    "produção",
    "credencial",
    "credential",
    "token",
)

BLOCKED_TERMS = (
    "blocked",
    "bloqueado",
    "impedido",
)


def text_of(task):
    values = [
        task.get("ticket", ""),
        task.get("title", ""),
        task.get("summary", ""),
        task.get("owner", ""),
        task.get("risk", ""),
        task.get("exec_pack", ""),
        task.get("evidence", ""),
    ]
    tags = task.get("tags", [])
    if isinstance(tags, list):
        values.extend(str(tag) for tag in tags)
    return " ".join(str(value).lower() for value in values)


def occurrence_is_negated(start, term, haystack):
    plain = term.replace("fazer ", "")
    prefix = haystack[max(0, start - 40):start]
    negated_patterns = (
        f"sem {term}",
        f"sem {plain}",
        f"nao {term}",
        f"nao {plain}",
        f"não {term}",
        f"não {plain}",
    )
    if any(pattern in haystack[max(0, start - 8): start + len(term)] for pattern in negated_patterns):
        return True
    return "sem " in prefix or "nao " in prefix or "não " in prefix


def first_positive_term(terms, haystack):
    for term in terms:
        for match in re.finditer(re.escape(term), haystack):
            if not occurrence_is_negated(match.start(), term, haystack):
                return term
    return ""


def decide(task):
    state = str(task.get("state", "")).lower()
    ticket = str(task.get("ticket", "TASK"))
    exec_pack = str(task.get("exec_pack", ""))
    evidence = str(task.get("evidence", ""))
    owner = str(task.get("owner", ""))
    risk = str(task.get("risk", "medium")).lower()
    haystack = text_of(task)

    if state == "done":
        return {
            "ticket": ticket,
            "decision": "done",
            "runner": "none",
            "reason": "Task already archived in done state.",
        }

    if state in {"human", "human_gate"}:
        return {
            "ticket": ticket,
            "decision": "human_gate",
            "runner": "human",
            "reason": "Task state explicitly requires human decision.",
        }

    matched_human = first_positive_term(HUMAN_GATE_TERMS, haystack)
    if matched_human:
        return {
            "ticket": ticket,
            "decision": "human_gate",
            "runner": "human",
            "reason": f"Human gate term matched: {matched_human}.",
        }

    matched_blocked = next((term for term in BLOCKED_TERMS if term in haystack), "")
    if state == "blocked" or matched_blocked:
        reason = "Task state is blocked." if state == "blocked" else f"Blocked term matched: {matched_blocked}."
        return {
            "ticket": ticket,
            "decision": "blocked",
            "runner": "none",
            "reason": reason,
        }

    missing = []
    if not exec_pack:
        missing.append("exec_pack")
    if not owner:
        missing.append("owner")
    if not evidence:
        missing.append("evidence")
    if risk not in {"low", "medium", "high"}:
        missing.append("valid risk")

    if missing:
        return {
            "ticket": ticket,
            "decision": "blocked",
            "runner": "none",
            "reason": "Missing required fields: " + ", ".join(missing) + ".",
        }

    if state in {"ready", "context", "intake"}:
        return {
            "ticket": ticket,
            "decision": "eligible",
            "runner": "codex-cli",
            "reason": "Task has Exec Pack, owner, evidence target, and no human-gate terms.",
        }

    return {
        "ticket": ticket,
        "decision": "blocked",
        "runner": "none",
        "reason": f"State '{state or 'unknown'}' is not eligible for dispatch.",
    }


decisions = []
by_ticket = {str(task.get("ticket", "TASK")): task for task in tasks}

for task in tasks:
    decision = decide(task)
    original = by_ticket.get(decision["ticket"], task)
    decision["title"] = str(original.get("title", ""))
    decision["state"] = str(original.get("state", ""))
    decision["exec_pack"] = str(original.get("exec_pack", ""))
    decisions.append(decision)

summary = {
    "eligible": sum(1 for item in decisions if item["decision"] == "eligible"),
    "blocked": sum(1 for item in decisions if item["decision"] == "blocked"),
    "human_gate": sum(1 for item in decisions if item["decision"] == "human_gate"),
    "done": sum(1 for item in decisions if item["decision"] == "done"),
}

result = {
    "schema_version": 1,
    "source": input_path,
    "summary": summary,
    "decisions": decisions,
}

if output_format == "json":
    print(json.dumps(result, ensure_ascii=False, indent=2))
else:
    print("ARTEMIS Orchestrator Dry Run")
    print(f"source: {input_path}")
    print(
        "summary: "
        f"eligible={summary['eligible']} "
        f"blocked={summary['blocked']} "
        f"human_gate={summary['human_gate']} "
        f"done={summary['done']}"
    )
    print("")
    for item in decisions:
        print(f"- {item['ticket']} [{item['decision']}] runner={item['runner']}")
        print(f"  title: {item['title']}")
        print(f"  reason: {item['reason']}")
        if item["decision"] == "eligible":
            print(f"  would_dispatch: {item['runner']} --exec-pack {item['exec_pack']}")
PY

if [ -n "$generated" ]; then
  rm -f "$generated"
fi
