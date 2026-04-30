#!/usr/bin/env sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

output=""

if [ "${1:-}" = "--output" ]; then
  output="${2:-}"
  if [ -z "$output" ]; then
    echo "usage: scripts/artemis-tasks.sh [--output path]" >&2
    exit 2
  fi
elif [ "$#" -gt 0 ]; then
  echo "usage: scripts/artemis-tasks.sh [--output path]" >&2
  exit 2
fi

generate_json() {
  generated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  printf '{\n'
  printf '  "schema_version": 1,\n'
  printf '  "generated_at": "%s",\n' "$generated_at"
  printf '  "source": "scripts/artemis-tasks.sh",\n'
  printf '  "tasks": [\n'

  files=$(find docs/exec-packs/active docs/exec-packs/done \
    -maxdepth 1 \
    -type f \
    -name 'TKT-*.md' \
    2>/dev/null \
    | sort)

  if [ -n "$files" ]; then
    # Exec Pack paths are repository-controlled and do not contain spaces.
    awk '
function esc(value) {
  gsub(/\\/, "\\\\", value)
  gsub(/"/, "\\\"", value)
  gsub(/\t/, "\\t", value)
  gsub(/\r/, "", value)
  return value
}

function risk_from_level(value) {
  if (value ~ /Nivel 0/) return "low"
  if (value ~ /Nivel 1/) return "medium"
  if (value ~ /Nivel 2/) return "medium"
  if (value ~ /Nivel 3/) return "high"
  if (value ~ /Nivel 4/) return "high"
  return "medium"
}

function emit() {
  if (path == "") return

  summary = result
  if (summary == "") summary = objective
  if (summary == "") summary = title
  if (evidence == "") evidence = path
  if (owner == "") owner = "Codex"

  if (count > 0) printf ",\n"
  printf "    {\n"
  printf "      \"id\": \"%s\",\n", esc(tolower(ticket))
  printf "      \"ticket\": \"%s\",\n", esc(ticket)
  printf "      \"title\": \"%s\",\n", esc(title)
  printf "      \"state\": \"%s\",\n", esc(state)
  printf "      \"owner\": \"%s\",\n", esc(owner)
  printf "      \"risk\": \"%s\",\n", esc(risk)
  printf "      \"summary\": \"%s\",\n", esc(summary)
  printf "      \"exec_pack\": \"%s\",\n", esc(path)
  printf "      \"evidence\": \"%s\",\n", esc(evidence)
  printf "      \"tags\": [\"exec-pack\", \"%s\"]\n", esc(bucket)
  printf "    }"
  count++
}

FNR == 1 {
  if (NR > 1) emit()

  path = FILENAME
  bucket = path ~ /\/done\// ? "done" : "active"
  state = bucket == "done" ? "done" : "ready"
  ticket = ""
  title = ""
  owner = "Codex"
  risk = "medium"
  objective = ""
  result = ""
  evidence = ""
  section = ""
}

/^# / {
  heading = $0
  sub(/^# +/, "", heading)
  ticket = heading
  sub(/[[:space:]]-.*/, "", ticket)
  title = heading
  sub(/^TKT-[0-9]+[[:space:]]*-[[:space:]]*/, "", title)
}

/^## / {
  section = $0
  sub(/^## +/, "", section)
  next
}

section == "Nivel ARTEMIS da execucao" && /Nivel / {
  risk = risk_from_level($0)
}

section == "Agentes envolvidos" && /^- / && owner == "Codex" {
  owner = $0
  sub(/^- /, "", owner)
  sub(/:.*/, "", owner)
}

section == "Objetivo" && objective == "" && $0 !~ /^$/ {
  objective = $0
}

section == "Resultado esperado" && result == "" && $0 !~ /^$/ {
  result = $0
}

section == "Evidencias obrigatorias" && evidence == "" {
  if (match($0, /`artifacts\/[^`]+`/)) {
    evidence = substr($0, RSTART + 1, RLENGTH - 2)
  }
}

END {
  emit()
  printf "\n"
}
' $files
  fi

  printf '  ]\n'
  printf '}\n'
}

if [ -n "$output" ]; then
  tmp="${output}.tmp"
  mkdir -p "$(dirname -- "$output")"
  generate_json >"$tmp"
  mv "$tmp" "$output"
else
  generate_json
fi
