---
id: T-980
name: "RCA: why the peer-consult sidecar never works for 832 (no listener, wrong identity,
  unread inbox) while it works for other agents"
description: >
  Inception: RCA: why the peer-consult sidecar never works for 832 (no listener, wrong
  identity, unread inbox) while it works for other agents

status: work-completed
workflow_type: inception
target_blast_radius: 3
voi_score: 0.5
current_node: frw_11_task
owner: human
horizon: null
tags: []
components: []
related_tasks: []
created: 2026-10-01T19:02:56Z
last_update: 2026-10-01T19:24:17Z
date_finished: 2026-10-01T19:24:17Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
#
# T-865 (operator-directed 2026-09-26): BOTH fields below are now ESTIMATED
# automatically from this task's own text. Do not pre-fill them.
#
# They used to ship with `target_blast_radius: 3` and `voi_score: 0.5` already
# filled in, and that default was doing real damage: int(round(0.5*5)) == 2, and
# an ABSENT voi_score also scored 2, so "nobody assessed this" and "someone
# judged it middling" were the same number. 42 of 45 inceptions ranked on a
# value no person had chosen, and because 2 is mid-range they sorted ahead of
# measured work. T-624 tried to fix it with a warning printed right here; 28
# days later the figure had not moved by one, because a comment is not a gate.
# Deleting the default IS the gate.
#
# TO OVERRIDE. Set the value AND its source, and it becomes sticky — no
# automatic pass will ever change it again:
#
#   voi_score: 0.9
#   voi_score_source: human
#
# Anything without `_source: human` is treated as the estimator's own and is
# freely recomputed. There is no third state, deliberately: an "unknown
# provenance" value is exactly the ambiguity this replaced.
#
# target_blast_radius — int 0..9. Anticipated component count of the build work
#   this inception would authorise on GO; substitutes for the absent
#   components: list in the F8 cost formula (040).
#   Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem
#   (M), 7=multi-arc (L), 9=framework-wide (XL).
# voi_score — float 0..1. Value of Information: expected value of RESOLVING
#   this question, independent of build cost. Higher when the answer affects
#   many tasks or unblocks a strategic decision.
bvp_scores_proposed:
  - ts: '2026-10-01T19:03:10Z'
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
    rationale: D1=3 (voi:decision-with-alternatives~'go/no-go'); D2=3 
      (voi:decision-with-alternatives~'go/no-go'); D3=3 
      (voi:decision-with-alternatives~'go/no-go'); D4=3 
      (voi:decision-with-alternatives~'go/no-go'); F-RECALL=3 
      (voi:decision-with-alternatives~'go/no-go'); F2=3 
      (voi:decision-with-alternatives~'go/no-go'); F4=3 
      (voi:decision-with-alternatives~'go/no-go'); F3=3 
      (voi:decision-with-alternatives~'go/no-go'); F1=3 
      (voi:decision-with-alternatives~'go/no-go')
    rubric_sha: e4a00f38e801
---

# T-980: RCA: why the peer-consult sidecar never works for 832 (no listener, wrong identity, unread inbox) while it works for other agents

## Problem Statement

Interactive agent-to-agent communication keeps failing for this project, and the operator
has had to say "check your inbox" more than once. Measured on 2026-10-01 (T-979):
`fw sidecar inbox` reads an empty inbox while the real one holds 79 consults (cursor at 0,
never read); every consult we send is signed `.agentic-framework`; no listener process exists
for 832 (or for Ring20), while three other agents have one; the escalation ladder never ran on
any of our 4 sends. Operator: *"I really want to find this to the bottom ... how come this is
overlooked? This is essential for interactive communication ... you need to help your
engineering upstream agent to solve that."* Research artefact:
`docs/reports/T-980-sidecar-rca.md`.

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

We believe that fixing the sidecar upstream for vendored consumers (AEF D1-D4: project identity
from the project root, the inbox hook installed and able to parse the inbox, the sweep cron for
consumers; TermLink D5-D6: per-project listeners and receipts),
we will achieve working two-way agent messaging for this project without manual workarounds.
We will know that we are successful when we see `fw sidecar whoami` print `832-Workflow-designer` with no FRAMEWORK_ROOT override, the sidecar-inbox hook installed in `.claude/settings.json` and printing a non-empty block when the inbox holds 1 or more consults, and a consult sent to 999-Agentic-Engineering-Framework return a reply that `fw sidecar inbox` shows here; all measured in this project after the next bleeding-edge upgrade.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-XXX -->

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

- **IW-1: Why does the sidecar resolve this project's identity as `.agentic-framework`?**
  confidence: 3
  disposition: answered
  rationale: lib/sidecar/outbox.py:36 _root() uses FRAMEWORK_ROOT (else __file__ parents[2]); circuit.py:145 takes its .name. Overriding FRAMEWORK_ROOT to the project root makes whoami print 832-Workflow-designer (D1).
- **IW-2: What starts a sidecar listener (notify-sidecar.sh) for an agent, and why is there none for 832?**
  confidence: 3
  disposition: answered
  rationale: TermLink's cron supervisor starts only agents declared in /opt/termlink/.context/cron/notify-sidecar-agents.conf (3 agents; none is 832 or Ring20). notify-sidecar.sh:46 defaults SELF_PROJECT=010-termlink (D5). AEF's consumer half, the sidecar-inbox hook, is never installed by lib/init.sh (D2) and cannot parse the CLI's dict output (D3: 79 in, 0 bytes out).
- **IW-3: Why did nothing — audit, doctor, handover, the send itself — report that our inbox was never read and our sends never acknowledged?**
  confidence: 3
  disposition: answered
  rationale: every guard reads through the same wrong identity (inbox, audit ledger, hook), the hook fails open silently, and delivered:true measures transport not reading. The sweep cron that would escalate exists only for AEF (D4).
- **IW-4: Is this specific to vendored installs, i.e. does it hit every project that vendors AEF (Ring20 included)?**
  confidence: 2
  disposition: answered
  rationale: D1-D4 follow from vendoring by construction; AEF itself is not vendored, which is why it works there. Ring20 vendors AEF (its worker runs .../proxmox-ring20-management/.agentic-framework/bin/fw) and its sidecar inbox holds only our posts. Confidence 2, not 3: Ring20's own whoami was not run (boundary).

## Exploration Plan

<!-- How will we validate assumptions? Spikes, prototypes, research? Time-box each. -->

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

<!-- What's IN scope for this exploration? What's explicitly OUT? -->

## Acceptance Criteria

### Agent
<!-- @auto-tick-on-decide -->
- [x] Problem statement validated
<!-- @auto-tick-on-decide -->
- [x] Assumptions tested
<!-- @auto-tick-on-decide -->
- [x] Recommendation written with rationale

### Human
<!-- @auto-tick-on-decide -->
- [x] [REVIEW] Review exploration findings and approve go/no-go decision
  **Steps:**
  1. Run: `fw task review T-XXX` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- Root cause identified with bounded fix path
- Fix is scoped, testable, and reversible

**NO-GO if:**
- Problem requires fundamental redesign or unbounded scope
- Fix cost exceeds benefit given current evidence

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

**Recommendation:** GO — fix upstream (AEF D1-D4, TermLink D5-D6), not by patching our vendored copy

**Rationale:**

Seven defects, each sufficient on its own; four are in AEF's sidecar and installer, two in
TermLink, one is Ring20's channel choice. The mechanism works only in its two producer repos,
which are not vendored, and every guard reads through the same wrong identity, so it was never
seen to fail. A local patch to `.agentic-framework/` is lost at the next upgrade and the
operator says the next bleeding-edge upgrade is the vehicle. So: send AEF the RCA as a pickup
now, keep the documented local workaround until the upgrade lands, then verify in this project
with `fw sidecar whoami` + a live round trip.

**Evidence:**

- `docs/reports/T-980-sidecar-rca.md` — D1..D7 with file:line and measurements
- hook parser: 79 consults in, 0 bytes out (D3)
- `FRAMEWORK_ROOT=<project>` override: whoami correct, 79 consults visible (D1)
- `/opt/termlink/.context/cron/notify-sidecar-agents.conf`: 3 declared agents, none ours (D5)
- `dm:9219671e28054458:d1993c2c3ec44c94` offsets 71/73: receipts by 010-termlink for our post (D6)

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

**Decision**: GO

**Rationale**: GO: the peer-consult sidecar works only in the repos that built it (AEF, TermLink, neither vendored); every vendored consumer is deaf. Seven defects, each sufficient (docs/reports/T-980-sidecar-rca.md): D1 identity from FRAMEWORK_ROOT, D2 sidecar-inbox hook never installed, D3 hook cannot parse the CLI dict and fails silent (79 in, 0 out), D4 sweep cron only for AEF, D5 listeners only for TermLink-declared agents, D6 shared host key receipted by TermLink, D7 Ring20 reads DMs not inboxes. Fix upstream, not by patching the vendored copy; RCA sent to AEF as a pickup. Local workaround until the bleeding-edge upgrade: FRAMEWORK_ROOT override for sidecar_cli.py. Verify after upgrade: whoami names 832-Workflow-designer and a live round trip is read here.

**Date**: 2026-10-01T19:24:17Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-01T19:03:10Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-01T19:24:17Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** GO: the peer-consult sidecar works only in the repos that built it (AEF, TermLink, neither vendored); every vendored consumer is deaf. Seven defects, each sufficient (docs/reports/T-980-sidecar-rca.md): D1 identity from FRAMEWORK_ROOT, D2 sidecar-inbox hook never installed, D3 hook cannot parse the CLI dict and fails silent (79 in, 0 out), D4 sweep cron only for AEF, D5 listeners only for TermLink-declared agents, D6 shared host key receipted by TermLink, D7 Ring20 reads DMs not inboxes. Fix upstream, not by patching the vendored copy; RCA sent to AEF as a pickup. Local workaround until the bleeding-edge upgrade: FRAMEWORK_ROOT override for sidecar_cli.py. Verify after upgrade: whoami names 832-Workflow-designer and a live round trip is read here.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-665f97e6
- **Timestamp:** 2026-10-01T19:24:21Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Verification-level findings:**

  1. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-3
     - evidence: `IW-3 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`
  2. **disposition-incomplete** (partial, heuristic) @ ## Open Questions: IW-4
     - evidence: `IW-4 disposition='answered' but rationale has no evidence citation (T-NNNN, file:line, docs/reports/, G-/L-/D-id, dialogue-log, or commit hash)`

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-6994e327
- **Timestamp:** 2026-10-01T19:24:21Z
- **Overall:** CONFIRMED
- **Claims:** 2

| Claim | Type | Status |
|-------|------|--------|
| `docs/reports/T-980-sidecar-rca.md` | file | ✓ pass |
| `/opt/termlink/.context/cron/notify-sidecar-agents.conf` | file | ✓ pass |

### 2026-10-01T19:24:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
