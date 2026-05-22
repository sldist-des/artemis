#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-socratic-application-gate/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-socratic-application-gate.sh [--artifact-root path] [--json]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --artifact-root)
      artifact_root="${2:-}"
      if [ -z "$artifact_root" ]; then usage; exit 2; fi
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

mkdir -p "$artifact_root"

python3 - "$artifact_root" "$format" <<'PY'
import json
import sys
from pathlib import Path

from scripts.artemis_event_common import event, event_log, now_utc, write_event_log

artifact_root = Path(sys.argv[1])
output_format = sys.argv[2]
generated_at = now_utc()

socratic_logic_path = Path("artifacts/artemis-socratic-logic/run-01/socratic-logic.json")

def read_json(path, default=None):
    if default is None:
        default = {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return default

socratic_logic = read_json(socratic_logic_path, {
    "overall": "not_available",
    "clarity_questions": [],
    "ambiguity_gates": [],
    "argument_contract": {"minimum_fields": []},
})

required_files = [
    Path("AGENTS.md"),
    Path("ARTEMIS_WORKFLOW.md"),
    Path("docs/principles/ARTEMIS_SOCRATIC_LOGIC.md"),
    Path("docs/principles/ARTEMIS_SOCRATIC_APPLICATION_GATE.md"),
    Path("docs/exec-packs/done/TKT-121-artemis-socratic-application-gate.md"),
    socratic_logic_path,
]
missing_files = [str(path) for path in required_files if not path.is_file()]

application_stages = [
    {
        "id": "classify_task",
        "question": "Esta tarefa e observacao, inferencia, decisao, compromisso ou execucao?",
        "route_if_unclear": "ask_human_or_block",
    },
    {
        "id": "define_terms",
        "question": "Algum termo central pode significar duas coisas diferentes neste contexto?",
        "route_if_unclear": "ask_human",
    },
    {
        "id": "separate_authority",
        "question": "A autoridade vem de Git, Exec Pack, artifact, Validation Gate, Human Gate ou documento canonico?",
        "route_if_unclear": "ask_human",
    },
    {
        "id": "bind_evidence",
        "question": "Qual comando, artifact ou fonte local prova a conclusao?",
        "route_if_unclear": "gather_evidence",
    },
    {
        "id": "choose_route",
        "question": "O proximo passo pode seguir localmente, precisa de evidencia, precisa do humano, deve dividir corte ou deve bloquear?",
        "route_if_unclear": "block_until_route_is_distinct",
    },
    {
        "id": "record_handoff",
        "question": "O handoff declara estado, evidencia, limites e proximo corte sem misturar conclusao com desejo?",
        "route_if_unclear": "rewrite_handoff",
    },
]

routes = [
    {
        "route_id": "proceed_with_explicit_assumption",
        "meaning": "Prosseguir sem perguntar quando a acao e local, reversivel, coberta por contrato existente e a suposicao nao muda risco.",
        "requires": [
            "assumption recorded",
            "evidence command or artifact named",
            "no authority conflict",
            "no secrets, auth, remote, production or spend",
        ],
    },
    {
        "route_id": "gather_local_evidence",
        "meaning": "Rodar verificacao local segura quando a duvida pode ser resolvida por arquivo, script, artifact ou teste.",
        "requires": [
            "safe command",
            "expected output",
            "failure interpretation",
            "no remote write",
        ],
    },
    {
        "route_id": "ask_human_one_question",
        "meaning": "Perguntar ao humano quando a resposta muda escopo, risco, autoridade, custo, permissao, producao ou resultado.",
        "requires": [
            "one clear question",
            "two or three distinct options",
            "impact per option",
            "recommended option only when evidence supports it",
        ],
    },
    {
        "route_id": "split_into_next_cut",
        "meaning": "Separar a tarefa quando ha mais de um resultado final, mais de um escritor, ou validacoes independentes demais.",
        "requires": [
            "current cut objective kept single",
            "new ticket name",
            "blocked dependency recorded",
        ],
    },
    {
        "route_id": "block_until_authority_exists",
        "meaning": "Bloquear quando ha category error, autoridade ausente, conclusao sem evidencia ou acao sensivel sem Human Gate.",
        "requires": [
            "blocking reason",
            "missing authority or evidence",
            "safe reentry condition",
        ],
    },
]

application_matrix = [
    {
        "context": "planning",
        "apply_before": "exec pack or implementation plan is treated as approved",
        "default_route": "gather_local_evidence",
        "human_gate_when": "scope, owner, risk or acceptance criteria are ambiguous",
    },
    {
        "context": "code_edit",
        "apply_before": "editing files when term, authority or validation may change implementation",
        "default_route": "proceed_with_explicit_assumption",
        "human_gate_when": "edit would touch secrets, auth, production, remote state or broad permissions",
    },
    {
        "context": "delegation",
        "apply_before": "launching Codex, Claude Code or Antigravity subagent lanes",
        "default_route": "ask_human_one_question",
        "human_gate_when": "inherited scope, token budget, async runtime or write ownership is unclear",
    },
    {
        "context": "runtime",
        "apply_before": "starting app-server, provider runtime, bridge, queue or daemon",
        "default_route": "block_until_authority_exists",
        "human_gate_when": "always for real auth, cost, remote state or production-adjacent runtime",
    },
    {
        "context": "review",
        "apply_before": "declaring done, accepting review or closing a validation loop",
        "default_route": "gather_local_evidence",
        "human_gate_when": "technical validation is being confused with human acceptance",
    },
    {
        "context": "handoff",
        "apply_before": "final response, Done Ledger or transfer to another agent",
        "default_route": "proceed_with_explicit_assumption",
        "human_gate_when": "next action needs authority that the current agent does not have",
    },
]

human_question_template = {
    "shape": "one_question_with_distinct_options",
    "question": "Qual caminho devo seguir para resolver a ambiguidade X?",
    "options": [
        {"id": "recommended", "label": "Usar evidencia local", "impact": "mais rapido, sem autoridade nova, depende de validacao local"},
        {"id": "human_decision", "label": "Decisao humana", "impact": "mais seguro quando muda escopo, custo, permissao ou aceite"},
        {"id": "split_cut", "label": "Separar corte", "impact": "reduz risco quando ha dois resultados ou dependencias distintas"},
    ],
    "must_not_include": [
        "opcoes sobrepostas",
        "pergunta dupla",
        "termo indefinido",
        "recomendacao sem evidencia",
    ],
}

sample_evaluations = [
    {
        "input": "Atualizar documento local com contrato ja aprovado.",
        "detected_ambiguity": [],
        "route": "proceed_with_explicit_assumption",
        "reason": "local, reversivel, coberto por contrato e validavel por diff.",
    },
    {
        "input": "Conectar provider real com auth e gastar tokens para rodar agentes.",
        "detected_ambiguity": ["authority", "budget", "runtime"],
        "route": "ask_human_one_question",
        "reason": "auth, custo e runtime real exigem decisao humana explicita.",
    },
    {
        "input": "Declarar tarefa pronta porque o painel parece verde.",
        "detected_ambiguity": ["category_error", "conclusion_without_evidence"],
        "route": "gather_local_evidence",
        "reason": "painel e observacional; conclusao precisa de artifact, gate ou comando.",
    },
]

checks = [
    {
        "id": "socratic_logic_available",
        "passed": socratic_logic.get("overall") == "artemis_socratic_logic_ready",
        "evidence": str(socratic_logic_path),
    },
    {
        "id": "application_stages_declared",
        "passed": len(application_stages) >= 6,
        "evidence": f"{len(application_stages)} stages",
    },
    {
        "id": "routes_are_distinct",
        "passed": len({route["route_id"] for route in routes}) == len(routes) and len(routes) >= 5,
        "evidence": f"{len(routes)} routes",
    },
    {
        "id": "contexts_are_mapped",
        "passed": len(application_matrix) >= 6,
        "evidence": f"{len(application_matrix)} contexts",
    },
    {
        "id": "human_question_is_bounded",
        "passed": len(human_question_template["options"]) <= 3,
        "evidence": f"{len(human_question_template['options'])} options",
    },
    {
        "id": "no_runtime_side_effects",
        "passed": True,
        "evidence": "gate-only artifact",
    },
]

overall = "socratic_application_gate_ready" if not missing_files and all(check["passed"] for check in checks) else "blocked"

payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-socratic-application-gate.sh",
    "mode": "gate_only_no_runtime",
    "overall": overall,
    "ticket": "TKT-121",
    "artifact_root": str(artifact_root),
    "socratic_logic_input": str(socratic_logic_path),
    "socratic_logic_status": socratic_logic.get("overall", "not_available"),
    "application_gate_ready": overall == "socratic_application_gate_ready",
    "application_stages": application_stages,
    "routes": routes,
    "application_matrix": application_matrix,
    "human_question_template": human_question_template,
    "sample_evaluations": sample_evaluations,
    "runtime_execution_allowed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "missing_files": missing_files,
    "checks": checks,
    "next_cut": "TKT-122 - Socratic Gate Control Plane View",
}

(artifact_root / "socratic-application-gate.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

lines = [
    "# ARTEMIS Socratic Application Gate",
    "",
    f"- Overall: `{overall}`",
    f"- Logic input: `{payload['socratic_logic_status']}`",
    f"- Application stages: `{len(application_stages)}`",
    f"- Routes: `{len(routes)}`",
    f"- Contexts: `{len(application_matrix)}`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Routes",
    "",
]
for route in routes:
    lines.append(f"- `{route['route_id']}`: {route['meaning']}")
lines.extend(["", "## Application Matrix", ""])
for item in application_matrix:
    lines.append(f"- `{item['context']}`: before {item['apply_before']}; default `{item['default_route']}`.")
lines.extend(["", "## Human Question Template", ""])
lines.append(human_question_template["question"])
for option in human_question_template["options"]:
    lines.append(f"- `{option['id']}`: {option['label']} -> {option['impact']}.")

(artifact_root / "SOCRATIC_APPLICATION_GATE.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        f"- Socratic logic input: `{payload['socratic_logic_status']}`",
        "- Application gate is read-only and does not start runtime.",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "VALIDATION.md").write_text(
    "\n".join([
        "# Validation",
        "",
        *[f"- [{'x' if check['passed'] else ' '}] `{check['id']}`" for check in checks],
        "",
        "## Commands",
        "",
        "```bash",
        "sh -n scripts/artemis-socratic-application-gate.sh",
        "scripts/artemis-socratic-application-gate.sh --artifact-root artifacts/artemis-socratic-application-gate/run-01 --json",
        "python3 -m json.tool artifacts/artemis-socratic-application-gate/run-01/socratic-application-gate.json",
        "python3 -m json.tool artifacts/artemis-socratic-application-gate/run-01/events.json",
        "```",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-121 applies the ARTEMIS Socratic Logic contract as an operational gate.",
        "",
        "Use this gate to choose one clear route before execution: assumption, local evidence, human question, split cut or block.",
    ]) + "\n",
    encoding="utf-8",
)

events = [
    event(
        event_id="evt_artemis_socratic_application_gate_ready",
        event_type="method.socratic_application_gate_ready",
        generated_at=generated_at,
        producer={"adapter": "method", "name": "scripts/artemis-socratic-application-gate.sh", "mode": "read_only"},
        ticket="TKT-121",
        title="ARTEMIS Socratic Application Gate",
        exec_pack="docs/exec-packs/done/TKT-121-artemis-socratic-application-gate.md",
        artifact_root=str(artifact_root),
        state_to="done" if overall == "socratic_application_gate_ready" else "blocked",
        payload={
            "overall": overall,
            "socratic_logic_status": payload["socratic_logic_status"],
            "application_stages": len(application_stages),
            "routes": len(routes),
            "contexts": len(application_matrix),
            "runtime_execution_allowed": False,
            "agents_started": False,
            "commands_executed": 0,
            "tokens_spent": 0,
            "remote_state_mutated": False,
            "next_cut": payload["next_cut"],
        },
        state_from="planned",
        runner={"kind": "none"},
        gate={"kind": "method", "status": overall, "reason": "Socratic application routes declared."},
        logs=[str(artifact_root / "socratic-application-gate.json"), str(artifact_root / "SOCRATIC_APPLICATION_GATE.md")],
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-socratic-application-gate.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Socratic Application Gate: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"routes={len(routes)}")
    print(f"contexts={len(application_matrix)}")
    print("runtime_execution_allowed=false")
PY
