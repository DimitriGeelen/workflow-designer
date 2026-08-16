---
id: T-349
name: "Can any T-309 surface ever show the import-loss class (T-347/T-348)?"
description: >
  T-347 and T-348 measured silent loss that happens INSIDE parseBpmnXml, before state
  exists. T-309 is pricing three surfaces (panel / gutter / save-gate) that all read
  from state or from validator findings computed over state. If the loss is invisible
  to all three by construction, that constrains IW-1a/IW-2/IW-3 the same way the three
  parseBpmnXml-repaired ERROR rules already do (rail-393), and the operator should
  know before deciding.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T16:33:08Z
last_update: '2026-08-16T12:33:51Z'
date_finished: 2026-08-02T16:35:29Z
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
---

# T-349: Can any T-309 surface ever show the import-loss class (T-347/T-348)?

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] The input each T-309 surface reads is identified from source: **panel** and
      **gutter** render from `state`; **save-gate** runs over `buildBpmnXml(state)`.
      All three read at or after `state` exists.
- [x] The loss point is located from source, not memory: it occurs **inside**
      `parseBpmnXml` (`src:9595`+). There are **two** `state = loaded` sites —
      `src:9124` (import) and `src:6911` (`_restoreSnapshot`, the undo path) — and both
      are downstream of a `parseBpmnXml` call, so the loss is strictly upstream of every
      route by which `state` is populated, not just the import one.
- [x] Same method applied to all three — each was resolved by asking what it reads,
      not by how closely it was examined.
- [x] **Counter-example attempt made, and it SUCCEEDED** — see below. The honest answer
      is not "no surface can show it" but "none of the three priced surfaces can, and a
      fourth one that is not on the list can".
- [x] Result written into T-309's Inception Windows section, where the pricing decision
      lives.
- [x] No designer source modified.

## Finding

**All three priced surfaces are blind to the entire import-loss class, by construction.**
`parseBpmnXml` drops content before `state` exists; a panel and a gutter render from
`state`; a save-gate evaluates `buildBpmnXml(state)`. Nothing that never entered `state`
can reach any of them, and this is independent of IW-2 (how the rules are delivered) —
porting the rules to JS, calling a sidecar, or sharing a spec all produce the same
blindness, because the problem is *what the surface reads*, not *where the rules run*.

Population affected: T-337 (unknown tags), T-340 (the DI sub-tree), T-347 (5 content
shapes), T-348 (7 root-level shapes) — plus the 3 ERROR rules already known to be
repaired inside `parseBpmnXml`. The last of these was previously recorded in T-309 as a
constraint on IW-1/IW-3; the point of this task is that it was never one rule family, it
was the shape of the whole import path.

## The counter-example succeeded, and that is the result

The AC required naming a mechanism by which the loss *could* reach a surface, rather than
concluding "impossible" from not having thought of one. The attempt found one immediately:

`adoptImportedXml(text, opts)` (`src:9101`) holds the original `text` in scope and calls
`parseBpmnXml(text)` on the next line. **An input-vs-re-export comparison at that instant
would see every loss in the class** — it is precisely what `tools/_t338-input-fidelity-cdp.mjs`
does out-of-band today. The original `text` is discarded when the function returns; nothing
retains it.

So the class is not unreachable. It is reachable by a **fourth surface — an import-time
fidelity report** — which is architecturally unlike the three being priced: no rule engine,
no port-to-JS decision, no severity model, because it compares two documents instead of
evaluating predicates over one. On current evidence it is the only one of the four that
can address this class at all, and it should be priced rather than assumed covered.

**Had the AC not demanded the counter-example, this task would have concluded "no surface
can show it" — which is false, and would have removed the one option worth building.**

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
# This task modifies no source. The claims are structural facts about the import
# path, so the gate checks that the anchors the finding rests on still exist —
# if parseBpmnXml or the state assignment moves, the finding must be re-derived
# rather than silently inherited.

grep -q "^function parseBpmnXml(text) {" src/aef-workflow-designer.html
grep -q "^function adoptImportedXml(text, opts) {" src/aef-workflow-designer.html
out=$(grep -n "state = loaded;" src/aef-workflow-designer.html); test -n "$out"
# adoptImportedXml must still hold the raw text at the call site — that is the
# entire basis for the fourth-surface claim.
out=$(sed -n '/^function adoptImportedXml(text, opts) {/,/^  saveActiveToLibrary();/p' src/aef-workflow-designer.html); echo "$out" | grep -q "parseBpmnXml(text)"
# The finding was written into T-309, where the pricing decision lives.
grep -q "T-349" .tasks/active/T-309-surface-workflow-validator-findings-in-t.md

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

### 2026-08-02T16:33:08Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-349-can-any-t-309-surface-ever-show-the-impo.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-4f4cb111
- **Timestamp:** 2026-08-02T16:35:30Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T16:35:29Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
