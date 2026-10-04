---
id: T-1020
name: "Census: local fixes to vendored files that were never declared — which ones
  did the re-vendors lose silently?"
description: >
  Inception: Census: local fixes to vendored files that were never declared — which
  ones did the re-vendors lose silently?

status: work-completed
workflow_type: inception
current_node: frw_11_task
owner: human
horizon: null
tags: []
components: []
related_tasks: [T-1024, T-1025, T-1026, T-1027, T-1028, T-1021]
created: 2026-10-03T23:22:04Z
last_update: 2026-10-04T07:54:03Z
date_finished: 2026-10-04T07:54:03Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── Inception scoring exception (T-2186 Slice 2 / T-2188). See 050-Inceptions.md §Scoring Exception. ──
target_blast_radius: 3            # int 0..9. Anticipated component count of the build work this inception would authorise on GO.
                                  # Substitutes for the absent components: list in the F8 cost formula (040). Required.
                                  # Guide: 0=docs only, 1=single file, 3=small subsystem (S), 5=cross-subsystem (M), 7=multi-arc (L), 9=framework-wide (XL).
voi_score: 0.5                    # float 0..1. Value of Information — expected value of resolving this question,
                                  # independent of build cost. Higher when answer affects many tasks or unblocks a strategic decision. Required.
bvp_scores_proposed:
  - ts: '2026-10-04T00:11:46Z'
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

# T-1020: Census: local fixes to vendored files that were never declared — which ones did the re-vendors lose silently?

## Problem Statement

On 2026-10-04 (T-1009) T-931's `fw task delegate` owner fix (0a00d59d) turned out to have been
erased by the 1.7.740 re-vendor with no trace: never declared in .vendor-divergence.yaml, held by
no test, so `_t517` (which only knows declared paths) could not report it. The re-vendor protocol
(T-1000) and G4 stop this going FORWARD; nothing has looked BACKWARD. Every local commit that
touched `.agentic-framework/` before G4 existed is a candidate for the same silent loss, and a lost
fix is a live regression nobody is told about. Why now: AEF's next release is the next re-vendor;
anything lost must be on that upgrade's re-apply list, not discovered after it.

## Hypothesis

We believe that a mechanical census of every post-baseline commit that changed `.agentic-framework/`
— reverse-applying each commit's vendored hunks against HEAD — separates still-present, adopted-
upstream and silently-lost changes,
we will achieve a named list of silently lost local fixes (expected: a handful, not dozens, since
T-1005 re-applied the 51 declared ones),
We will know that we are successful when we see docs/reports/T-1020-silent-loss-census.md listing
every such commit with one verdict each (PRESENT / UPSTREAM / LOST / NOT-A-FIX), the LOST count
stated, and each LOST row carrying its probe result or "no probe".

## Assumptions
<!-- Key assumptions to test. Register with: fw assumption add "Statement" --task T-1020 -->

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

- **IW-1: How many commits since the T-276 baseline changed `.agentic-framework/` other than via the two pristine re-vendor commits, and how many of their vendored hunks are no longer in HEAD?**
  confidence: 3
  disposition: answered
  rationale: 211 (commit,file) rows measured mechanically; 88 with <50% of added lines surviving, 28 of them naming a task the register never mentions + 12 on undeclared paths (docs/reports/T-1020-silent-loss-census.md, Spike A)
- **IW-2: Of the hunks no longer in HEAD, which were superseded upstream (the behaviour is present in another form) and which are genuinely lost?**
  confidence: 2
  disposition: answered
  rationale: by each task's probe or a behaviour check — LOST: T-866, T-908, T-912, T-914, T-939; usability-only T-636/T-650/T-652; wording-only T-624/T-625; the rest PRESENT. T-295/T-351 unverified (report table)
- **IW-3: For each genuinely lost fix, is it still wanted (a defect it fixed is still reproducible) and is there a probe that can prove it?**
  confidence: 2
  disposition: answered
  rationale: T-908 reproduced live (AttributeError hidden by 2>/dev/null, empty impact chain); T-939 verified (re-published value == /etc/machine-id, also in AEF's public mirror); T-866/T-912/T-914 confirmed absent by code, no probe — each restore needs one

## Exploration Plan

Research artifact: docs/reports/T-1020-silent-loss-census.md (created before the spike).
1. Spike A (1 h): enumerate commits touching `.agentic-framework/` since T-276's baseline, excluding
   the pristine re-vendor commits (7b5e227e T-840, 2659abad T-988); for each, `git apply --check -R`
   its vendored diff against HEAD per file. Read-only.
2. Spike B (1 h): for hunks that no longer reverse-apply, classify: path deleted/rewritten upstream,
   declared and re-applied (T-1005 rows), or candidate LOST; for each candidate, look for the
   behaviour upstream and run the commit's own probe if one exists.
3. Write the per-commit table and the recommendation.

## Technical Constraints

<!-- What platform, browser, network, or hardware constraints apply?
     For web apps: HTTPS requirements, browser API restrictions, CORS, device support.
     For hardware APIs (mic, camera, GPS, Bluetooth): access requirements, permissions model.
     For infrastructure: network topology, firewall rules, latency bounds.
     Fill this BEFORE building. Discovering constraints after implementation wastes sessions. -->

## Scope Fence

IN: read-only census of our own git history and the vendored tree; running existing probes.
OUT: re-applying anything (each lost fix becomes its own build task after the decision);
editing vendored files; contacting AEF beyond reporting the result.

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
  1. Run: `fw task review T-1020` (opens Watchtower with recommendation, assumptions, research artifacts)
  2. Review the Agent Recommendation section and go/no-go criteria evaluation
  3. Record decision via the Watchtower form or the command shown alongside the QR code
  **Expected:** Decision recorded, task completed
  **If not:** Ask agent for clarification on specific findings

## Go/No-Go Criteria

<!-- Fill these BEFORE writing the recommendation. The placeholder detector will block review/decide if left empty. -->
**GO if:**
- The census finds at least one genuinely LOST fix that is still wanted, and each can be restored as its own scoped task with a probe
- The census method itself is cheap enough to repeat before every re-vendor (minutes, mechanical)

**NO-GO if:**
- Zero genuinely lost fixes beyond T-931's (then record the clean result and close; G4 covers the future)
- The reverse-apply signal is too noisy to classify without reading every commit by hand

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

The census found FIVE more silently lost fixes beyond T-931's, two with live consequences, each with a bounded restore: (1) T-939 — the 1.7.740 re-vendor re-published this host's real /etc/machine-id (the secrets-store key derives from it) in .agentic-framework/docs/reports/T-375-agent-3-key-storage.md; the same file is in AEF's PUBLIC GitHub mirror (master and bleeding-edge); (2) T-908 — `fw fabric impact` crashes on 24 plain-string depends_on entries and 2>/dev/null turns the crash into an empty chain ("nothing depends on this"); (3) T-866 — GO no longer requires an observable hypothesis; (4) T-912 — `fw note promote` records `promoted_to: task`, not the id; (5) T-914 — `fw note resolve` is gone. GO = one build task per restore, each with a probe, each upstreamed in bundle E (T-1021); the machine-id needs AEF to redact upstream, and whether anything must be rotated or history rewritten is the operator's decision. The census also exposed and fixed a regression of my own (T-1023).

**Evidence:**
- docs/reports/T-1020-silent-loss-census.md — per-task table, probes run on HEAD, method
- T-908: traverse.sh with its stderr mask removed (scratch copy) raises AttributeError: 'str' object has no attribute 'get'
- T-939: comparison of the 32-hex value in the vendored report against /etc/machine-id → equal (value never printed); same check on the GitHub mirror's master and bleeding-edge → equal

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

**Rationale**: Census found five local fixes the 1.7.740 re-vendor erased silently (T-939 machine-id re-published, T-908 fabric impact silent crash, T-866 GO without observable hypothesis, T-912 promote records 'task', T-914 note resolve gone). Restore each as its own build task with a probe, and send each upstream in bundle E (T-1021). Key rotation and any history rewrite for T-939 are decided separately.

**Date**: 2026-10-04T07:54:02Z

## Updates

<!-- Auto-populated by git mining at task completion.
     Manual entries optional during execution. -->

### 2026-10-03T23:22:27Z — status-update [task-update-agent]
- **Change:** horizon: now → next

### 2026-10-04T00:11:46Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-10-04T07:54:02Z — inception-decision [inception-workflow]
- **Action:** Recorded inception decision
- **Decision:** GO
- **Rationale:** Census found five local fixes the 1.7.740 re-vendor erased silently (T-939 machine-id re-published, T-908 fabric impact silent crash, T-866 GO without observable hypothesis, T-912 promote records 'task', T-914 note resolve gone). Restore each as its own build task with a probe, and send each upstream in bundle E (T-1021). Key rotation and any history rewrite for T-939 are decided separately.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-bccd2ec4
- **Timestamp:** 2026-10-04T07:54:04Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

## Recommendation Verdict (v1.0)

- **Scan ID:** RC-1c4dc789
- **Timestamp:** 2026-10-04T07:54:04Z
- **Overall:** CONFIRMED
- **Claims:** 9

| Claim | Type | Status |
|-------|------|--------|
| `T-931` | task | ✓ pass |
| `T-939` | task | ✓ pass |
| `T-375` | task | ✓ pass |
| `T-908` | task | ✓ pass |
| `T-866` | task | ✓ pass |
| `T-912` | task | ✓ pass |
| `T-914` | task | ✓ pass |
| `T-1021` | task | ✓ pass |
| `T-1023` | task | ✓ pass |

### 2026-10-04T07:54:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
- **Reason:** Inception decision: GO
