---
id: T-051
name: "Re-validate + fix geometry of pre-convention corpus maps against lane-band
  gate"
description: >
  Eight older maps (arc-lifecycle, assumption-validation, audit-process, inception-lifecycle,
  session-handover, task-lifecycle, tier0-escalation, upgrade-process) predate the
  tightened T-042/T-043 lane-band convention and fail tools/check-lane-bands.py (nodes
  straddle lane bands). Independent of T-050. Re-lay-out each to satisfy the geometry
  gate; add all corpus maps to a CI geometry sweep so the gate can never silently
  drift past authored maps again.

status: work-completed
workflow_type: refactor
owner: agent
horizon:
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-03T13:15:05Z
last_update: '2026-08-16T12:33:33Z'
date_finished: 2026-07-03T13:43:19Z
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
  - ts: '2026-08-16T12:33:33Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-051: Re-validate + fix geometry of pre-convention corpus maps against lane-band gate

## Context

Eight pre-convention maps (arc-lifecycle, assumption-validation, audit-process,
inception-lifecycle, session-handover, task-lifecycle, tier0-escalation,
upgrade-process) were authored before the lane-band convention was tightened; their
nodes are tagged with one lane but positioned in an adjacent band, so
`tools/check-lane-bands.py` reports straddles. Registered from T-050; gated (but not
blocked) by the T-052 sweep allowlist. Fix each map so every node's y-box sits inside
its assigned lane band, preserving the authored flow/semantics (reposition drifted
nodes into their band; reassign a lane only where the node semantically belongs
there). As each map passes, remove it from the T-052 sweep's LEGACY allowlist so the
sweep's stale-detection stays satisfied.

## Acceptance Criteria

### Agent
- [x] All 8 listed maps pass `tools/check-lane-bands.py` (exit 0 — no straddle, no
      same-lane overlap)
- [x] Each fixed map still validates clean and round-trips (YAML→BPMN→validator) via
      the bridge suite — no semantic/schema regression from the layout edits
- [x] Every fixed map is removed from the LEGACY allowlist in
      `tests/check-corpus-geometry.sh`; the sweep reports 0 known-legacy, 0 stale
- [x] Full bridge suite (`tests/run-bridge-tests.sh`) exits 0 with all corpus maps
      geometry-clean (no allowlist remaining)
- [x] Re-laid-out maps render legibly: the 3 highest-risk (assumption-validation
      lane-crossing spine, audit-process squeezed fan, inception-lifecycle branch
      stack) Playwright-rendered and screenshots READ; the other 5 (simple single-band
      clamps) load error-free with content fully inside the viewBox — see
      ## Visual Verification. (Geometry gate guarantees in-band + non-overlap for all 8.)

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

# Every corpus map is geometry-clean with NO legacy allowlist remaining
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "0 known-legacy, 0 new-fail, 0 stale"
# Full bridge suite green
bash tests/run-bridge-tests.sh

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

**Symptom:** 8 corpus maps rendered with nodes straddling their lane bands (nodes
tagged one lane but positioned in an adjacent band); `tools/check-lane-bands.py`
reported straddles/overlaps on all 8.

**Root cause:** the maps were authored (T-031-era) before the lane-band geometry
convention (T-042/T-043) was established. Their eyeballed node placements never
matched the later-tightened band model, and nothing re-validated already-authored
maps against the new gate.

**Why structurally allowed:** the geometry gate existed but was never run over the
corpus — a gate that passes by never executing (the T-050/T-052 G-019 blindness). New
maps authored to convention passed; legacy maps silently drifted out of compliance
with no CI check pointing at them.

**Prevention:** T-052 wired `tests/check-corpus-geometry.sh` into the bridge suite,
running the gate over EVERY corpus map with stale-allowlist detection. With T-051's
re-layout the allowlist is now empty, so any future straddle in any map — legacy or
new — fails the suite. Captured as [[PL-004]] (a gate never run against its subject is
latent blindness).

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

## Visual Verification

Served the editor over HTTP; for each map, converted YAML→BPMN (yaml-to-bpmn.py) and
loaded it via `parseBpmnXml` + `renderAll` in Playwright.

**3 highest-risk re-layouts — screenshot READ:**
- **assumption-validation** (biggest change — spine tagged across two lanes): agent
  steps (identify → gather → assess) now sit in the Agent·Initiative band, framework
  recording + supported/refuted branches in the Framework·Authority band. Renders
  legibly; the lane-crossing edges correctly show initiative→authority handoffs, no
  overlap, no clipping.
- **audit-process** (squeezed fan): n_discovery placed as the 3rd branch in the
  fork→join fan (y=314, the clean gap between traceability@250 and enforcement@380);
  all 5 branches distinct, 3-way FAIL/WARN/PASS outcome clear.
- **inception-lifecycle** (branch stack): go/no-go/defer decision correctly in the
  Human·Sovereignty lane; the 3 outcome branch-pairs top-aligned, no overlap.

**Other 5 (simple single-band clamps) — load-verified:** session-handover,
task-lifecycle, arc-lifecycle, tier0-escalation, upgrade-process all load error-free
with `svg.getBBox()` content fully inside the viewBox (no clip). Geometry gate
guarantees in-band + non-overlap for these.

**Console:** 0 JS errors across all 8 loads (only harmless favicon 404s).

## Decisions

### 2026-07-03 — how to fix straddling nodes
- **Chose:** reposition drifted nodes into their assigned lane band (preserving the
  authored flow), and for assumption-validation honor the lane tags — move the
  agent-tagged spine into the Agent band rather than retag it framework.
- **Why:** the lane assignment encodes *authority* (the whole point of these maps);
  honoring it produces the faithful authority-handoff view. Repositioning keeps the
  above/below-spine branch idiom the authors intended, just pulled inside the band.
- **Rejected:** retagging spine nodes to match their drifted position (would falsify
  who-does-what); growing lane heights to enclose out-of-band nodes (cascades band
  shifts onto adjacent lanes' nodes — more disruptive, not less).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-03T13:15:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-051-re-validate--fix-geometry-of-pre-convent.md
- **Context:** Initial task creation

### 2026-07-03T13:18:44Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-07-03T13:19:46Z — status-update [task-update-agent]
- **Change:** horizon: now → later

### 2026-07-03T13:30:29Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: later → now (auto-sync)

### 2026-07-03T13:43:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
