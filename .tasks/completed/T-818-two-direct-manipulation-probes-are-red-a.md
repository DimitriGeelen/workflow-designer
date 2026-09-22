---
id: T-818
name: "Two direct-manipulation probes are RED and nobody knows since when"
description: >
  Measured while wiring T-817. tools/_endpoint-overlap-verify-cdp.mjs fails a real assertion (expects edge 'e_11'); tools/_saveproject-verify-cdp.mjs reports pass:false. Neither is an infrastructure error — both load src/ directly, drive a real headless Chrome, and emit structured JSON naming the offending element. They were written, passed once at their task's completion, and were never wired to anything that re-runs them (F-08's 118-instrument population), so NOTHING RECORDS WHEN THEY WENT RED. It is not knowable from the tree whether the editor regressed or the expectation went stale — the same 'UNMEASURED, not zero' shape F-03 named for the suite's own 7 failures. Deliberately NOT wired into the suite by T-817: wiring a red probe converts an unobserved failure into a permanently red leg, and OBS-293 records that a leg which is always red teaches readers to rerun rather than to look. Diagnose each: read the JSON, decide whether the editor or the expectation is wrong, fix the right one, then wire it.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tests/run-bridge-tests.sh, tools/_endpoint-overlap-verify-cdp.mjs, tools/_saveproject-verify-cdp.mjs, tools/_t817-wiring-controls.sh, tools/_t818-probe-controls.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T14:47:07Z
last_update: 2026-09-22T16:09:10Z
date_finished: 2026-09-22T16:09:10Z
# revisit_at: YYYY-MM-DD          # T-1451: set on DEFER decisions to enable G-053 daily revisit scan
# revisit_evidence_needed:        # T-1451: one-line description of what evidence makes the revisit actionable
# ── BVP scoring fields (T-1918, arc-006). See docs/reports/T-1915-bvp-inception.md for semantics. ──
# bvp_scores:                     # confirmed per-driver scores 0-5, set by `fw bvp confirm` (T-1924).
#                                 # Sovereignty boundary — only set after human or agent confirmation.
#                                 # Shape: {D1: <int 0-5>, D2: <int 0-5>, D3: <int 0-5>, D4: <int 0-5>, [<free-driver-id>: <int>]...}
# bvp_scores_proposed:            # estimator-proposed scores (T-1922 worker). Persists when ≥2 delta
#                                 # from bvp_scores: on any driver (M3 v2-delta). Shape: list of timestamped entries.
# cost_estimate:                  # F8 composite: 0.6×blast_radius + 0.3×tier + 0.1×effort.
#                                 # Q2 fallback: T-shirt S/M/L/XL mapped to 2/4/6/8 when blast_radius is not yet computable.
---

# T-818: Two direct-manipulation probes are RED and nobody knows since when

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] For each probe, the JSON verdict is read and the failure is attributed: either the EDITOR regressed or the EXPECTATION went stale — stated with evidence, not guessed
- [x] Whichever side is wrong is the side that changes. An expectation is not relaxed to make a red probe green unless the editor's current behaviour is shown to be correct
- [x] If the editor regressed, the regression is dated as far as the tree allows, and the fact that nothing recorded when it broke is stated rather than glossed
- [x] Once green, each probe is wired into `tests/run-bridge-tests.sh` alongside T-817's four, so it cannot rot unobserved again
- [x] CONTROL: each newly-wired probe is proven to fail the suite when its subject breaks
- [x] `_endpoint-overlap` and `_saveproject` are handled as TWO separate diagnoses — one bug, one task's worth of reasoning each; a shared "fixed the probes" commit would destroy the causality this task exists to recover

### Human
<!-- Criteria requiring human verification (UI/UX, subjective quality). Not blocking.
     Remove this section if all criteria are agent-verifiable.
     Each criterion MUST include Steps/Expected/If-not so the human can act without guessing.

     ── Prefix routing (T-1811, T-1878): default to [REVIEWER] if Expected is grep-able ──
     If your Expected clause is grep-able / file-exists / structural (a deterministic
     shell check), prefer [REVIEWER] — that AC should be an Agent AC with the reviewer
     command in `## Verification` instead of a Human AC here. Only keep [REVIEW] if
     verification genuinely needs human taste (tone, feel, layout rhythm).
     See CLAUDE.md §AC Classification Guidance for the conversion rule.

     [REVIEW] example (genuine human judgment):
       - [ ] [REVIEW] Dashboard renders correctly
         **Steps:**
         1. Open https://example.com/dashboard in browser
         2. Verify all panels load within 2 seconds
         3. Check browser console for errors
         **Expected:** All panels visible, no console errors
         **If not:** Screenshot the broken panel and note the console error

     [REVIEWER] example (static-scan-verifiable — convert to Agent AC + Verification):
       - [ ] [REVIEWER] Block message names both bypass mechanisms
         **Steps:**
         1. Run `bin/fw reviewer T-818`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-818 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# ---- T-818 legs -------------------------------------------------------------
# 1+2. Each probe passes on the real tree. Its own exit code is the verdict, so no
#      context question arises (T-352). These are the two that were red for 56 and 75 days.
node tools/_endpoint-overlap-verify-cdp.mjs > /tmp/.t818-eo.out 2>&1
node tools/_saveproject-verify-cdp.mjs > /tmp/.t818-sp.out 2>&1
# 3. The probes DISCRIMINATE — 6 controls: subject-break and stimulus-break for each, plus a
#    clean baseline per probe without which a red result proves nothing.
bash tools/_t818-probe-controls.sh > /tmp/.t818-ctl.out 2>&1
# 4. All three are wired with LITERAL `tools/<name>` paths. Not style: _t451's edge detector
#    matches the literal string, so a composed path runs the probe while the instrument whose
#    job is detecting wiring cannot see it (measured A/B in T-819, delta ZERO).
grep -q 'tools/_endpoint-overlap-verify-cdp.mjs' tests/run-bridge-tests.sh && grep -q 'tools/_saveproject-verify-cdp.mjs' tests/run-bridge-tests.sh && grep -q 'tools/_t818-probe-controls.sh' tests/run-bridge-tests.sh
# 5. The census agrees they now have a live caller. `;` not `&&` is deliberate — the census
#    exits non-zero BECAUSE it has findings, and the verdict here is the grep (T-352 says the
#    line is judged on the last command alone; that is the intent, not an accident).
#    The positive clause is the CONTROL for the two negative ones: _autoload-verify-cdp is a
#    sibling probe still unwired (blocked on a stale build artefact), so if it disappears too
#    the output is empty or broken and the absences below would be vacuous (T-804).
python3 tools/_t451-unwired-guard-census.py > /tmp/.t818-census.out 2>&1; grep -q '_autoload-verify-cdp' /tmp/.t818-census.out && ! grep -q '_endpoint-overlap-verify-cdp' /tmp/.t818-census.out && ! grep -q '_saveproject-verify-cdp' /tmp/.t818-census.out
#
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
# Origin: L-387, captured 4× (T-1716, T-1838, T-1862, T-1863) before this hint.
#
# Single pipe only — no intermediate tail/awk/sed stages between capture and grep
# (T-2090): `echo "$out" | tail -3 | grep -q PAT` re-introduces the SIGPIPE risk
# the capture step closed off — the middle stage is what `grep -q` slams its
# stdin on. `echo "$out"` is small and immediate; grep scans the whole captured
# string anyway, so the tail-3 was cosmetic. Drop it: `echo "$out" | grep -q PAT`.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** two CDP probes that load `src/` directly and drive real headless Chrome both
reported `pass:false`. Neither was an infrastructure error, and nothing recorded when either
went red.

**Root cause — the same one twice, and it is not in the editor.** Both probes were written
against a gesture the editor then deliberately improved, and neither was re-run afterwards:

| probe | written | the editor changed | red for |
|---|---|---|---|
| `_endpoint-overlap` | 2026-07-06 (T-136) | 2026-07-28 — T-293 moved endpoint halos to `#g-handles` above `#g-nodes`, because handles resident in `#g-edges` were shadowed by node bodies exactly where they matter (T-168 anchors endpoints on the node border) | 56 days |
| `_saveproject` | 2026-07-06 (T-130) | 2026-07-09/10 — T-150 put an optional per-version note between click and POST, T-161 made it the in-app `#save-note-modal` | 75 days |

Both editor changes were correct and both are documented at the change. The probes' *gestures*
went stale, not the editor.

**Why structurally allowed:** neither probe had a live caller. F-08 measured 118 such
instruments — "written, ran once at task completion, never wired to anything that re-runs
them". A probe in that state has no failure date because nothing ever asked it.

**The part that is worse than silence, and the reason this is not just F-08 again:** an
unobserved probe does not merely stop informing — it starts MISINFORMING, and the reader it
misinforms is whoever next triages the list.

- `_endpoint-overlap` reported a `TypeError: Cannot read properties of null (reading 'cx')`.
  That reads as a failing check and is not one: `querySelector` returned null and the next
  line dereferenced it, so the final assertion — that a real endpoint DRAG is not hijacked
  into sibling-select — never executed. It could not FAIL because its STIMULUS never fired.
  PL-206, inside the probe written to guard the T-136 fix.
- `_saveproject` reported four red steps (no feedback, no version, no thumbnail, roundtrip
  404) that together read as "the save path is broken". All four were consequences of one
  stall in a modal. A reader would have gone looking at `/api/save`, the thumbnail capture
  and the sidecar — none of which were ever invoked. The save path was never broken.

**Prevention** — three things, only the first of which is the fix:

1. Both probes now match on the element's own identity / drive the modal, so they exercise
   the real gesture again.
2. Each gained a NAMED step asserting its stimulus exists (`endpoint-halo-found`,
   `save-note-modal-opened`) and fails as COULD-NOT-MEASURE when it does not. The next
   relocation is then reported as "the gesture changed" instead of as a fabricated failure
   of a subject nothing touched.
3. `tools/_t818-probe-controls.sh` drives BOTH branches per probe — subject-break (editor
   regresses, probe must go red) and stimulus-break (probe's gesture becomes unreachable,
   probe must go red *naming the missing stimulus*). The second branch is the one that was
   missing for 56 and 75 days. Every mutation asserts it matched exactly once, because a
   mutation that silently fails to apply turns "the probe caught it" into "the probe ran
   against unmutated source" — this task's defect wearing a control's clothes.

All three are wired into `tests/run-bridge-tests.sh` with literal `tools/<name>` paths so
`_t451` can see them; the census now reports both probes as having a live caller, while
sibling `_autoload-verify-cdp` remains unwired and listed, which is what makes that a
reading rather than an empty output.

**Not prevented, and stated rather than glossed:** nothing dates either failure, and nothing
can. The tree records when the editor changed; it does not record when the probe stopped
agreeing. Only re-execution produces that, which is F-03 — the suite is still scheduled by
nobody.

<!-- REQUIRED for bug-class tasks (workflow_type=build with bug-tag, OR title matches
     fix/bug/rca/broken/crash/error/regression/fail/hotfix).
     Non-bug-class tasks may leave this section empty or remove it.

     For bug-class, fill in:
       **Symptom:** what was observed (the user-facing manifestation).
       **Root cause:** the specific structural/logical gap — not "the code was wrong".
       **Why structurally allowed:** what in the framework/code/tooling let this go undetected.
       **Prevention:** what catches the next instance (test/lint/gate/doc/learning) — distinct from the fix itself.

     The completion gate (T-1550, G-019) blocks --status work-completed when
     bug-class AND this section is empty/template-only. Use --skip-rca to bypass (logged).
-->

## Evolution

<!-- REQUIRED for arc-tagged build tasks (tags include arc:*). Captures how
     understanding evolved during build — what was learned that wasn't known at
     filing, what in the original plan no longer fits, what triggered pivots
     or new sub-tasks. Mandatory at slice boundaries (when applicable) and
     before --status work-completed.

     Origin: T-1717 grill Q4 — "the understanding of what we need and want
     evolves with the process of materialisation." Structural counter to §ACD:
     spec-vs-build divergence is logged as soon as it happens, not lost as
     folklore.

     Format (one entry per slice boundary or significant insight):
       ### YYYY-MM-DD — [topic]
       - **What changed:** [what we learned that we didn't know at filing]
       - **Plan impact:** [what in the plan no longer fits]
       - **Triggered:** [new sub-task / pivot / scope cut, with task ID if filed]

     The completion gate (T-1718) blocks --status work-completed when this
     section exists but is empty/template-only. Use --skip-evolution to bypass
     (logged Tier-2). Non-arc tasks may leave this empty.
-->

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

<!-- Filled at completion of inception tasks via:
     fw inception decide T-818 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T14:47:07Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-818-two-direct-manipulation-probes-are-red-a.md
- **Context:** Initial task creation

### 2026-09-22T14:50:08Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e08dbb52
- **Timestamp:** 2026-09-22T16:09:35Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** yes
- **Findings:** none

- **Layer-1 escalations:** 1
  1. **destructive-action** (high) — Destructive operation in verification or AC
     - matched: `destroy`

### 2026-09-22T16:09:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
