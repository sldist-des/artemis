#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

artifact_root="artifacts/artemis-socratic-logic/run-01"
format="text"

usage() {
  echo "usage: scripts/artemis-socratic-logic.sh [--artifact-root path] [--json]" >&2
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

required_files = [
    Path("AGENTS.md"),
    Path("ARTEMIS_WORKFLOW.md"),
    Path("docs/principles/ARTEMIS_SOCRATIC_LOGIC.md"),
    Path("docs/exec-packs/done/TKT-120-artemis-socratic-logic.md"),
]
missing_files = [str(path) for path in required_files if not path.is_file()]

clarity_questions = [
    {
        "id": "objective",
        "question": "Qual resultado unico esta sendo buscado agora?",
        "blocks_if_empty": True,
        "required_answer_shape": "uma frase com artefato ou estado final verificavel",
    },
    {
        "id": "terms",
        "question": "Quais termos podem ter mais de um sentido nesta tarefa?",
        "blocks_if_undefined_terms": True,
        "required_answer_shape": "termo, significado usado e significado rejeitado",
    },
    {
        "id": "premises",
        "question": "Quais premissas estamos usando como verdade e de onde elas vieram?",
        "blocks_if_unverifiable": True,
        "required_answer_shape": "premissa, fonte local ou decisao humana",
    },
    {
        "id": "distinctions",
        "question": "O que precisa ficar distinto para nao misturar conceitos?",
        "blocks_if_collapsed": True,
        "required_answer_shape": "par conceitual e criterio de separacao",
    },
    {
        "id": "authority",
        "question": "Quem ou qual artefato tem autoridade para decidir isto?",
        "blocks_if_missing_authority": True,
        "required_answer_shape": "git, Exec Pack, Validation Gate, Human Gate ou documento canonico",
    },
    {
        "id": "evidence",
        "question": "Que evidencia provaria que a conclusao e correta?",
        "blocks_if_empty": True,
        "required_answer_shape": "comando, arquivo, gate ou artifact verificavel",
    },
    {
        "id": "counterexample",
        "question": "Que fato faria a conclusao cair?",
        "blocks_if_unanswered_for_high_risk": True,
        "required_answer_shape": "contraexemplo, risco ou condicao de reversao",
    },
    {
        "id": "decision",
        "question": "A proxima acao e observacao, inferencia, decisao ou execucao?",
        "blocks_if_category_mixed": True,
        "required_answer_shape": "uma categoria e o motivo",
    },
    {
        "id": "handoff",
        "question": "Como a resposta sera entregue sem deixar ambiguidade para humano ou agente?",
        "blocks_if_empty": True,
        "required_answer_shape": "estado, evidencia, limites e proximo passo",
    },
]

argument_contract = {
    "minimum_fields": [
        "objective",
        "defined_terms",
        "premises",
        "distinctions",
        "evidence",
        "inference",
        "conclusion",
        "confidence",
        "counterexample",
        "next_action",
    ],
    "conclusion_ladder": [
        {"level": "observation", "meaning": "fato visto em arquivo, comando ou artifact"},
        {"level": "inference", "meaning": "interpretacao derivada de observacoes"},
        {"level": "decision", "meaning": "escolha com autoridade explicita"},
        {"level": "commitment", "meaning": "promessa operacional registrada em Exec Pack ou gate"},
        {"level": "execution", "meaning": "mudanca aplicada e validada"},
    ],
    "forbidden_collapses": [
        "tratar hipotese como fato",
        "tratar preferencia como requisito",
        "tratar fixture como autorizacao real",
        "tratar template pendente como decisao",
        "tratar validacao tecnica como aceite humano",
        "tratar painel observacional como fonte canonica",
    ],
}

question_policy = {
    "ask_when": [
        "a resposta muda escopo, risco, custo, autoridade ou arquivo de escrita",
        "um termo central tem dois sentidos plausiveis",
        "a conclusao depende de informacao que nao existe no repositorio",
        "a acao pode tocar secrets, auth, remoto, producao, dinheiro ou permissao ampla",
    ],
    "do_not_ask_when": [
        "a proxima acao e local, reversivel e coberta por contrato existente",
        "a lacuna pode virar suposicao declarada sem afetar risco",
        "a validacao local pode resolver a duvida com comando seguro",
    ],
    "question_shape": {
        "one_question_default": True,
        "must_include": ["termo_ambiguo", "opcoes_distintas", "impacto_da_escolha"],
        "max_options": 3,
        "avoid": ["perguntas vagas", "multiplas perguntas numa frase", "opcoes sobrepostas"],
    },
}

ambiguity_gates = [
    {
        "gate_id": "undefined_term",
        "detects": "termo central sem definicao operacional",
        "action": "definir termo ou perguntar ao humano antes de executar",
    },
    {
        "gate_id": "mixed_authority",
        "detects": "duas fontes de autoridade competindo",
        "action": "priorizar hierarquia ARTEMIS e registrar a decisao",
    },
    {
        "gate_id": "multi_outcome",
        "detects": "mais de um resultado final no mesmo corte",
        "action": "dividir em cortes ou escolher um objetivo unico",
    },
    {
        "gate_id": "conclusion_without_evidence",
        "detects": "conclusao sem comando, artifact, fonte ou decisao",
        "action": "bloquear handoff ate existir evidencia",
    },
    {
        "gate_id": "category_error",
        "detects": "observacao, inferencia, decisao e execucao misturadas",
        "action": "reescrever no conclusion_ladder antes de prosseguir",
    },
]

agent_rules = [
    {
        "agent": "codex",
        "rule": "Use a logica socratica antes de editar codigo quando escopo, termo, autoridade ou validacao puderem mudar o resultado.",
    },
    {
        "agent": "claude_code",
        "rule": "Use perguntas curtas para mapear diretorio, linguagem, limites e handoff antes de tarefas medias.",
    },
    {
        "agent": "antigravity_cli",
        "rule": "Exija escopo, permissao herdada, budget e Human Gate antes de qualquer lane assincrona ou ampla.",
    },
    {
        "agent": "human_collaborator",
        "rule": "Receba perguntas com opcoes distintas e impacto claro, sem jargao tecnico quando uma decisao humana for necessaria.",
    },
]

checks = [
    {
        "id": "clarity_questions_declared",
        "passed": len(clarity_questions) >= 9,
        "evidence": f"{len(clarity_questions)} questions",
    },
    {
        "id": "argument_contract_declared",
        "passed": len(argument_contract["minimum_fields"]) >= 10,
        "evidence": "argument minimum fields",
    },
    {
        "id": "ambiguity_gates_declared",
        "passed": len(ambiguity_gates) >= 5,
        "evidence": f"{len(ambiguity_gates)} gates",
    },
    {
        "id": "question_policy_declared",
        "passed": question_policy["question_shape"]["one_question_default"] is True,
        "evidence": "one-question default",
    },
    {
        "id": "no_runtime_side_effects",
        "passed": True,
        "evidence": "contract-only artifact",
    },
]

overall = "artemis_socratic_logic_ready" if not missing_files and all(check["passed"] for check in checks) else "blocked"
payload = {
    "schema_version": 1,
    "generated_at": generated_at,
    "source": "scripts/artemis-socratic-logic.sh",
    "mode": "contract_only_no_runtime",
    "overall": overall,
    "ticket": "TKT-120",
    "artifact_root": str(artifact_root),
    "socratic_logic_ready": overall == "artemis_socratic_logic_ready",
    "clarity_questions": clarity_questions,
    "argument_contract": argument_contract,
    "question_policy": question_policy,
    "ambiguity_gates": ambiguity_gates,
    "agent_rules": agent_rules,
    "runtime_execution_allowed": False,
    "agents_started": False,
    "commands_executed": 0,
    "tokens_spent": 0,
    "remote_state_mutated": False,
    "missing_files": missing_files,
    "checks": checks,
    "next_cut": "TKT-121 - Socratic Logic Application Gate",
}

(artifact_root / "socratic-logic.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

lines = [
    "# ARTEMIS Socratic Logic",
    "",
    f"- Overall: `{overall}`",
    f"- Questions: `{len(clarity_questions)}`",
    f"- Ambiguity gates: `{len(ambiguity_gates)}`",
    "- Runtime execution allowed: `false`",
    "- Agents started: `false`",
    "- Tokens spent: `0`",
    f"- Next cut: `{payload['next_cut']}`",
    "",
    "## Clarity Questions",
    "",
]
for item in clarity_questions:
    lines.append(f"- `{item['id']}`: {item['question']} Evidence: {item['required_answer_shape']}.")
lines.extend(["", "## Argument Contract", ""])
for field in argument_contract["minimum_fields"]:
    lines.append(f"- `{field}`")
lines.extend(["", "## Ambiguity Gates", ""])
for gate in ambiguity_gates:
    lines.append(f"- `{gate['gate_id']}`: {gate['detects']} -> {gate['action']}.")
lines.extend(["", "## Question Policy", ""])
for item in question_policy["ask_when"]:
    lines.append(f"- Ask when: {item}.")
for item in question_policy["do_not_ask_when"]:
    lines.append(f"- Do not ask when: {item}.")

(artifact_root / "SOCRATIC_LOGIC.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

(artifact_root / "STATUS.md").write_text(
    "\n".join([
        "# Status",
        "",
        f"- Overall: `{overall}`",
        "- Socratic logic is contract-only and does not start runtime.",
        "- Questions, argument contract and ambiguity gates are declared.",
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
        "sh -n scripts/artemis-socratic-logic.sh",
        "scripts/artemis-socratic-logic.sh --artifact-root artifacts/artemis-socratic-logic/run-01 --json",
        "python3 -m json.tool artifacts/artemis-socratic-logic/run-01/socratic-logic.json",
        "python3 -m json.tool artifacts/artemis-socratic-logic/run-01/events.json",
        "```",
    ]) + "\n",
    encoding="utf-8",
)

(artifact_root / "HANDOFF.md").write_text(
    "\n".join([
        "# Handoff",
        "",
        "TKT-120 records the ARTEMIS Socratic Logic contract.",
        "",
        "Use this gate before execution when a term, premise, distinction, authority, evidence or conclusion could be ambiguous.",
    ]) + "\n",
    encoding="utf-8",
)

events = [
    event(
        event_id="evt_artemis_socratic_logic_ready",
        event_type="method.socratic_logic_ready",
        generated_at=generated_at,
        producer={"adapter": "method", "name": "scripts/artemis-socratic-logic.sh", "mode": "read_only"},
        ticket="TKT-120",
        title="ARTEMIS Socratic Logic",
        exec_pack="docs/exec-packs/done/TKT-120-artemis-socratic-logic.md",
        artifact_root=str(artifact_root),
        state_to="done" if overall == "artemis_socratic_logic_ready" else "blocked",
        payload={
            "overall": overall,
            "clarity_questions": len(clarity_questions),
            "ambiguity_gates": len(ambiguity_gates),
            "runtime_execution_allowed": False,
            "agents_started": False,
            "commands_executed": 0,
            "tokens_spent": 0,
            "remote_state_mutated": False,
            "next_cut": payload["next_cut"],
        },
        state_from="planned",
        runner={"kind": "none"},
        gate={"kind": "method", "status": overall, "reason": "Socratic logic contract declared."},
        logs=[str(artifact_root / "socratic-logic.json"), str(artifact_root / "SOCRATIC_LOGIC.md")],
    )
]
write_event_log(artifact_root / "events.json", event_log(source="scripts/artemis-socratic-logic.sh", generated_at=generated_at, events=events))

if output_format == "json":
    print(json.dumps(payload, ensure_ascii=False, indent=2))
else:
    print(f"ARTEMIS Socratic Logic: {overall}")
    print(f"artifact_root={artifact_root}")
    print(f"clarity_questions={len(clarity_questions)}")
    print(f"ambiguity_gates={len(ambiguity_gates)}")
    print("runtime_execution_allowed=false")
PY
