---
id: T-1413
name: "Should 832 move to a Docker-style service (ring20 swarm), and what would it
  serve?"
description: >
  Inception: Should 832 move to a Docker-style service (ring20 swarm), and what would
  it serve?

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-11-14T00:58:09Z
last_update: '2026-11-14T09:12:06Z'
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): the two values below are PLACEHOLDERS, not an assessment. The BVP
# estimator ignores any value without `<field>_source: human` and estimates it from this task's own text, so a
# 0.5 nobody chose no longer ranks as "judged middling". They stay filled because AEF's T-2188 schema hook
# refuses an edit to an inception without them (T-1178; T-865 had deleted them before that hook arrived here).
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-11-14T09:12:06Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 3
      D2: 3
      D3: 3
      D4: 3
      F-RECALL: 3
      F2: 3
      F4: 3
      F3: 3
      F1: 3
    rationale: D1=3 (voi:decision-with-alternatives~'either way'); D2=3 
      (voi:decision-with-alternatives~'either way'); D3=3 
      (voi:decision-with-alternatives~'either way'); D4=3 
      (voi:decision-with-alternatives~'either way'); F-RECALL=3 
      (voi:decision-with-alternatives~'either way'); F2=3 
      (voi:decision-with-alternatives~'either way'); F4=3 
      (voi:decision-with-alternatives~'either way'); F3=3 
      (voi:decision-with-alternatives~'either way'); F1=3 
      (voi:decision-with-alternatives~'either way')
    rubric_sha: e4a00f38e801
---

# T-1413: Should 832 move to a Docker-style service (ring20 swarm), and what would it serve?

## Problem Statement

Today 832 ships ONE artifact: `src/aef-workflow-designer.html`, a single file that AEF vendors and serves (AEF is the
main consumer). Around it run hand-started processes on .107: the dev/gallery server (`tools/gallery-serve.py`, with
write APIs for versions and field profiles), Watchtower, and test runs (now partly on ring20's dispatch pool). The
framework's deploy gate assumes every project is a ring20 swarm service and reports three FAILs (no Dockerfile, no
`deploy/docker-compose.swarm.yml`, no `deploy/traefik-routes.yml`; T-752..T-754). The operator (2026-11-14): "Do we want
to start moving it into a docker-type style of service? That's toward an inception with external review, or external
consultation." Why now: the gate keeps failing, and the designer is going public (SPRIND video), so a hosted,
reachable designer may have real users beyond AEF.

## Hypothesis

<!-- REQUIRED before a GO decision (T-866, arc-004). Fill the three blanks below and
     delete this comment. Keep the three phrases — the gate looks for them.

     NOT EVERY INCEPTION HAS ONE, and that is fine. "Research how X works" produces
     understanding, not a delivered outcome, and forcing it into "we will achieve
     <outcome>" would manufacture a fake claim to satisfy a gate — which teaches
     authors to write fiction and is worse than no gate at all.

     If this is that kind of inception, set in the frontmatter:

         inception_kind: research

     and delete this section. The gate then passes. Declare it NOW, while framing the
     work — not later at the decision, when you know whether the hypothesis would have
     been inconvenient. The count of research inceptions is reported, so if the
     exemption quietly becomes the default that is visible rather than silent.

     This is the form the BVP scoring method expects. Every support score in this
     task's value-driver table is an ARGUMENT ABOUT THIS SENTENCE: "support 5 on
     Reliability" means something only once the sentence says what success looks
     like. Without it a score can rank but cannot be wrong, because there is no
     claim for it to be wrong about.

     THE THIRD CLAUSE IS THE ONE THAT BITES. It has to be checkable by someone who
     was not in the room and who reads this in three months. A number, a count, a
     threshold, a named state.

       no  — "...when the system is better"
       no  — "...when the team is more productive"
       yes — "...when 5 consecutive fire-suppression tests pass at every equipped site"
       yes — "...when fw audit reports 0 failures for 3 consecutive nightly runs"
       yes — "...when the importer no longer fabricates a lane for input that has none"

     Writing it is genuinely hard. You are not expected to start from blank: the
     estimator drafts one from this task's own text, and you correct it. Your
     correction is sticky — set `hypothesis_source: human` in the frontmatter and no
     automatic pass will ever overwrite it. -->

We believe that packaging 832's designer and gallery server as a ring20 swarm service behind traefik,
we will achieve a designer that people and agents can open at a stable address without anyone starting a process on .107,
We will know that we are successful when we see the designer reachable at a stable ring20 address for 7 consecutive days
with no hand restart, the deploy gate's three checks PASS, and AEF's vendored copy unchanged in how it is served.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1413 -->

## Open Questions

<!-- T-2190 (T-2186 Slice 4): every IW-N question must be disposed before
     --status work-completed. Disposition gate (agents/task-create/update-task.sh
     check_disposition_gate) refuses on under-disposed inceptions.

     Per-question shape:

       - **IW-1: <question text>**
         confidence: 0-3      (your confidence in your current answer; 0=guess, 3=verified)
         disposition: answered | deferred | dissolved
         rationale: <one-line evidence — file:line, decision id, dialogue ref>

     Never bare yes/no — the gate refuses bare checkboxes. See 050-Inceptions.md
     §Disposition Gate. Bypass: --skip-disposition-gate "rationale" (direct) or
     FW_SKIP_DISPOSITION_GATE=1 (env-var, T-1890 producer/consumer parity).
-->
- **IW-1: Who would use a hosted 832 designer that does not already get it through AEF, and how often?**
  confidence: 2
  disposition: answered
  rationale: none known — AEF (msg 1d7d8b4b) and ring20 (msg b86d15f0) know of no user outside AEF/Watchtower; the
    only open audience is the public (SPRIND video), which only the operator can name. docs/reports/T-1413-*.md
- **IW-2: What exactly would the container serve: only the static designer, or the gallery server with its write
  APIs (versions, field profiles, suggestions), and what auth would writes need?**
  confidence: 3
  disposition: answered
  rationale: static designer = safe but needs no swarm (ring20: a Surfer static app is cheaper); gallery-serve.py writes
    (save/delete/field-profile/suggestions) have no auth and bind 0.0.0.0 (line 399), so hosting it needs auth + backups
- **IW-3: What does ring20 expect of a swarm service (image registry, ports, traefik routes, secrets, backups), and is
  there capacity and an owner for it?**
  confidence: 3
  disposition: answered
  rationale: ring20 msg b86d15f0 — registry image via OneDev CI, traefik route on both proxy nodes, Infisical secrets,
    app-level or Keycloak auth, PBS + own volume export; capacity yes; ring20 runs the platform, 832 the app
- **IW-4: Does AEF want anything different from 832 if 832 runs as a service (e.g. fetch the designer from it instead
  of vendoring), or must the vendored single file stay the contract?**
  confidence: 3
  disposition: answered
  rationale: AEF msg 1d7d8b4b — "The vendored single HTML file stays our contract"; a hosted 832 changes nothing AEF
    depends on
- **IW-5: If NO-GO, is the right fix to declare the deploy section not applicable to 832 (and can a consumer project
  say so), instead of scaffolding files to silence it?**
  confidence: 3
  disposition: dissolved
  rationale: nothing to declare — the deployment section is opt-in (audit.sh:9147-9151, "--section deployment" only;
    confirmed by AEF msg 1d7d8b4b); 832 never meets it unless someone asks for it

## Exploration Plan

Research artifact: `docs/reports/T-1413-docker-service-inception.md`, updated as answers arrive. Time-box: about one
session of our own reading, plus however long the consultations take to come back.
1. **Our side (1 h):** what 832 runs today and why (gallery-serve routes and writes, Watchtower, pool runner), and what
   the deploy gate checks and whether a consumer can scope it out (IW-2, IW-5).
2. **External consultation, ring20 (IW-3):** ask the ring20 management agent what a swarm service needs and costs, and
   whether they would host and back it.
3. **External consultation, AEF (IW-4, IW-1):** ask whether a hosted 832 changes anything for them, and who else would use it.
4. **External review of the write-up:** the finished artifact goes to an independent reviewer
   (`fw reviewer judge`) before the operator decides, so the recommendation is not only the author's view.
No Dockerfile, compose file or route is written during the inception (build artifacts wait for a GO).

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->
- No LAN addresses in tracked files (T-1239 gate); addresses are read at run time.
- Greenfield client data (`build/peer-data/`) must never leave .107; a hosted service must not serve or bundle it.
- The designer must keep working as one file opened locally and as AEF's vendored copy (the product contract).
- The gallery server's write APIs must not be exposed without auth.

## Scope Fence

**IN:** whether 832 should run as a ring20 swarm service, what it would serve, who would use it, what ring20 and AEF
need, and what to do about the deploy gate either way.
**OUT:** writing the Dockerfile, compose or traefik files; changing how AEF vendors the designer; moving the test
tiers (the dispatch pool already covers those).

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [ ] Problem statement validated
<!-- @auto-tick-on-decide -->
- [ ] Assumptions tested
<!-- @auto-tick-on-decide -->
- [ ] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [ ] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-1413` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- At least one named user or agent besides AEF would use a hosted designer (IW-1), and
- ring20 can host it with a named owner and a known cost (IW-3), and
- the write paths can be served safely, or the service is read-only (IW-2).

**NO-GO if:**
- Nobody but AEF would use it (AEF already serves the designer), or ring20 cannot host it; then the deploy section is
  declared not applicable to 832 (IW-5) and T-752..T-754 close on that ruling.

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# For inception tasks, verification is often not needed (decisions, not code).
#
# Toolchain hint (L-291): if a GO decision will mean editing *.vbproj/*.csproj/*.xaml,
# *.go, Cargo.toml, tsconfig.json, or pom.xml in the build task, plan to add the
# matching build command (dotnet build / go build / cargo check / tsc --noEmit /
# mvn compile) to that build task's ## Verification — P-011 only runs what you write.

## Recommendation

**Recommendation:** NO-GO

**Rationale:**

No named user needs a hosted 832 (AEF and ring20 both know of none); AEF's contract stays the vendored single file and
a hosted 832 changes nothing for it; ring20's closest precedent (workshop-designer, one HTML designer) was moved OFF
swarm in May 2026 to a static app; the only part that would justify a service, the gallery server, would first need
auth and backups nobody has asked for. The deploy gate is opt-in, so no change in 832 is needed; T-752..T-754 close on
this ruling. If the operator wants a public, always-on designer to show, the cheap path is a read-only static app
(as workshop-designer), as its own small task, not this decision.

**Evidence:**
- AEF, msg 1d7d8b4b (2026-11-14): single vendored file stays the contract; no users outside AEF/Watchtower; deployment
  section opt-in, no declaration needed.
- ring20, msg b86d15f0 (2026-11-14): workshop-designer moved off swarm (their T-849/T-850); static designer not worth a
  swarm service; only a writing server justifies one, with auth + backup; no known fleet users.
- `.agentic-framework/agents/audit/audit.sh:9147-9200`: deployment section runs only with `--section deployment`.
- `tools/gallery-serve.py:399, 1104-1140`: binds 0.0.0.0, writes without auth.
- Full write-up: `docs/reports/T-1413-docker-service-inception.md`.

<!-- Add evidence bullets as exploration progresses (file paths,
     commit hashes, test results). The filing-time recommendation
     can be revised before fw inception decide. -->

## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Decision

<!-- Filled at completion via: fw inception decide T-1413 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-11-14T09:12:05Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
