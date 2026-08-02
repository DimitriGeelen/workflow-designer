---
id: T-343
name: "fw fabric enrich silently discards edges whose target has no component card"
description: >
  resolve_edges() drops any detected dependency whose target is unregistered, with no counter and no report. Measured on this repo: 17 edges detected, 2 kept, 15 discarded silently. Consequence: the audit's standing mitigation 'Run: fw fabric enrich' is a no-op on a sparse registry and the operator cannot distinguish 'nothing to add' from '15 discarded'.

status: captured
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
created: 2026-08-02T11:15:44Z
last_update: 2026-08-02T11:15:44Z
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
- [ ] `fw fabric enrich` reports the number of detected edges discarded for want of a
      registered target, distinctly from edges added, in both normal and `--dry-run` mode.
- [ ] The report names the unregistered targets (at least under `--verbose`) so the
      operator can act on it — a bare count restates the problem without locating it.
- [ ] A zero in the new counter is distinguishable from the counter never running:
      the summary line is emitted unconditionally, not only when the count is non-zero.
- [ ] Teeth: with the repo's real cards, the new counter reads **15**; a leg that
      registers a card for one dropped target reduces it and increases edges added, and
      the leg fails if the two do not move together.
- [ ] No change to which edges are written — this is a reporting fix, not a behaviour
      change. Card contents byte-identical before/after on a `--dry-run`-then-run pair.
- [ ] Change is confined to `.agentic-framework/` and recorded for upstream to AEF per G-008.

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

**Prevention:** the counter itself, plus the teeth leg above — a guard that proves the
discarded count is *fillable* rather than merely reading zero.

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

### 2026-08-02T11:15:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-343-fw-fabric-enrich-silently-discards-edges.md
- **Context:** Initial task creation
