---
id: T-342
name: "Measure whether the audit's standing fabric mitigation can move the metric it prescribes"
description: >
  The audit has printed 'Run: fw fabric enrich' as its sole priority action for 13 consecutive audits against WARN 'Fabric: 11/15 cards have no edges'. Running it enriches 0 cards and adds 0 edges. Measure whether that zero is construction or occupancy, and establish what the coverage denominator actually is.

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: [tools/_t342-fabric-edge-drop-probe.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T11:08:08Z
last_update: 2026-08-02T11:24:29Z
date_finished: 2026-08-02T11:24:29Z
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

# T-342: Measure whether the audit's standing fabric mitigation can move the metric it prescribes

## Context

`fw audit` has emitted the same single PRIORITY ACTION — `Run: fw fabric enrich` — at every
audit for 14 days (13 audits + today), against `[WARN] Fabric: 11/15 cards have no edges`.
Running it processes 15 cards and reports **0 enriched, 0 forward edges, 0 reverse edges**.
A remedy that cannot move the metric it is prescribed for is indistinguishable, on the
operator's screen, from a remedy nobody has got round to running — the same shape as
G-015 (a permanently-red gate reads as "the human has not looked yet") and as the
T-178 verification lines.

Mechanism already read in source: `resolve_edges` (`.agentic-framework/agents/fabric/lib/enrich.py:655`)
does `target_id = loc_to_id.get(loc); if not target_id: continue` — an edge whose target
has no component card is dropped with no counter and no report. So enrichment can only
ever draw edges *inside* the registered set.

This task MEASURES; it does not fix. Anything found is filed per "one bug = one task",
and any repair that is a convention change rather than a defect is left to the operator.

Predecessors: T-339 (spun off T-340/T-341 the same way), G-015, G-016.

## Acceptance Criteria

### Agent
- [x] The zero's KIND is established by measurement, not inference: enrich's own detectors
      are run over the same 15 cards and the count of edges **detected before resolution**
      is reported alongside the count **surviving resolution**. A detected>0 / resolved=0
      split proves the zero is a drop (occupancy of the registry); detected=0 proves it is
      construction (the files genuinely have no detectable dependencies).
- [x] The coverage denominator is stated explicitly: what set the audit's
      `Fabric: N registered, 0 unregistered` and `drift: All watched source files registered`
      actually range over, and whether the "unregistered" count is capable of being non-zero.
      If the watch set is derived from the registered set, that is recorded as a
      denominator answerable only to itself, with the source line that makes it so.
- [x] Every distinct defect found is filed as its own task with its own root cause, and
      none is fixed under this task ID.
- [x] Any zero reported in the findings names its kind (construction vs occupancy) in the
      same sentence, per the standing rule on this arc.
- [x] The measurement is reproducible from the repo — either a committed instrument or a
      probe whose exact commands are recorded in `## Evidence` — and its result is stated
      with the population it ranged over.
- [x] Existing gating suites stay green (bridge suite `0 failed`); no vendored framework
      file is modified under this task.

## Evidence` — and its result is stated
      with the population it ranged over.
- [x] Existing gating suites stay green (bridge suite `0 failed`); no vendored framework
      file is modified under this task.

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

The mitigation cannot move the metric. Three independent causes, all measured:

| # | Finding | Measured | Filed |
|---|---|---|---|
| A | `enrich` discards edges to unregistered targets silently | 17 detected → 2 kept, **15 dropped**, no counter | T-343 |
| B | `.fabric/watch-patterns.yaml` is the untailored default | expands to **0 files**; real source population **115**, carded **15** | T-344 |
| C | audit's first fabric check is a broken duplicate of its own sibling | printed `0 unregistered` **[PASS]** in the same run its sibling printed `49 ... no fabric card` **[WARN]** | T-345 |

**Zero kinds.** Every zero above is an **occupancy** zero, not construction, and each was
proven fillable rather than asserted:
- A's zero fills when a target is registered — the 15 discarded targets are real files on
  disk (the detectors are existence-guarded before resolution ever runs).
- B's zero fills under a matching pattern set — the *same* expander returns 17 files for
  `tools/**/*.py` + `src/**/*.html`, so the 0 is the patterns, not the expander.
- C's zero does not fill at all: it is structurally constant. That is the finding.

### Commands

```bash
cd /opt/832-Workflow-designer && PROJECT_ROOT=/opt/832-Workflow-designer python3 tools/_t342-fabric-edge-drop-probe.py
cd /opt/832-Workflow-designer && python3 .agentic-framework/agents/fabric/lib/expand_patterns.py .fabric/watch-patterns.yaml /opt/832-Workflow-designer | wc -l    # -> 0
cd /opt/832-Workflow-designer && git ls-files | grep -Ev '^\.agentic-framework' | grep -E '\.(py|sh|mjs|js|html|ts)$' | wc -l                                        # -> 115
```

C was reproduced end-to-end against the real audit by temporarily widening
`.fabric/watch-patterns.yaml` to `tools/**/*.py`, `tests/**/*.py`, `src/**/*.html`, running
`fw audit --section structure --output <scratch>`, and reverting with `git checkout --`.
Output written to scratch so the tracked audit file was never touched; working tree
confirmed clean immediately after.

### Method notes

**The probe wraps enrich's own `resolve_edges` rather than reimplementing the detector
dispatch.** A probe that re-derives the logic it is measuring can diverge from it, and then
reports on its copy. Cards producing zero raw edges never reach `resolve_edges` at all
(`if not raw_edges: continue` precedes it), so those are recovered by difference rather
than assumed.

**Reading the branch gave the weaker half of C.** From source I predicted the defect was
"both verdict arms call `pass()`, so the metric has no failing state". True, but not the
operative mechanism: the run showed the check reports `0` even when 49 files are
unregistered, because its glob is `glob.glob(p['glob'])` — no `PROJECT_ROOT` join and no
`recursive=True`, while the correct sibling at `:1499` has both. Had I filed on the reading
alone, the fix would have addressed the severity of a number that is structurally zero.

**What I did not do.** None of the three is fixed here, and the two that change what the
operator sees at every audit (B, C) are `owner: human`. A and C are vendored framework code
(G-008: fix in-tree, upstream to AEF). The ordering matters and is recorded in both tasks:
**C must land before or with B** — tailoring the patterns while the duplicate check still
reports a constant zero makes the audit print two contradictory fabric lines side by side,
which is precisely the output the reproduction above produced.

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
# NOTE: these lines deliberately assert the probe RUNS and reports its figures.
# They do NOT pin the figures themselves (15 dropped, 0 expansion, 115 sources).
# Those are the very numbers T-343/T-344 exist to change, and pinning a
# currently-true global into a per-task gate is the G-015 subject error this
# project already carries 75 instances of.
PROJECT_ROOT=/opt/832-Workflow-designer python3 tools/_t342-fabric-edge-drop-probe.py
out=$(PROJECT_ROOT=/opt/832-Workflow-designer python3 tools/_t342-fabric-edge-drop-probe.py 2>&1); echo "$out" | grep -q "raw edges DETECTED"
out=$(PROJECT_ROOT=/opt/832-Workflow-designer python3 tools/_t342-fabric-edge-drop-probe.py 2>&1); echo "$out" | grep -q "ZERO KIND:"
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

### 2026-08-02T11:08:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-342-measure-whether-the-audits-standing-fabr.md
- **Context:** Initial task creation

### 2026-08-02T11:08:15Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-d0a26452
- **Timestamp:** 2026-08-02T11:25:55Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T11:24:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
