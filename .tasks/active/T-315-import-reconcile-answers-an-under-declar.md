---
id: T-315
name: "Import reconcile answers an under-declared lane height by moving nodes; growing the band preserves the authored layout"
description: >
  Import reconcile answers an under-declared lane height by moving nodes; growing the band preserves the authored layout

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
created: 2026-07-31T08:44:51Z
last_update: 2026-07-31T08:44:51Z
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

# T-315: Import reconcile answers an under-declared lane height by moving nodes; growing the band preserves the authored layout

## Context

T-313 built the DETECTION half (`W-XML-LANE-CAPACITY`): a lane whose declared
members' occupancy extent exceeds its declared `<aef:laneMeta height>`. This task
is the designer half — what the editor should DO about such a map on import.

**What it does today, and why that is the wrong repair for this class.** T-310's
import reconcile (src ~9823) tests each node's CENTRE against the band it lands in:

    if (findLane(n.lane) && laneAtY(n.y + def.h / 2) !== n.lane) → n.y = laneCenterY(n.lane)

That is the right answer when the map contradicts itself about **who** — a node
declared in lane A but drawn inside lane B's band. It is the wrong answer when the
map does not disagree about ownership at all: when a lane's own declared members
simply spill past its own bottom edge, the defect is an **under-declared height**.
There, moving the nodes fixes the symptom by destroying an authored layout, when
growing the band preserves every position and changes no semantics whatsoever.

**Why the two cases separate cleanly — this is T-313's composition result, not a
heuristic.** Bands tile the axis contiguously in declaration order from
`POOL_Y + POOL_HEADER`, so heights are the only free variable. A set of heights
that contains every lane's members exists **exactly when** the lanes are
ordering-clean (`lane_geometry`). So:

| | ordering-clean | ordering-dirty |
|---|---|---|
| **lane over-spills its height** | a pure height solve exists — grow the band, move nothing | no set of heights can fix it; it is a real membership/authority conflict |

The rule therefore has a precondition it can actually test, not a guess.

**Governance: this must not move the ground under T-310's open operator review.**
T-310 is partial-complete with three unchecked `[REVIEW]` ACs, and the second one
asks the operator precisely: *"is 'declared membership wins' the right default?"*,
offering them the binary **move the node** vs **flag it and keep the pixels**.
T-315 is a third option they were never shown — for the height subclass only,
neither move nor merely flag, but **grow the band**, which satisfies both horns.

That question stays theirs. This task must not pre-empt it, and provably does not:
the fixture the operator is asked to load, `lane-position-conflict.bpmn`, is a
two-node SWAP — ordering-dirty — and by the composition result above no lane height
can repair it. So the review fixture's behaviour is untouched by construction, and
an AC pins that as an observed fact rather than an argument. What this change does
is strictly REMOVE cases from the moved-nodes set: maps that were only ever
mis-drawn because a band was too short.

**Do not compute the fix from cumulative band boundaries.** T-312's origin-freeness
trap applies in reverse here: the growth amount comes from the lane's OWN members
(`extent` vs declared `height`), never from reconstructed band edges. Growing lane
*i* moves every boundary below it, so the pass must resize all lanes from their own
members BEFORE any node is tested against a band — resize-then-reconcile, never
interleaved.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] On import, a lane whose declared members' extent exceeds its declared height has its height grown to the Clean fixpoint (`extent + 2*LANE_FIT_MARGIN`) **before** the T-310 centre-test reconcile runs, so nodes that were only out-of-band because the band was too short are never moved
- [ ] The growth pass is gated on the map being ordering-clean (T-312's `lane_geometry` predicate, evaluated in-editor over declared lane membership). On an ordering-dirty map it does nothing and T-310's reconcile behaves exactly as it does today — the composition result, enforced in code rather than assumed
- [ ] The growth amount is derived from the lane's own members only (`max botOf − min topOf`), never from reconstructed band boundaries; all lanes are resized before any node is tested against a band (resize-then-reconcile, not interleaved)
- [ ] **T-310's open-review fixture is provably unaffected:** loading `tests/fixtures/aef-bpmn/lane-position-conflict.bpmn` produces byte-identical node positions, the same "2 nodes moved back" notice, and identical lane heights before and after this change — pinned by a CDP assertion, not by inspection
- [ ] A map that is ordering-clean and has an under-declared lane loads with **zero** nodes moved and the lane grown instead — verified on `tests/fixtures/aef-bpmn/lane-capacity-large-spill.bpmn` (agent lane h=260, extent 567), whose four node y-values are unchanged after load
- [ ] Round-trip safety: re-exporting a map whose lanes were grown emits the NEW heights and otherwise byte-identical bytes — the grown height is a real edit to the model, not a render-time fudge that silently reverts on save
- [ ] The operator is told what happened, in the same notice channel T-310 uses: a map whose bands were grown says so, with the lane name(s) and the growth in px — a silent geometry change on load is the failure mode this AC exists to prevent
- [ ] Teeth (PL-061): every new CDP assertion is shown RED against the pre-change build — a rule that only ever passes is not evidence
- [ ] Existing suites stay green: bridge 48/0, validator 36/0, geometry sweep 24 clean, and the T-312 counted-tolerance note count still exactly 5
- [ ] Visual verification (CLAUDE.md §Visual Verification for UI Changes): element-level screenshots of the canvas after loading both fixtures, READ with the Read tool, confirming grown bands contain their nodes and no node sits past a band edge — DOM-rect math alone does not close this

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

### 2026-07-31T08:44:51Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-315-import-reconcile-answers-an-under-declar.md
- **Context:** Initial task creation
