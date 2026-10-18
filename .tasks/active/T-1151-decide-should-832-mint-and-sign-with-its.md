---
id: T-1151
name: "Decide: should 832 mint and sign with its own termlink identity? Shared root
  key d1993c2c3ec44c94 exposes other projects' DM traffic and cannot attribute our
  posts"
description: >
  Promoted from OBS-251 by T-1149 (observation triage, 2026-10-13). Still true and
  no task decides it. T-916 deliberately left it pending as the operator's call, and
  T-531 says "OBS-251 already carries it". The question of whether 832 mints its own
  termlink key (changing fleet identity and TOFU state) has no carrier task. Original
  observation text is in .context/inbox.yaml under OBS-251.

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: agent
horizon: now
tags: [observations]
components: []
related_tasks: []
created: 2026-10-13T16:20:48Z
last_update: 2026-10-18T12:35:34Z
date_finished:
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-18T12:35:36Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 2
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 2
      F4: 2
      F3: 2
      F1: 2
    rationale: D1=2 (voi:open-question~'assumption'); D2=2 
      (voi:open-question~'assumption'); D3=2 (voi:open-question~'assumption'); 
      D4=2 (voi:open-question~'assumption'); F-RECALL=2 
      (voi:open-question~'assumption'); F2=2 (voi:open-question~'assumption'); 
      F4=2 (voi:open-question~'assumption'); F3=2 
      (voi:open-question~'assumption'); F1=2 (voi:open-question~'assumption')
    rubric_sha: e4a00f38e801
---

# T-1151: Decide: should 832 mint and sign with its own termlink identity? Shared root key d1993c2c3ec44c94 exposes other projects' DM traffic and cannot attribute our posts

OBS-251 (2026-08-15): 832's TermLink posts are signed with fingerprint d1993c2c3ec44c94, which other projects on
this host also hold. Two consequences were measured then: (1) a post "from 832" proves nothing cryptographically,
since AEF's reply carried the same fingerprint, so attribution rests on a metadata convention; (2) another project's
DM topic (ring20-manager, AP-fleet operations including a credential-custody thread) appears in 832's inbox, so
sessions here can read it, and vice versa. Remedy proposed then: 832 mints and signs with its own key. That changes
fleet identity and TOFU state, so it is the operator's decision. Research artifact:
`docs/reports/T-1151-termlink-identity.md`.

## Hypothesis

<!-- Agent wording (2026-10-18), replacing the estimator draft; the operator may correct it. -->

We believe that giving 832 its own TermLink signing identity,
we will achieve posts that are attributable to 832 alone and an inbox that no longer receives other projects' DMs.
We will know that we are successful when a 832 post carries a fingerprint no other project holds, and 832's inbox
lists no DM rail addressed to the shared fingerprint d1993c2c3ec44c94.

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1151 -->

- A-1: the identity is still shared today (OBS-251 is two months old). To be measured read-only.
- A-2: minting a per-project key is supported by TermLink without forking it (TERMLINK_IDENTITY_FILE or similar).
- A-3: what a switch breaks (peer trust pins, hub auth, sidecar addressing, existing DM rails) can be listed before acting.

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

- **IW-1: Is 832's TermLink identity still shared with other projects today, and which ones?**
  confidence: 3
  disposition: answered
  rationale: yes. `termlink whoami`: d1993c2c3ec44c94 "shared with 126 other sessions on this hub"; read-only resolver gives the host file /root/.termlink/identity.key; `fw rail status` state: host. Greenfield (90d45538) and CashWeb already use their own keys (artifact F1)
- **IW-2: Is the exposure still live — do other projects' DM rails still reach 832's inbox?**
  confidence: 2
  disposition: answered
  rationale: yes: 28 DM rails on the shared fingerprint; read cursors are host-wide (ring20 DM 12 unread at 00:38, 0 now, unread by this session). An own key does NOT give confidentiality: DMs are signed not encrypted and found by client-side filtering of all hub topics; not confirmed by reading anyone's DM, hence 2 (artifact F2)
- **IW-3: How would 832 get its own key, and does TermLink/AEF already support or plan per-project identity?**
  confidence: 3
  disposition: answered
  rationale: env precedence TERMLINK_IDENTITY_FILE > TERMLINK_AGENT_ID > TERMLINK_IDENTITY_DIR > host; framework has `fw config set RAIL_IDENTITY_FILE` (lib/rail-identity.sh, AEF T-2904), but only `fw rail` applies it — the sidecar (circuit.py, dm.py) does not, so full coverage needs TERMLINK_IDENTITY_FILE at every 832 entry point (artifact F3)
- **IW-4: What breaks if 832 switches key — peer trust (TOFU), hub auth, sidecar circuit addressing, existing rails?**
  confidence: 2
  disposition: answered
  rationale: expected none for hub auth (hub.secret) and TOFU (hub certs) and sidecar addressing (project-addressed); DM rails move to the new fingerprint; read cursors stay shared unless TERMLINK_IDENTITY_DIR, unmeasured; peers need the new fingerprint announced. Docs-read, not exercised (exercising = registering a new identity, the act being decided) (artifact F4)

## Exploration Plan

Research only, read-only, one session. Measure the current identity and its sharing without creating, rotating or
pointing at any key; count DM rails by name without opening other projects' messages; read TermLink's identity and
TOFU model and AEF's sidecar addressing; list what a switch would touch. No experiment that could mint a key.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN: whether the identity is shared, whether the exposure is live, how a per-project key would work, what it would
break. OUT: creating, rotating or pointing at any key; changing TOFU state or hub config; reading other projects'
message content; anything outside this repo except read-only queries to TermLink.

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
  **Why you:** act-in-the-world — minting and signing with a new TermLink identity changes credentials on a hub other projects share (and what they can read of each other's DM traffic); and `fw inception decide` is the operator's
  **Steps:**
  1. Run: `fw task review T-1151` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- The identity is still shared and the exposure is live: **met** (126 sessions, 28 DM rails, shared cursors; F1, F2)
- A supported, project-local mechanism exists, needing no TermLink fork and no host config change: **met**
  (env precedence, `RAIL_IDENTITY_FILE`; F3)
- What a switch touches can be listed and checked: **met with a stated gap** (hub auth and the cursor dir are
  docs-read, so the build starts with an operator-approved spike; F4)

**NO-GO if:**
- A switch breaks hub authentication or AEF mail delivery: not expected, verified by the spike before rollout
- The benefit is only cosmetic: no, attribution becomes provable and other projects' DMs stop landing here
  (confidentiality is NOT delivered; that is upstream, option 4)

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

**Recommendation:** GO

**Rationale:** 832 still signs with the host key that 126 other sessions hold (`termlink whoami`), so nothing it
posts is attributable; 28 DM rails addressed to that key land in its directory, and read state is shared host-wide
(a DM went from 12 unread to 0 without this session reading it). TermLink and the framework already support a
project key (env precedence; `RAIL_IDENTITY_FILE`), but the sidecar ignores the framework setting, so the build
must set `TERMLINK_IDENTITY_FILE` at every 832 entry point. Order: an operator-approved spike (hub auth, AEF
delivery, what TERMLINK_IDENTITY_DIR moves), then the key minted by a runme job (gitignored, mode 600), then rollout
checked by `fw rail status` = project, then the new fingerprint announced to AEF, plus a report upstream asking for
DM access control, because an own key gives attribution, not privacy. Detail:
`docs/reports/T-1151-termlink-identity.md`.

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

<!-- Filled at completion via: fw inception decide T-1151 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-18T12:35:34Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)
