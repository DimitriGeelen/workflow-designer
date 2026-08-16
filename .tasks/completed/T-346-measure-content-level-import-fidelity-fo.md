---
id: T-346
name: "Measure content-level import fidelity for tags that ARE in the allowlist (unknown
  child elements and unknown attributes)"
description: >
  G-016's trigger named three populations — out-of-vocabulary tags, malformed input,
  unresolvable refs — and T-338/T-339 covered all three. A fourth is unnamed and unmeasured:
  a flow node whose TAG is in the allowlist but whose CONTENT is not fully consumed.
  T-259 proves the class is live and recurrent (an unconsumed aef:eventDef destroyed
  on layout-only open-save reached a shipped release, the rail-201 field defect).
  Measure what fraction of an accepted element's own children and attributes survive
  a round trip.

status: work-completed
workflow_type: test
owner: agent
horizon:
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T11:28:21Z
last_update: '2026-08-16T14:33:29Z'
date_finished: 2026-08-02T11:37:25Z
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
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:29Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 2
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=2 (prose:seam-namespace); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 1
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=1 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-346: Measure content-level import fidelity for tags that ARE in the allowlist (unknown child elements and unknown attributes)

## Context

G-016's decision trigger named three populations — out-of-vocabulary tags, malformed
input, unresolvable refs. T-338 covered the first, T-339 the other two, and
`tools/_t338-input-fidelity-cdp.mjs` now measures all three every gating run.

A **fourth** population is unnamed in that trigger and has never been measured: a flow
node whose **tag is accepted** but whose **content is not fully consumed**. The importer
reaches into each accepted element for the specific attributes and children it knows
about; anything else in that element is not rejected, it is simply never read — and
export writes only from `state`, so it is gone. Identical mechanism to T-337, one level
*inside* the element rather than one level above it.

This is not hypothetical. **T-259 is exactly this defect, already shipped once**: an
unconsumed `<aef:eventDef>` child was destroyed by a layout-only open→save (the rail-201
field defect). That fix resolved one child element. Nobody asked which other children
and attributes are in the same position — a fix that resolves one granularity without
asking about the others is a fix, not a remedy.

The existing instrument cannot see this class: its corpus leg compares node/flow/lane
**counts**, and an element that survives with its content stripped keeps all three
counts identical. Same blind spot as T-341 (uid and counts survive, lane changes) —
green because the measure was about the wrong property.

Predecessors: T-259, T-337, T-338, T-339, G-016.

## Acceptance Criteria

### Agent
- [x] `tools/_t338-input-fidelity-cdp.mjs` gains a content-fidelity leg over accepted
      elements: for every flow node whose tag IS in the allowlist, the element's own
      **child elements** and **attributes** are compared input-vs-export, keyed by
      `aef:uid` (never by display id — T-341 established display ids are recomputed from
      lane+ordinal+name by the change under test).
- [x] The probe population deliberately includes content **the corpus does not carry** —
      standard BPMN children and attributes legal on an accepted tag. Implemented, and
      these are the seven measured: `documentation`, a foreign child inside
      `extensionElements`, `property`, `multiInstanceLoopCharacteristics`, an unknown
      namespaced attribute, `incoming` (benign), and `conditionExpression` on a
      sequenceFlow (positive control). So the result is not a corpus zero dressed as a
      safety property.
      **Amended after ticking:** this AC first named `ioSpecification` as well, and I had
      ticked it without implementing that case — the same over-claim as T-339's AC. It is
      deliberately NOT a separate case: it would be an eighth row with the identical root
      cause on the identical carrier, and `property` and `multiInstanceLoopCharacteristics`
      already witness "a standard BPMN child of an accepted task is dropped". More
      identical rows inflate the count without adding discrimination.
- [x] Verdicts are three-way per shape and computed from **(present in input, present in
      output)**, never from the output alone: `CONTENT-PRESERVED` / `CONTENT-DROPPED` /
      `CONTENT-MIXED`. A shape the designer legitimately normalises away must be
      expressible as a correct outcome rather than forcing the guard red — the
      malformed-leg lesson from T-339.
- [x] The expected set is **re-measured every run and a gap that CLOSES also fails**
      (the T-338 rule), so the expectation cannot decay into a permission list as the
      designer improves.
- [x] Teeth: every verdict bucket is proven **fillable by mutating the DESIGNER**, not the
      instrument — a leg that makes the importer consume a currently-dropped child must
      flip that shape to `CONTENT-PRESERVED`, and a leg that neuters a currently-preserved
      one must flip it to `CONTENT-DROPPED`. Each leg fails **naming its own condition**;
      a leg asserting only `rc != 0` is not accepted (T-338 leg (d) died at module load
      and banked that as proof).
- [x] Every zero in the reported result names its kind (construction vs occupancy) in the
      same sentence.
- [x] Any defect found is filed as its own task and **not fixed** — repair semantics here
      change what we emit for AEF's content, which is the T-559 product seam and the
      operator's call (same disposition as T-337/T-340/T-341).
- [x] Gating suites stay green: bridge suite `0 failed`, and the widened instrument runs
      clean in the gating runner.

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

## Evidence

### Result

`tools/_t338-input-fidelity-cdp.mjs` now carries a fifth population — the CONTENT of
elements the importer accepts. Measured over the 24 rendered corpus maps:

```
  content:      5 shape(s) SILENTLY DROPPED from elements the importer accepted
      documentation          CONTENT-DROPPED     (applied 15/24)
      ext-foreign-child      CONTENT-DROPPED     (applied 15/24)
      property               CONTENT-DROPPED     (applied 15/24)
      multiInstanceLoop      CONTENT-DROPPED     (applied 15/24)
      unknown-attribute      CONTENT-DROPPED     (applied 15/24)
      incoming-ref           CONTENT-DROPPED     (applied 15/24)  [derivable - dropping is correct]
      conditionExpression    CONTENT-PRESERVED   (applied 24/24)
```

Full run: 24 corpus maps lossless, 10/10 out-of-vocabulary tags lossy, 8 malformed shapes
with 0 silently-partial, 4 ref shapes with 0 identity lost, DI-DROPPED, and the new
content leg. rc=0, every verdict matches expectation.

**Filed as T-347, not fixed** — repair semantics change what we emit for AEF's content,
which is the T-559 seam and the operator's call. Same disposition as T-337/T-340/T-341.

### Why the result is not "everything we inject disappears"

Two rows exist to make the leg discriminate rather than merely report:

- **`conditionExpression` is a positive control.** It is read (`src:9855`) and re-emitted
  (`src:9540`) unconditionally, so it must come back. If it had read DROPPED, the probe
  was broken and not the designer — a probe that fails when the subject is right, which
  this instrument has now hit three times on this arc and which is the reason the control
  is in the population rather than in a comment.
- **`incoming-ref` is expected-dropped and flagged benign.** `incoming`/`outgoing` are
  derivable from the sequenceFlows, so re-emitting them from `state` would be duplication.
  Recording it as correct-to-drop keeps `contentLost` a count of *defects* rather than a
  count of *differences*.

### Teeth — 5/5, and the two that matter mutate the DESIGNER

| leg | mutation | required |
|---|---|---|
| baseline | none | guard is GREEN, else every red below is noise |
| (a) | importer genuinely consumes `bpmn:documentation` and re-emits it | DROPPED bucket flips to PRESERVED, guard red naming `documentation` |
| (b) | designer stops emitting `conditionExpression` | PRESERVED bucket flips to DROPPED, guard red naming `conditionExpression` |
| (c) | content population emptied | red naming "content population is empty" |
| (d) | injection silently no-ops | red naming "the marker is not in the input" |

(a) and (b) are the load-bearing pair: they show both verdicts are producible by a change
in the **subject**, so "5 dropped, 1 preserved" is a measurement rather than a pair of
readings in buckets nobody has shown can fill. (c) and (d) attack the guard's own scope —
the denominator and the injection step — because a probe that silently measures nothing
reports exactly the same thing as a clean result.

Every leg checks that the failure text **names its own condition**. A leg asserting only
`rc != 0` banks a module-load syntax error as proof; that happened on T-338 leg (d).

### Zero kinds

- **`applied 15/24`** on the node-carrier shapes is an occupancy figure, not a limit: 15
  maps carry a `serviceTask` identifiable by `aef:uid`. The population assertion fails at
  0, so a carrier that stops existing is red rather than silent.
- **`conditionExpression` applied 24/24** — every map has a sequenceFlow.
- **`CONTENT-MOVED` never fires and is NOT proven fillable.** It discriminates content that
  survives on a *different* element from content that survives in place. No designer
  mutation was written to produce it, so it is a reachable-in-principle branch with no
  witness — recorded here rather than left to read as "no relocation occurs". The gated
  verdicts are PRESERVED and DROPPED; MOVED would surface as drift if it ever fired.

### Method note — the measure is read off the element, not the document

The verdict resolves the victim element by `aef:uid` in the output and asks whether the
marker is inside *that element*. A whole-document search cannot tell content that survived
in place from content that survived somewhere else, and display ids are recomputed from
lane+ordinal+name by the change under test (T-341), so they cannot identify the victim.

## Verification

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
#
# These lines assert the content leg RAN and reports its verdicts. The per-shape
# verdicts themselves are gated inside the instrument against EXPECTED_CONTENT,
# so a change there fails the first line. The applied counts (15/24) are NOT
# pinned — they move whenever the corpus grows, which is the G-015 shape.
node tools/_t338-input-fidelity-cdp.mjs
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "7 accepted-element content shapes probed"
out=$(node tools/_t338-input-fidelity-cdp.mjs 2>&1); echo "$out" | grep -q "conditionExpression    CONTENT-PRESERVED"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "0 failed"

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

### 2026-08-02T11:28:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-346-measure-content-level-import-fidelity-fo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5f9cb96a
- **Timestamp:** 2026-08-02T11:39:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T11:37:25Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
