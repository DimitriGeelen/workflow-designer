---
id: T-071
name: "Fix: clientToSvg ignores viewBox origin and meet letterbox — cursor-to-model
  conversion skewed"
description: >
  Fix: clientToSvg ignores viewBox origin and meet letterbox — cursor-to-model conversion
  skewed

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
created: 2026-07-04T09:25:53Z
last_update: '2026-08-16T12:33:34Z'
date_finished: 2026-07-04T09:29:18Z
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
  - ts: '2026-08-16T12:33:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-071: Fix: clientToSvg ignores viewBox origin and meet letterbox — cursor-to-model conversion skewed

## Context

Found while verifying T-070's body-drop AC with trusted input: `clientToSvg` converts
cursor coordinates by stretching the viewBox over the element rect — it ignores the
viewBox origin (`vb.x`/`vb.y`) and the `preserveAspectRatio="xMinYMin meet"` letterbox,
so X and Y get different scales. Measured: model centre (375, 592) converted to
(375, 188) — X exact, Y off by 404. Consequences: endpoint-drag body/port snapping
never matches (`nodeAt` misses), and vertical node drags move at the wrong speed
relative to the cursor. Fix: convert through the SVG's real screen CTM
(`svg.getScreenCTM().inverse()`), which accounts for viewBox origin and letterboxing.

## Acceptance Criteria

### Agent
- [x] `clientToSvg` converts via `getScreenCTM().inverse()` (with the corrected old formula as fallback only if CTM is unavailable)
- [x] Round-trip check in the live editor: converting a node shape's on-screen centre yields its model centre within 1px on BOTH axes (measured dx=0, dy=0), and `nodeAt` resolves the node
- [x] Trusted drag of an edge endpoint onto a node body re-anchors the edge (e_01 target n_ready→n_authoring); in middle attach mode the end stays unpinned (`targetPort: "auto"`) — the blocked T-070 AC now verified
- [x] Trusted node drag moves the node by the cursor delta (measured 77.1/48.2 model px = exactly 40/25 CSS px ÷ CTM scale, both axes uniform)
- [x] Inline script passes `node --check`; bridge suite stays 31 passed / 0 failed

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

# T-071 (2026-07-04)
grep -q "getScreenCTM" src/aef-workflow-designer.html
grep -q "matrixTransform(ctm.inverse())" src/aef-workflow-designer.html
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/.t071-editor.js && node --check /tmp/.t071-editor.js
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
python3 -c "import yaml; yaml.safe_load(open('.context/project/concerns.yaml'))"

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

**Symptom:** Endpoint drag-and-drop onto a node never re-anchored (snap silently missed); vertical node drags moved slower than the cursor. Surfaced while verifying T-070's body-drop AC with trusted input — the drop probe showed `nodeAt(clientToSvg(cursor))` resolving to null 404 model-px away from the node.

**Root cause:** `clientToSvg` stretched the viewBox over the element rect per-axis: it dropped the viewBox origin (`vb.x`/`vb.y`) and ignored `preserveAspectRatio="xMinYMin meet"` letterboxing, giving X and Y different scales. X happened to be exact (width was the binding axis, minX≈0), which masked the bug — everything horizontal felt fine while every absolute Y hit-test was skewed.

**Why structurally allowed:** Same gap as T-069 — zero trusted-input interaction coverage (bridge suite = serialization statics, visual protocol = rendered output). Relative drags "worked" because per-event deltas hid the scale error; the absolute-coordinate paths (snap, hover, port distance) simply never matched, and nothing measured them. Second field-found instance of the class in one day → systemic, registered as **G-003** in concerns.yaml per the bug-fix learning checkpoint.

**Prevention:** G-003 tracks the structural fix (trusted-input interaction smoke suite; decision shares G-002's toolchain question — human call). Until then: PL-006 discipline (all pointer-path claims verified with Playwright trusted input) + verification greps pinning the CTM-based conversion.

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

### 2026-07-04T09:25:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-071-fix-clienttosvg-ignores-viewbox-origin-a.md
- **Context:** Initial task creation

### 2026-07-04T09:29:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
