# STATUS

## Resultado

TKT-018 implementou a timeline read-only de eventos no ARTEMIS Control Plane.

## Mudancas

- `control-plane/index.html` carrega o event log local quando servido por HTTP.
- O Control Plane renderiza evento, estado, produtor, ticket e link de evidencia.
- A timeline tem fallback local para abertura direta sem servidor.
- `scripts/artemis-event-log.sh` agora descobre o Exec Pack ativo em vez de fixar um ticket especifico.

## Invariantes preservados

- Exec Packs continuam contrato canonico.
- Artifacts continuam evidencia canonica.
- Git continua memoria duravel.
- Timeline e observacional e nao persiste estado.
