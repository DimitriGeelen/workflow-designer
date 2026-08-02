---
id: T-343
name: "fw fabric enrich silently discards edges whose target has no component card"
description: >
  resolve_edges() drops any detected dependency whose target is unregistered, with no counter and no report. Measured on this repo: 17 edges detected, 2 kept, 15 discarded silently. Consequence: the audit's standing mitigation 'Run: fw fabric enrich' is a no-op on a sparse registry and the operator cannot distinguish 'nothing to add' from '15 discarded'.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t342-fabric-edge-drop-probe.py, tools/_t343-write-equivalence.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T11:15:44Z
last_update: 2026-08-02T12:43:53Z
date_finished: 2026-08-02T12:43:45Z
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

# T-343: fw fabric enrich silently discards edges whose target has no component card

## Context

Found by T-342. `.agentic-framework/agents/fabric/lib/enrich.py:655` —

```python
target_id = loc_to_id.get(loc)
if not target_id:
    continue
```

An edge whose target has no component card is discarded with no counter, no
`--verbose` line, and no effect on the summary. Enrichment can therefore only ever
draw edges *inside* the already-registered set.

Measured over this repo's 15 cards, by wrapping enrich's own `resolve_edges` rather
than reimplementing it (probe: `scratchpad/t342/rawvsresolved.py`):

| | count |
|---|---|
| raw edges DETECTED (already existence-guarded against disk) | **17** |
| surviving resolution | **2** |
| **discarded silently** | **15** |

Every discarded target is a real file: `tools/validate-workflow.py` (×3),
`tools/yaml-to-bpmn.py` (×3), `src/aef-workflow-designer.html` (×2),
`docs/standards/aef-bpmn-mapping-v1.md`, and several fixtures. These are among the
most-depended-on files in the repo; none has a card.

Consequence: the audit has printed `Run: fw fabric enrich` as its sole PRIORITY
ACTION at every audit for 14 days. Running it prints `Cards enriched: 0 / Forward
edges: 0` — which is indistinguishable, on the operator's screen, from "there was
nothing to add". The remedy cannot move the metric it is prescribed for, and nothing
in its output says why.

This is vendored framework code — G-008 (fix in-tree, upstream to AEF) applies.

## Acceptance Criteria

### Agent
- [x] `fw fabric enrich` reports the number of detected edges discarded for want of a
      registered target, distinctly from edges added, in both normal and `--dry-run` mode.
- [x] The report names the unregistered targets (at least under `--verbose`) so the
      operator can act on it — a bare count restates the problem without locating it.
- [x] A zero in the new counter is distinguishable from the counter never running:
      the summary line is emitted unconditionally, not only when the count is non-zero.
- [x] **(AMENDED — see Evolution.)** Teeth: the new counter is non-zero on this repo's
      real cards and equals an independently-computed measurement of the same drop; a leg
      that registers a card for a currently-discarded target makes the count **fall** and
      edges-added **rise**, and fails if the two do not move together. No literal count is
      asserted anywhere in the teeth or the verification block.
- [x] No change to which edges are written — this is a reporting fix, not a behaviour
      change. Proven by running the pre-change and post-change builds from the same
      starting state **in a configuration where enrich actually writes**, and comparing
      the resulting card trees.
- [x] Change is confined to `.agentic-framework/` (plus the T-342 probe that monkey-patches
      the changed function) and recorded for upstream to AEF per G-008.

### Counting the right thing (recorded before the fix, not after)

`resolve_edges` drops for **three** reasons — unregistered target, self-edge, duplicate
`(target, type)`. T-342 measured `len(raw) − len(resolved)` and attributed the whole
difference to "want of a card". Decomposed before writing any fix:

| drop arm | count |
|---|---|
| target UNREGISTERED | **17** |
| SELF edge | 0 |
| DUPLICATE (target, type) | 0 |

The attribution was right *in kind*, but only because the other two arms happen to be
empty here — an **occupancy** zero, not a construction one. The new counter therefore
collects the unregistered arm **only**; the other two are genuine non-results and are
deliberately not counted. Had they been non-zero, the headline number would have been
reporting three different facts under one name.

## RCA

**Symptom:** the audit's standing mitigation `Run: fw fabric enrich` produces
`0 enriched, 0 edges` and has done so at 13 consecutive audits.

**Root cause:** `resolve_edges` silently drops edges to unregistered targets. On a
sparse registry (15 cards over a 115-file source tree) that is nearly all of them —
15 of 17 here.

**Why structurally allowed:** the drop is a bare `continue` on a `dict.get` miss. A
lookup miss is being used to mean "not a dependency", when it actually means "not yet
registered" — the two are not the same and only one of them is a result. Nothing
counts the discarded set, so the failure is reported as a clean zero. Same class as
[[absence-cannot-carry-a-decision]].

**Prevention:** the counter itself, plus the teeth legs above — the summary line is
emitted *unconditionally*, so a zero renders as `Edges discarded: 0` rather than as an
absent line. Leg (d) proves that matters: making the line conditional on a non-zero count
turns a zero back into silence, which is the original defect in a new costume.

## Evidence

### What the operator saw, before and after

Same repo, same cards, same run:

```
before                                after
------                                -----
Cards enriched:    0                  Cards enriched:    0
Forward edges:     0  (depends_on)    Forward edges:     0  (depends_on)
Reverse edges:     0  (depended_by)   Reverse edges:     0  (depended_by)
Total edges added: 0                  Total edges added: 0
                                      Edges discarded:   17  (target has no
                                        component card; 10 distinct targets)
                                        (re-run with --verbose to list them)
```

The `0`s are unchanged and correct. What changed is that they are no longer the *whole*
report — the run that produced them discarded 17 detected edges to get there.

Under `--verbose`, the targets are named, and the naming immediately earns its keep:

```
  4x  [file] tools/validate-workflow.py
  4x  [file] tools/yaml-to-bpmn.py
  2x  [file] src/aef-workflow-designer.html
  1x  [file] .agentic-framework/agents/fabric/lib/enrich.py
  1x  [dir ] .fabric/components
  1x  [file] docs/standards/aef-bpmn-mapping-v1.md
  1x  [dir ] examples/aef-processes
  1x  [dir ] tests
  1x  [file] tests/fixtures/valid/gw-single-default.xml
  1x  [file] tests/fixtures/warn/W-XML-GW-AMBIGUOUS.xml
```

**3 of the 10 are directories**, which can never hold a component card. A bare count
would have told the operator to go register ten things; only seven are registerable.
That distinction exists only because the report names its members.

### Teeth — 7/7

| leg | mutation | required failure |
|---|---|---|
| baseline | none | counter present AND non-zero |
| baseline | none | internal counter **agrees** with the independent T-342 probe |
| (a) SUBJECT | register a card for a discarded target | count falls (17→14) **and** edges-added rises (0→4) **together** |
| (a) cleanup | remove it again | both return to baseline |
| (b) ZERO FILLABLE | run over a card whose edges all resolve | line still printed, reading `0` |
| (c) SCOPE | neuter the collection inside `compute_forward_edges` | counter reads 0 while the probe still reads 17 |
| (d) SCOPE | make the summary line conditional on non-zero | a zero becomes an **absent line** |

Leg (c) is the one that makes the baseline agreement mean anything. Two numbers agreeing
is evidence only if both could have disagreed ([[corroboration-from-a-constant]]); (c)
produces the disagreement on demand, so the baseline match is a measurement rather than
two views of one constant.

Leg (a) does **not** assert the fall equals the target's share. Registering
`tools/validate-workflow.py` resolves its 4 edges but also introduces a new card that is
itself scanned and contributes its own discards — net 17→14, not 17→13. The leg asserts
the two counters move *together*, which is the property; the arithmetic is not.

### The write-equivalence check had to be re-run to mean anything

First attempt compared card-tree shas before/after with the stock registry and reported
`identical: YES`. That result was worthless: enrich writes **nothing** in that state
(0 cards enriched), so the shas would have matched even if the change had broken
edge-writing outright — a check that discriminates nothing. Re-run with a card registered
so enrich genuinely writes (**5 cards enriched, 4 forward + 4 reverse edges**), the
pre-change and post-change builds produce **byte-identical card trees** and identical
edge accounting. That version could have failed.

### Note on the T-342 probe's own label

The probe prints `ZERO KIND: OCCUPANCY — edges were detected and discarded for want of a
card.` That attribution is correct at this reading but is **not something the probe can
justify** — it measures a difference that spans all three drop arms. It is left as-is
deliberately: its difference-based number is what makes it an independent cross-check for
leg (c), and decomposing it would collapse it into the thing it is checking.

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
#
# G-015 note: NO literal edge/card count appears below. The discarded count moved
# 15 -> 17 within a day of filing purely because a card was registered elsewhere.
# Every line here asserts a PROPERTY of the report, not a value of the repo.

# 1. The summary line is emitted at all, and unconditionally (a zero must render as "0",
#    not as an absent line — that absence is the original defect).
out=$(.agentic-framework/bin/fw fabric enrich --dry-run 2>&1); echo "$out" | grep -q "^Edges discarded:"

# 2. enrich's internal per-arm counter agrees with the T-342 probe's independently
#    computed difference-based measurement of the same drop. Both are re-measured on
#    every run; neither number is pinned.
a=$(.agentic-framework/bin/fw fabric enrich --dry-run 2>&1 | sed -n 's/^Edges discarded: *\([0-9]*\).*/\1/p'); b=$(python3 tools/_t342-fabric-edge-drop-probe.py 2>&1 | sed -n 's/.*dropped at resolution *: *\([0-9]*\).*/\1/p'); test -n "$a" && test -n "$b" && test "$a" = "$b"

# 3. When the count is non-zero the targets are NAMED (a bare count relocates the
#    problem without locating it). When it is zero this passes trivially — the check
#    must not decay into a red the day the registry is complete.
out=$(.agentic-framework/bin/fw fabric enrich --dry-run --verbose 2>&1); n=$(echo "$out" | sed -n 's/^Edges discarded: *\([0-9]*\).*/\1/p'); if [ "${n:-0}" -gt 0 ]; then echo "$out" | grep -q "Discarded edges"; fi

# 4. Reporting-only: enrich still writes exactly what it wrote before. Compared against
#    the pre-change build from git in a configuration where enrich actually writes.
python3 tools/_t343-write-equivalence.py

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

### 2026-08-02 — the AC I wrote at filing was already stale when I came to tick it

- **What changed:** AC 4 originally read *"with the repo's real cards, the new counter
  reads **15**"*. By the time the fix was built it read **17** — not because anything
  regressed, but because I had registered one component card for the T-342 probe in the
  meantime, and that card is itself scanned and contributes its own unresolved edges.
- **Plan impact:** the AC was a currently-true global pinned into a per-task gate — the
  **G-015 subject error**, committed by me, in a task filed *by* the window that
  registered G-015. A verification line built on it would have gone red on the next card
  anyone registers, and "someone registered a card" would have been indistinguishable
  from "the counter broke".
- **Triggered:** AC 4 amended in place to assert the *property* (non-zero; agrees with an
  independent measurement; falls when a target is registered, together with edges-added
  rising) rather than any literal. No count appears in the teeth or the verification
  block. Second cousin of [[acs-ticked-from-the-plan]]: there the enumeration rotted,
  here the integer did.

### 2026-08-02 — a teeth leg failed for the wrong reason, three lines below the comment warning about it

- **What changed:** leg (d) failed on first run. The subject was fine; the leg invoked the
  *unmutated* `enrich.py` instead of its mutated copy, so it measured nothing. The
  docstring immediately above it cites T-338 leg (d) — a leg that went red for the wrong
  reason — as the mistake being guarded against.
- **Plan impact:** none to the fix; the leg was corrected and passes.
- **Triggered:** worth stating plainly rather than quietly fixing — writing the warning
  down does not stop the hand from making the error. What caught it was that the leg's
  *detail line* prints what it actually observed (`line_absent_on_zero=False`), so a
  wrong-reason red was legible as one. Legs that print only PASS/FAIL would have sent me
  to debug working code.

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

### 2026-08-02T11:15:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-343-fw-fabric-enrich-silently-discards-edges.md
- **Context:** Initial task creation

### 2026-08-02T12:34:07Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-9f1463d1
- **Timestamp:** 2026-08-02T12:43:47Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 48
     - evidence: `out=$(.agentic-framework/bin/fw fabric enrich --dry-run --verbose 2>&1); n=$(echo "$out" | sed -n 's/^Edges discarded: *\([0-9]*\).*/\1/p'); if [ "${n:-0}" -gt 0 ]; then echo "$out" | grep -q "Discard`

### 2026-08-02T12:43:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
