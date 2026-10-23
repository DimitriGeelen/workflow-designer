---
id: T-1285
name: "Quality engine: what structural changes make a designer change reach AEF right
  first time"
description: >
  Inception: Quality engine: what structural changes make a designer change reach
  AEF right first time

status: started-work
workflow_type: inception
current_node: frw_1_start
owner: human
horizon: now
tags: []
components: []
related_tasks: []
created: 2026-10-23T22:00:14Z
last_update: '2026-10-23T22:02:11Z'
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
  - ts: '2026-10-23T22:02:11Z'
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

# T-1285: Quality engine: what structural changes make a designer change reach AEF right first time

## Problem Statement

**The operator, 2026-10-23:** "what do we need to do to improve our quality? We keep f***ing around, reading around
the bush, we're still not really getting good runs. ... Structurally, it's about improving the engine. And we know
what our particular goal and objectives are."

**The goal it serves** (CLAUDE.md, operator 2026-10-17): the designer is AEF's base. A designer change is done only
when AEF serves it, in tight continuous delivery. **Today a change rarely gets there in one pass:**
- **review rounds:** T-1241 needed 4 rounds (T-1274, T-1276, T-1277, T-1278), each a new point found by a reviewer
  that our own checks passed;
- **suite never green:** across 4 full runs on 2026-10-22/23 (305/8, 310/3, 307/6, 315/1), each red needed manual
  triage; most were environment, load or stale anchors, not product;
- **releases:** 0.25.0 shipped with the previous release's commit subject; 0.26.0 stopped on a reviewer false finding
  that our own validator text helped cause (T-1284);
- **AEF parity:** AEF lacked 4 of 13 designer endpoints (Check, instance overlay, field profile, field suggestions)
  and nothing compared the two (2026-10-23);
- **framework drift:** 37 local framework patches are re-applied by hand at every upgrade; 15 AEF tags in two days.

This inception asks one question: which few structural changes to how we build, check and ship would make a designer
change reach AEF right first time?

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

We believe that measuring, in the engine and before any review, what a person and AEF actually get (rendered result
at three widths, endpoint coverage, a hermetic suite), we will achieve designer changes that pass review and reach AEF
in one pass.
We will know that we are successful when we see, over the next 5 designer UI tasks: at most 1 official review round
each, a core suite 100% green on every push, 0 AEF endpoint gaps undetected at release time, and each release job
completing on its first run.

## Assumptions

<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1285 -->

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

- **IW-1: Where does rework actually come from?** Count, from git and task history over the last 30 days, the loops
  per designer change (review rounds, re-shoots, follow-up tasks, release attempts) and classify each loop's cause:
  check measured the wrong thing / environment / reviewer error / scope / process.
  confidence: 2
  disposition: answered
  rationale: spike 1 (docs/reports/T-1285-quality-engine.md). About 1 in 4 operator runs stops (30 STOPPED / 77
  done; 22 of 83 jobs retired), the largest cause being a framework gate the dry-run never exercised (7 jobs); then
  review rounds (T-1241 x4).
- **IW-2: Which suite reds are product, and which are environment?** Classify every failing leg in the last 10 full
  runs as product regression / environment (load, /tmp, TMPDIR, host) / stale anchor after upgrade / census drift.
  confidence: 2
  disposition: answered
  rationale: spike 2. Of 10 red legs triaged per leg over 3 runs, 0 were product regressions (5 environment, 2
  upgrade drift, 2 guard literalness/bookkeeping, 1 process). A 10-run pass would firm up the ratio, not change its
  direction.
- **IW-3: Can a "what a person sees" gate replace discovery-by-reviewer?** Of the findings reviewers raised on
  T-1241/T-1282, how many could a deterministic check on the rendered SVG/DOM have caught (crossings, arrowheads,
  clipping, text size, contrast, reachability)?
  confidence: 2
  disposition: answered
  rationale: spike 3. 9 of 13 distinct reviewer points (~70%) were mechanically decidable on the rendered map; 2 were
  taste and 2 were AEF's map content.
- **IW-4: Can the designer-to-host contract be generated from source and checked against AEF?** Generate the
  endpoint list from the designer source and compare it with AEF's vendored server code.
  confidence: 3
  disposition: answered
  rationale: spike 4. A ~30-line script reproduces the manual result exactly (13 used, 9 served, 4 missing; gaps 13-25
  days old) from source and AEF's vendored code.
- **IW-5: Can release reviewer findings be made verifiable?** A finding cites file:line, and a script checks the
  quoted text exists before it counts.
  confidence: 2
  disposition: answered
  rationale: spike 5. REVIEW.json has no map evidence today and loop.sh checks none. A required map_evidence
  {line, quote} plus a quote check would have flagged GLM's claim (line 119 lacks the quoted default=).

## Exploration Plan

Five spikes, each time-boxed to about one hour and answering one IW. Results go into
docs/reports/T-1285-quality-engine.md as they land. No build work before the GO.
1. Rework census from git and episodic memory, 30 days (IW-1).
2. Suite-red classification over the last 10 runs (IW-2).
3. Reviewer-finding census on T-1241/T-1282: what a deterministic check could have caught (IW-3).
4. A throwaway script generating the endpoint contract from src, diffed against AEF's vendored code (IW-4).
5. The kit's REVIEW.json schema and a quote-checker prototype on the 0.26.0 calibration outputs (IW-5).

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

**IN:**
- measuring where 832's rework comes from;
- ranking at most five structural changes to the engine (checks, suite, contract, release review, framework
  drift);
- naming the build tasks a GO would create, and the weekly metrics.

**OUT:**
- building any of them, which comes after the GO as separate tasks;
- AEF's own process: we can propose upstream changes, not make them;
- the designer's feature roadmap.

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
  1. Run: `fw task review T-1285` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- the spikes attribute at least half of the measured rework loops to causes a deterministic engine check, a hermetic
  suite or a generated contract would have caught;
- each proposed change is a bounded build task (at most about one session each) with its own metric.

**NO-GO if:**
- most rework comes from scope or decisions (what to build), not from checking or shipping. Then the fix is in
  planning, not the engine, and this inception says so;
- the changes would cost more upkeep than the rework they remove (measured in loops per month).

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

**Rationale:**

The spikes meet the GO criterion: most measured rework comes from checking and shipping, not from what to build.
- About 1 in 4 operator runs stops, mostly because a rehearsal checks preconditions but never exercises the steps'
  gates.
- ~70% of reviewer findings were mechanically decidable.
- The suite was red every run while catching 0 product regressions.
- AEF went 13-25 days without 4 designer endpoints, with nothing comparing the two.
Each remedy is a bounded build task with its own metric, so build them in the ranked order, one at a time:
1. a deep rehearsal for operator jobs;
2. a "what a person sees" gate before review;
3. a hermetic core suite plus quarantine;
4. a generated designer-to-host contract;
5. verifiable reviewer findings;
6. upstreaming local framework patches.
Measure weekly against the hypothesis.

**Evidence:**
- docs/reports/T-1285-quality-engine.md, spikes 1-5 (commits d6710863, d1e272ca, 2bce661e and the spike-4 commit)
- `.context/runme/*/retired` (22 retirements by cause) and `.context/working/runme.events` (30 STOPPED / 77 done)
- `.context/working/t1275-suite.log`, `t1279-suite.log`, `t1280-suite.log` (per-leg triage)
- `.context/working/t1285/contract.py` (the contract spike)
- `docs/authoring-kit/REVIEW.md:6-9`, `docs/authoring-kit/loop.sh:98-119` (finding format and scoring)

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

<!-- Filled at completion via: fw inception decide T-1285 go|no-go --rationale "..." -->

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-23T22:02:09Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
