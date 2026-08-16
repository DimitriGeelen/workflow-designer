---
id: T-339
name: "Widen the input-fidelity instrument to the two populations G-016 names and
  T-338 did not cover: malformed input and unresolvable refs"
description: >
  Widen the input-fidelity instrument to the two populations G-016 names and T-338
  did not cover: malformed input and unresolvable refs

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T10:22:41Z
last_update: '2026-08-16T12:33:51Z'
date_finished: 2026-08-02T10:44:03Z
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
bvp_scores_proposed:
  - ts: '2026-08-16T12:33:51Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 3
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=3 
      (body:component-silent-failure); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-339: Widen the input-fidelity instrument to the two populations G-016 names and T-338 did not cover: malformed input and unresolvable refs

## Context

G-016's `decision_trigger` names **three** populations the input-fidelity check must cover:
"malformed input, out-of-vocabulary tags, unresolvable refs". T-338 landed
`tools/_t338-input-fidelity-cdp.mjs` and covered **one** of them — out-of-vocabulary tags
(10 standard BPMN flow-node tags the importer's allowlist omits).

The other two were never measured, and the sentence I put on the rail (394) —
"G-016's 'the next divergence would be equally invisible' is now false regardless" — is
true for a *vocabulary* divergence and unproven for the other two. A trigger with three
clauses, satisfied on one, reported in prose that does not name which: the same shape as
the IW-3 "not measured" cells that moved the published ratio 4-of-5 → 5-of-5. The fix is
to measure the remaining two, not to reword the claim.

**The design trap this task must avoid.** For the corpus and for out-of-vocabulary tags,
the expected property is *losslessness*, and T-338 asserts it directly. For **malformed
input that is the wrong expectation**: refusing to load a broken document is correct
behaviour, and a guard demanding preservation would go red when the designer does the
right thing — the `probes-that-fail-when-right` trap, hit three times already on this arc.
The property that is actually wanted is:

> **Either refuse visibly, or preserve. Silent partial acceptance is the defect.**

So the malformed leg must be three-way (REFUSED / PRESERVED / SILENTLY-PARTIAL) and only
the third is a failure. Same for unresolvable refs: dropping a dangling `flowNodeRef` may
be a legitimate repair, whereas dropping the *element that carried it* is loss — those two
outcomes must not share a verdict.

Related: G-016 (the gap), T-338 (the one leg that exists), T-337 (the defect that lived in
the uncovered intersection), T-309 IW-3 (where the import verdict vocabulary came from).

## Acceptance Criteria

### Agent
- [x] The instrument probes a **malformed-input** population (not-well-formed XML, absent
      `<bpmn:process>`, node without an id, wrong root) and reports a three-way verdict per
      case: REFUSED (threw — acceptable), PRESERVED (acceptable), SILENTLY-PARTIAL (fails).
- [x] The instrument probes an **unresolvable-ref** population — dangling `sourceRef`,
      `targetRef`, `flowNodeRef` and `attachedToRef` (4 cases) — keyed on `aef:uid` so a
      legitimate ref repair does not read as data loss. A dangling DI `bpmnElement` is
      deliberately NOT a separate case: the entire `bpmndi` sub-tree is dropped regardless
      of whether its refs resolve (leg 5, T-340), so probing it would measure the sub-tree
      drop a second time rather than the ref.
- [x] Both new populations are **measured every run** and compared against an expected set,
      failing in EITHER direction — the T-338 discipline, so a behaviour that improves is
      recorded rather than silently absorbed.
- [x] Population assertions: the run fails if either new population is empty, or if any
      probe case could not be constructed (no silent skip shrinking the denominator).
- [x] Teeth: each new leg is proven to go RED by a mutation, and the failure text is
      asserted to NAME its own condition (not merely `rc != 0` — red is not evidence,
      red-for-the-stated-reason is).
- [x] The gating bridge runner still passes with the widened instrument wired in.
- [x] G-016's coverage is reported honestly clause-by-clause — which of the three
      populations is now covered and which is not. Flipping the concern's status stays with
      the operator.

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
         1. Run `bin/fw reviewer T-XXX`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-XXX 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# The instrument itself must be green on all five legs.
node tools/_t338-input-fidelity-cdp.mjs
# It must report all four widened populations, not silently shrink to the T-338 one.
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "8 malformed shapes, 4 unresolvable-ref shapes, 1 unknown sub-tree"
# The two safety verdicts must be stated, not merely absent.
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "no silent partial acceptance"
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "no identity lost"
# The gating suite must still be green. Asserted as 0 failed, NOT as a pass count:
# pinning "69 passed" would rebuild the G-015 shape (a global always-moving
# property inside a per-task gate).
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "0 failed"

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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

## Evidence

Measured 2026-08-02 over all 24 rendered corpus maps. Run time 4s.

| population | cases | result |
|---|---|---|
| corpus (T-338) | 24 maps | lossless — node/flow/lane counts preserved |
| out-of-vocabulary tags (T-338) | 10 | 10/10 lossy, set unchanged |
| **malformed input** (new) | 8 | 6 REFUSED, 2 PRESERVED, **0 SILENTLY-PARTIAL** |
| **unresolvable refs** (new) | 4 | **0 UID-LOST**; `flowNodeRef` re-homes framework→human on 5 |
| **unknown sub-tree** (new) | 1 | DI-DROPPED on 24/24 |

Teeth 7/7, every leg red *and naming its own condition*. Legs (f) and (g) mutate the
DESIGNER rather than the instrument: (f) makes the importer skip id-less elements and
`SILENTLY-PARTIAL` duly fires; (g) stops `aef:uid` being emitted and `UID-LOST` fires.
Without those two, "0 silent partial acceptance" and "0 identity lost" would be zeros in
buckets never shown fillable — indistinguishable from buckets that cannot fill.

Gating suite: bridge 69 passed / 0 failed, geometry sweep 24 clean.

### G-016 coverage, clause by clause

The gap's `decision_trigger` names three populations. State before and after this task:

| clause | T-338 | now |
|---|---|---|
| out-of-vocabulary tags | covered | covered |
| malformed input | **not covered** | covered (8 shapes, three-way verdict) |
| unresolvable refs | **not covered** | covered (4 shapes, identity-keyed) |

Rail post 394 said "G-016's *the next divergence would be equally invisible* is now false
regardless." That was true for a vocabulary divergence and unproven for the other two
clauses, and the prose did not say which. Corrected here rather than reworded.

**Flipping G-016's status remains the operator's call.** Two findings this widening
produced (T-340 DI loss, T-341 silent lane reassignment) are open, and the trigger's own
words — "closing because T-337 is fixed is not closure" — apply equally to closing because
the instrument now exists.

## Findings spun off

- **T-340** — standard BPMN DI is silently discarded (`DI-DROPPED` 24/24). T-337's class,
  one granularity up: an unknown sub-tree rather than an unknown tag. Latent by occupancy
  (0 of 175 local `.bpmn` carry DI) but it is what every mainstream modeller emits.
- **T-341** — an unresolvable `flowNodeRef` silently re-homes the orphaned node to the
  `human` lane. Not loss; a silent authority change, since lane is *who*.

## Method note — the measure was wrong twice before it was right

Worth keeping, because both traps are general and neither is about BPMN:

1. **Keyed on display id**, the lane comparison measured *renumbering*, not re-homing —
   display ids derive from lane + ordinal + name, so re-homing one node renames its
   siblings. Read 2 where the answer is 5, and on one map read "still present" only
   because a *different* node had inherited the vacated name.
2. **Keyed on uid but baselined on the mutated input**, the comparison excluded the
   victim: the mutation replaces its ref with a ghost, so the one node whose fate is the
   question was not in the comparison set. That version reported 0, and reported it
   cleanly. A probe that cannot observe its own subject returns a confident zero.

The baseline has to come from the ORIGINAL document, and identity has to be `aef:uid`.

## RCA

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
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-02T10:22:41Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-339-widen-the-input-fidelity-instrument-to-t.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-300052c9
- **Timestamp:** 2026-08-02T10:45:41Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T10:44:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
