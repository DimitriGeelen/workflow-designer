---
id: T-313
name: "Lane capacity: a lane whose members outgrow its declared height renders nodes past the band edge"
description: >
  AEF T-2687 (rail 338) found a defect class the lane ORDERING rule is structurally blind to: a lane whose own members span more than its declared height. Order correct, nothing crossing, band simply cannot contain its content. Live instance their side: draft-knowledge-leveling agent lane spans 513px inside height=260, overflow 253px - a SECOND independent defect on the v8 promotion candidate, separate from the two-node authority call. On OUR side this is not merely a lint finding but a VISIBLE RENDER DEFECT: poolHeight sums declared lane heights while nodes draw at their own y, so nodes spill past the band edge. This is a candidate mechanism for the operator screenshot that started T-310 - roughly 14 nodes rendered BELOW every lane band with long trunk edges on a 53-node 5-lane map, with the Clean nudge firing. T-310 explained the membership half but never explained why so many sat below ALL bands; capacity does, and Clean firing fits because cleanLayout (T-125) compacts lanes to exactly the fitting height. UNCONFIRMED against that map - pen_inbound_classifier bytes were never obtained. Measured our side: all 24 rendered corpus maps have ZERO overflowing lanes, because T-101 baked Clean layout in and Clean drives lanes to the fixpoint height == (max botOf - min topOf) + 2*LANE_FIT_MARGIN. So the class arrives via IMPORTED maps authored elsewhere, not from our own corpus. Occupancy is not node height: botOf = y + h(type) + (labelBelow(type) ? 18 : 0), LANE_FIT_MARGIN=12 at both edges. Effective occupancy events 54, gateways 66, tasks 64 - the smallest shapes are not the smallest occupants.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-29T22:44:43Z
last_update: 2026-07-31T07:52:25Z
date_finished: null
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

# T-313: Lane capacity: a lane whose members outgrow its declared height renders nodes past the band edge

## Context

The survivor rule from AEF's retraction (rail 338): ordering compares lanes against
*each other* and is structurally blind to a lane that cannot contain **its own**
members. They shipped it as `tools/corpus_lint.py::lane_overflow` (their T-2689,
23 tests) using the occupancy table we gave them at rail 340. This task builds our
half: the same detection over the BPMN seam form, so an overflowing map is caught
in bytes rather than discovered by eye.

**Deliverable is the DETECTION rule, not the designer repair.** The designer half is
a separate deliverable with a different risk profile (it touches import geometry and
needs visual verification), and the analysis below shows it is not the same defect —
see the two-class split. Filed separately rather than folded in.

**Gate on CONTAINMENT, not on the Clean fixpoint — this divergence is deliberate.**
AEF gate on `extent > height`, strict, so a box whose bottom edge lands exactly ON
the band edge is contained. We gate identically. Their argument, adopted: *"a lint
that reports tidiness as breakage trains people to ignore it."* Two of their lanes
(aef-task-lifecycle agent, aef-inception-flow agent) fit their content while failing
our Clean fixpoint `height == (max botOf − min topOf) + 2*LANE_FIT_MARGIN` — they are
one Clean away from tidy, not broken. Tidiness is already covered our side by the
mapMessiness nudge (T-102), so the validator has no business duplicating it at a
severity that reads as a defect.

> AEF, rail 341: *"If your capacity task gates on the fixpoint instead, our two rules
> will disagree by exactly those two lanes and that will be correct rather than drift
> — worth pinning in both directions so neither of us 'fixes' it later."*

So the divergence gets a **test**, not a comment: a fit-but-untidy lane must NOT fire.

**Occupancy, not height — and the lowest node is found by botOf, not by y.** From
`NODE_DEFAULTS` (src:1759) and `botOf` (src:6975):

    botOf(n) = n.y + h(type) + (labelBelow(type) ? 18 : 0)
    labelBelow = startEvent | endEvent | linkEventThrow | linkEventCatch
               | startsWith('event') | endsWith('Gateway')

Effective occupancy: **events 54, gateways 66, tasks/subProcess 64** — the smallest
shapes are not the smallest occupants. AEF proved the consequence with a fixture:
a gateway at y=199 occupies to 265 while a task at y=200 occupies to 264, so **a
largest-y sort names the wrong node**, and their live `aef-session-lifecycle` case
has a gateway as its lowest node, which a height-only table misses entirely.

**Seam vocabulary bridge (stated, not assumed):** the validator reads BPMN local
tags, not designer palette keys. Our typed/link events serialise to
`intermediateCatchEvent` / `intermediateThrowEvent` / `boundaryEvent`. Collapsing
them for occupancy is safe *specifically* because every event kind in `NODE_DEFAULTS`
is 36 with `labelBelow` true — so the collapse is sound for this rule and would not
be sound for a rule that needed the shape.

**Two classes, and only one of them still renders past the band edge.** The filed
premise needs correcting from source. `parseBpmnXml` reconciles on the node's
CENTRE (src:9823, `laneAtY(n.y + def.h/2) !== n.lane`), so post-T-310:

| | centre in band | centre out of band |
|---|---|---|
| **occupancy past band bottom** | renders SPILLING — invisible to T-310, bounded by h/2 + 18 (this is AEF's 6px session-lifecycle case) | T-310 fires: node yanked to the lane centre |

So an imported overflowing map no longer renders nodes below every band — that
symptom (the operator screenshot) is **pre-T-310 behaviour**. What it does instead
for large overflows is COLLAPSE the lane's out-of-band nodes onto one row, which
fixes membership by destroying an authored layout. That is arguably the wrong repair
for this class: when a lane's own declared members spill past its own bottom edge,
the map is not contradicting itself about *who* — it is under-declaring a height.
Growing the band preserves every authored position; moving the nodes does not.

**Why the repair is a pure height solve exactly when ordering is clean.** Bands tile
the axis contiguously in declaration order from `POOL_Y + POOL_HEADER`, so heights
are the only free variables. A set of heights containing every lane's members exists
iff the lanes' member extents are already ordered and non-overlapping — which is
precisely T-312's `lane_geometry` predicate — and the topmost node is at or below the
origin. Therefore: **ordering-clean ⇒ capacity is repairable with zero node movement
(zero-semantic); ordering-dirty ⇒ capacity cannot be fixed by heights at all and the
repair is an authority call.** The two rules compose; capacity should be read after
ordering, never before.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] A new rule in `tools/validate-workflow.py` reports a lane whose DECLARED members' occupancy extent exceeds its declared `<aef:laneMeta height>`: `extent = max botOf(n) − min topOf(n)` over the lane's `flowNodeRef` members, `botOf = y + occupancy(type)`, `topOf = y`
- [ ] Occupancy is a per-BPMN-tag table derived from the renderer's own constants, NOT node height: events (`startEvent`/`endEvent`/`intermediateCatchEvent`/`intermediateThrowEvent`/`boundaryEvent`) 54, gateways 66, tasks and `subProcess` 64. The 18px below-shape label allowance is what makes a 48px gateway occupy more than a 64px task
- [ ] The lowest-drawn node is selected by **botOf, not by y** — and a test pins AEF's counterexample directly (a gateway at y=199 occupying to 265 beats a task at y=200 occupying to 264), because a largest-y sort is the obvious implementation and names the wrong node there
- [ ] The gate is CONTAINMENT and strict: `extent > height`. A node whose bottom edge lands exactly ON the band edge is contained and must NOT fire
- [ ] The deliberate divergence from the Clean fixpoint is pinned by a TEST, not a comment: a lane with `height >= extent` but `height < extent + 2*LANE_FIT_MARGIN` (fit-but-untidy — one Clean away) must NOT fire. This is the exact set AEF's rule and ours agree to disagree about; a future "consistency fix" in either direction has to delete a named test to do it
- [ ] SKIP, not PASS, on an unevaluable lane, reusing T-312's INFO channel: a lane that declares a height and has members but where any member is unpositioned emits `I-XML-LANE-CAPACITY-SKIP`, with text ending "not passed by it"
- [ ] Scope guard (AEF adopted this from T-312 verbatim; keep it symmetric here): a lane with no members, or with no declared height, makes NO containment claim — out of scope, silent, no note. Without it every hand-authored heightless fixture gains a permanent unresolvable note
- [ ] An unknown BPMN tag SKIPs its lane rather than defaulting to a guessed occupancy, AND a coverage test asserts every flow-node tag our exporter can emit has an occupancy entry — sourced from `src/aef-workflow-designer.html` so the palette cannot grow past the table silently. Silent-skip-forever is the failure mode this exists to prevent
- [ ] The finding names the lane, its declared height, the extent, the spill in px, and the lowest-drawn node with its type and occupancy — enough to act on without opening the map
- [ ] Zero false positives on the clean corpus: all 24 maps in `examples/aef-processes/rendered/` pass, with **0 lanes skipped** (T-101 baked Clean in, so every lane sits at the fixpoint). The zero-skipped half is the load-bearing one — a clean sweep resting on unevaluated lanes is the false green T-312 fixed
- [ ] Teeth (PL-061): proven RED against the pre-change build on every positive fixture, and the test module is shown to fail against it — a rule that only ever passes is not evidence
- [ ] Positive fixtures cover both live shapes AEF measured: a large spill (their knowledge-leveling agent lane, 307px past a 260px band) and a small one whose lowest node is a GATEWAY (their session-lifecycle agent lane, 6px) — the second is the one a height-only table misses
- [ ] Validator suite and bridge suite both stay green (currently 35/0 and 47/0), and the T-312 exception-note count assertion still holds at exactly 3

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

### 2026-07-31 — CHECKPOINT: rule is built and green; 3 named suite failures remain

**State at the budget cut-off (288K, wrap-up gate fired mid-fix). NOT complete.**
The rule itself is implemented and its own test module is **36/36 green**; the
validator suite is **36/0**. The bridge suite is **45/3**, and all three failures
are understood, none is a mystery. Each has a one-edit fix, listed with enough
detail to apply without re-deriving:

1. **`tests/test_t312_lane_geometry.py` — my own test's span boundary, not a code
   defect.** Its origin-free guard extracts the rule body as
   `src[index("def _check_lane_geometry") : index("def _check_iw9_authority")]`.
   `_check_lane_capacity` now sits BETWEEN those two markers, and capacity reads
   `laneMeta/@height` legitimately, so the scan sees a height read inside what it
   believes is the geometry rule. **Fix:** bound the extraction on the next
   `\n    def ` after the start marker instead of on a named later method.
2. **`tests/test_dead_leg_census.py` — a second TRUE POSITIVE on AEF's pinned
   bytes.** `draft-knowledge-leveling-v3` (b82668c8) now also fires
   `W-XML-LANE-CAPACITY` on both lanes. **Fix:** admit the capacity rule into the
   same counted, printed exception the geometry rule already has there (T-314) —
   and raise the T-312 `NOTE (known` count assertion from 3 to 4 in that task's
   Verification block, since the census fixture now prints two notes.
3. **`examples/aef-processes/audit-process.workflow.yaml` — a true positive in our
   OWN source corpus.** Its `framework` lane declares `height: 420` while its
   members need 438 (spill 18). Measured across the whole YAML corpus: **25 maps,
   65 evaluable lanes, exactly 1 overflowing** — this one. Root cause is corpus
   drift, not the rule: the rendered form declares **529** because T-101 baked
   Clean into `rendered/`, but the YAML sources were never re-baked, so the two
   forms have disagreed about this lane's height ever since. **Fix:** set the YAML
   lane height to 462 (its own fixpoint: extent 438 + 2*12); do NOT copy 529,
   which belongs to Clean's re-layout of a different geometry. Check
   `tests/test_forward_fixtures.py` / `test_corpus_fixture_pins.py` for a pin on
   the forward-conversion output first — that check was the next command when the
   budget gate fired and has NOT been run.

- **What changed vs the filing:** the filed premise ("renders nodes past the band
  edge") needed correcting from source, and the correction is in Context — post
  T-310 the large-overflow case COLLAPSES nodes onto the lane centre instead of
  spilling, because reconcile tests the node's CENTRE (src:9823). Only the small
  case (centre in band, occupancy past the bottom edge) still spills. Two classes,
  one filed as one.
- **Plan impact:** none to the ACs; the deliverable stayed the detection rule.
- **Triggered:** the designer-side half is NOT filed yet — see the note below,
  which is the first thing to do next window.

**NOT YET FILED (do this first next window):** the designer-side deliverable.
T-310's import reconcile answers a capacity overflow by moving nodes to the lane
centre, which fixes membership by destroying an authored layout. When a lane's own
declared members spill past its own bottom edge the map is not contradicting
itself about *who* — it is under-declaring a height, and growing the band
preserves every position. The proof that this is always available is in Context:
bands tile the axis, so heights are the only free variable, and a containing set
of heights exists exactly when `lane_geometry` is clean. That is a real behaviour
change to the import path and needs its own task, CDP coverage and visual
verification — it is not a fold-in.

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

### 2026-07-29T22:44:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-313-lane-capacity-a-lane-whose-members-outgr.md
- **Context:** Initial task creation

### 2026-07-31T07:52:25Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
