---
id: T-995
name: "Why did the bridge suite slide from 7 to 38 failures in 10 days without being
  stopped"
description: >
  Inception: Why did the bridge suite slide from 7 to 38 failures in 10 days without
  being stopped

status: work-completed
workflow_type: inception
owner: human
horizon: null
tags: []
components: []
related_tasks: [T-996, T-997, T-998, T-999, T-1000, T-1001, T-1002]
created: 2026-10-02T15:13:59Z
last_update: 2026-10-02T16:36:42Z
date_finished: 2026-10-02T16:36:42Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-02T15:14:35Z'
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
    rationale: D1=2 (no-signal); D2=2 (no-signal); D3=2 (no-signal); D4=2 
      (no-signal); F-RECALL=2 (no-signal); F2=2 (no-signal); F4=2 (no-signal); 
      F3=2 (no-signal); F1=2 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-995: Why did the bridge suite slide from 7 to 38 failures in 10 days without being stopped

## Problem Statement

<!-- What problem are we exploring? For whom? Why now? -->

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

- **IW-1: Are most of the 31 new failures environment-dependent (browser/CDP, Watchtower, hub) rather than product regressions, and does the suite fail to tell the two apart? (H1, lead L-a: 9 -> 30 at the same commit d43b09a0 in 3 minutes)**
  confidence: 2
  disposition: dissolved
  rationale: L-a compared a SIGPIPE-killed partial sweep (71 checks, rc 0; IW-4) with a full one — not an environment effect; env-dependent legs exist (live Watchtower, CDP) but did not drive the slide; spike 2 not needed. Report §Spike 1
- **IW-2: How many failures are guards on the vendored framework that drifted with upgrades (incl. the uncommitted T-988), unfixed and un-rebaselined? (H2)**
  confidence: 2
  disposition: answered
  rationale: ~24 of 38 test the vendored framework (by leg message/target, not re-verified per leg); curve 7-10 -> 29-32 follows the T-840 re-vendor (09-25, 1407 files, 545 with local commits; T-944 found >=4 local fixes reverted and the T-657 rail removed); the uncommitted T-988 re-vendor has already erased the T-952 rail. Report §Spike 1
- **IW-3: Does anything in the normal work cycle (task completion, handover, audit, release, pre-push) consume the suite's result, or does a red suite have no consequence? (H3)**
  confidence: 3
  disposition: answered
  rationale: no consumer can say no — completion, release (3 releases cut at 38-40), pre-push all ignore it; cron T-917 and audit rail T-952 only report, and the audit rail was erased from the working-tree audit.sh by the uncommitted T-988 re-vendor (HEAD 4 refs, tree 0; audit line present 10-01 23:00, absent in all 70 cron audits since); OBS-430 (urgent, 09-28) named the rc-0 defect and is still pending. Report §Spike 4
- **IW-4: Under what runner path did two sweeps exit rc 0 while recording 9 failures over 71 checks? (H4, lead L-b)**
  confidence: 2
  disposition: answered
  rationale: SIGPIPE — runner piped into `head` dies mid-sweep; EXIT trap records "$?"=0 and there is no PIPE trap (reproduced with identical trap logic: pipe -> rc=0 partial, unpiped -> rc=1); transcripts show agents running it `| grep FAIL | head -20`; _t952 ratchet accepts rc 0 as complete (COMPLETED_RCS=(0,1)) without checking fail==0. docs/reports/T-995-bridge-suite-slide.md §Spike 3

## Exploration Plan

Four spikes, time-boxed, detailed in docs/reports/T-995-bridge-suite-slide.md:
1. Attribute each of the 31 new failures (first failing run, cause class) — 2h — answers IW-1, IW-2
2. Reproduce L-a at d43b09a0 in a clean worktree with and without services — 1h — IW-1
3. Explain L-b from the runner's exit trap and history writer; failing test — 1h — IW-4
4. Trace who consumes the suite's result, here and in AEF upstream — 1h — IW-3

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

**Recommendation:** DEFER

**Rationale:**

Evidence not yet gathered; the decision is what structural change to make, and that needs the spikes. Leads from tests/.run-history.tsv: 7 failures on 2026-09-22, 32 when a ratchet floor was set on 09-30, 38 since 10-01; a jump 9 -> 30 on 09-27 at the SAME commit d43b09a0 three minutes apart (cause outside committed code); two runs on 09-27 that exited rc=0 while recording 9 failures over 71 checks (a suite reporting success while failing). Operator asked for this inquiry and expects framework-level learnings (2026-10-02).

**Evidence:**

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

**Rationale**: Slide caused by re-vendoring over local patches (~24/38), no consumer that can block, rails inside vendored files, and an exit-0-on-SIGPIPE record. Build B1-B5, upstream U1; designer failures as separate bug tasks.

**Date**: 2026-10-02T16:36:41Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-02T15:14:35Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-10-02T16:36:41Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Slide caused by re-vendoring over local patches (~24/38), no consumer that can block, rails inside vendored files, and an exit-0-on-SIGPIPE record. Build B1-B5, upstream U1; designer failures as separate bug tasks.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-1ee29122
- **Timestamp:** 2026-10-02T16:36:46Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-e0441a9d
- **Timestamp:** 2026-10-02T16:36:46Z
- **Overall:** UNVERIFIED
- **Claims:** 0
- No verifiable claims found in ## Recommendation

### 2026-10-02T16:36:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
