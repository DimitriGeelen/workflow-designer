# T-1413: Should 832 move to a Docker-style service (ring20 swarm), and what would it serve?

Inception research artifact (C-001). Updated as answers arrive. Status: exploring; starting recommendation DEFER.

## Origin

The operator, 2026-11-14, on the deploy-gate findings T-752..T-754 (no Dockerfile, no swarm compose, no traefik routes):
"Do we want to start moving it into a docker-type style of service? That's toward an inception with external review,
or external consultation."

## What 832 runs today (our side, read 2026-11-14)

- **The product** is one file, `src/aef-workflow-designer.html`. AEF vendors it and serves it (AEF is the main consumer;
  its pin is tracked by `tools/_t1187-aef-pin-lag.sh`). Other projects embed it too: 1409-sprind's Watchtower serves it
  at `/designer` with its own workflows loaded (seen 2026-11-14 in the SPRIND video work, T-1412).
- **The dev/gallery server** `tools/gallery-serve.py` is started by hand when needed. It is not running now.
  - It binds `0.0.0.0` by default (line 399; `--bind` overrides).
  - Reads: `/api/health`, `list`, `versions`, `version`, `thumb`, `instances`, `field-suggestions`, `field-catalog`,
    `lens-definition`, `field-profile`.
  - Writes, with NO authentication: `POST /api/save`, `/api/delete`, `/api/validate`, `/api/field-suggestions`, and
    `PUT /api/field-profile`.
  - So it cannot be hosted as it is: anyone who can reach it can save or delete maps.
- **Watchtower** (the framework's dashboard) runs on .107 for this project.
- **Test tiers** already run on ring20's dispatch pool (T-1397 GO, T-1406..T-1409); they are out of scope here.

## The deploy gate (IW-5)

`.agentic-framework/agents/audit/audit.sh` lines 9147-9200: the deployment section is **opt-in**. It runs only with
`--section deployment` (T-275, T-4410); the default audit, the cron audits and the pre-push audit do not run it. It
checks: an active task, a clean git tree for `*.py *.sh *.yml *.yaml Dockerfile`, a task reference on HEAD, and the three
files `Dockerfile`, `deploy/docker-compose.swarm.yml`, `deploy/traefik-routes.yml`.

So the three FAILs came from one explicit run of that section (the September residue audit), not from a recurring
check. Nothing in 832's normal flow is red because of them. This weakens "the gate keeps failing" as a reason to act;
the real question is whether a hosted service would be useful.

## Open questions and evidence

| Q | Question | Status |
|---|---|---|
| IW-1 | Who besides AEF would use a hosted 832 designer, and how often? | asked AEF and ring20 (below) |
| IW-2 | What would the container serve: the static designer only, or the gallery server with writes (then with what auth)? | our side: the writes have no auth today; static-only is safe as is |
| IW-3 | What does ring20 need for a swarm service (registry, ports, traefik, secrets, backups); capacity and owner? | asked ring20 |
| IW-4 | Does AEF want anything different if 832 runs as a service, or does the vendored single file stay the contract? | asked AEF |
| IW-5 | If NO-GO: can the deployment section be declared not applicable to 832? | partly answered: it is opt-in, so 832 never runs it unless asked |

## Consultations

- ring20 (`proxmox-ring20-management`): IW-3, IW-1. Sent 2026-11-14, conversation `832-docker-service`, msg 172047af.
- AEF (`999-Agentic-Engineering-Framework`): IW-4, IW-1, IW-5 (a supported "not applicable" for consumers). Sent
  2026-11-14, conversation `832-docker-service`, msg 33498293.
- Independent review of this write-up before the operator decides: planned (`fw reviewer judge`).

## Dialogue log

- 2026-11-14 (operator): asked whether to move 832 to a Docker-type service; wants external review or consultation
  first. Outcome: this inception, DEFER until evidence.
