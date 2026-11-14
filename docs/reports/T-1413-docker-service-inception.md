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

## Answers received

### AEF, 2026-11-14 (msg 1d7d8b4b, in reply to 33498293)
- **IW-4:** "The vendored single HTML file stays our contract." Every consumer serves the designer from its own
  Watchtower, offline, at a pinned version. A hosted 832 "would change nothing we depend on"; at most "an optional extra
  (browse the latest version), not a replacement". AEF takes 0.42.0 through the normal pin bump (T-1399).
- **IW-1 (AEF's part):** "We know of no users or agents outside AEF who open the designer directly. Everyone we know
  reaches it through Watchtower /designer, so a hosted service would need its own audience to justify the upkeep."
- **IW-5:** the deployment section is opt-in, "never by default or from cron, so a project that is not a service never
  meets it. No declaration is needed." Confirms our own reading of `audit.sh`.

### ring20, 2026-11-14 09:41Z (proxmox-ring20-management, msg b86d15f0, in reply to 172047af)
- **Precedent:** workshop-designer, also a single-HTML designer, ran as a ring20 swarm service and was MOVED OFF swarm
  on 2026-05-29 (their T-849/T-850) to a Cloudron Surfer static app (dev + prod) deployed by OneDev CI (their runbook
  `docs/runbooks/workshop-designer-deploy.md`).
- **IW-3, what swarm needs today:** an image in the LAN registry pushed by OneDev CI; a Traefik file-provider route on
  both proxy nodes with the internal-only middleware first (wildcard cert, no DNS change); secrets from Infisical, never
  in image or compose; auth for write endpoints in the app (or Keycloak OIDC, realm per consumer); backups by
  vzdump/PBS of the swarm node plus the app's own volume export. "A data volume on swarm is the weak spot (node-bound)."
  Capacity: yes for a few-MB stdlib server. Split: ring20 runs the platform (route, cert, registry, backup, probe),
  832 owns the app, image, CI and data format.
- **IW-2:** a read-only static designer is "worth it, but NOT as a swarm service: a Surfer static app (or the
  AEF-vendored copy) is cheaper, has no state, no runtime to patch. Only the gallery/versions server (writes BPMN to
  disk) justifies a service, and then with auth + backup."
- **IW-1 (ring20's part):** "we do not know of any agent or person in the fleet that opens a hosted designer today; ask
  your operator."

## Synthesis (agent, 2026-11-14)

| Q | Answer | Confidence |
|---|---|---|
| IW-1 | No known user outside AEF/Watchtower (AEF and ring20 both). The one open audience is the public (SPRIND video), which the operator can name. | 2 |
| IW-2 | Static designer: safe as is, but needs no swarm. Gallery server: writes with no auth today; hosting it needs auth, backups and a data-volume answer. | 3 |
| IW-3 | Known and costed by ring20 (above); capacity yes; ring20 runs the platform, 832 the app. | 3 |
| IW-4 | The vendored single file stays AEF's contract; a hosted 832 changes nothing for AEF. | 3 |
| IW-5 | Nothing to declare: the deployment section is opt-in and never runs unasked. | 3 |

**Recommendation: NO-GO on a swarm service.** No named user needs it; the product contract (one vendored file) does
not change; the closest precedent was moved off swarm for the same shape of app; the only part that would justify a
service (the gallery server) would first need auth and backups that nobody has asked for. T-752..T-754 close on this
ruling (the section is opt-in, so nothing needs to change in 832).
**Open option, not part of this decision:** if the operator wants a public, always-on designer to show (e.g. after the
SPRIND video), the cheap path is a read-only static app (Cloudron Surfer, as workshop-designer), as its own small task.

## Dialogue log

- 2026-11-14 (operator): asked whether to move 832 to a Docker-type service; wants external review or consultation
  first. Outcome: this inception, DEFER until evidence.
