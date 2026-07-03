---
id: T-042
name: "Fix inception-review diagram layout congestion"
description: >
  Fix inception-review diagram layout congestion

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
created: 2026-07-03T08:34:50Z
last_update: 2026-07-03T08:34:50Z
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

# T-042: Fix inception-review diagram layout congestion

## Context

Visual (Playwright) testing of the T-041 fidelity-pilot artifact
(`examples/aef-processes/rendered/inception-review.bpmn`) showed it loads with the right
nodes but a **congested, auto-laid-out layout** — end-events crammed left, decision
scriptTasks in a type-ordered row — nothing like the authored coordinates. Investigation
(in-browser `parseBpmnXml` probe) found the **true root cause: a namespace-constant drift
in the editor**. The editor's import/export used `https://aef.anchorpoint.dev/extensions`
while the bridge, validator, golden fixture, and `docs/designer/schema.md` all use the
canonical `http://anchorpoint.framework/aef/extensions`. `byAef` therefore matched **no**
`aef:*` elements on any spec-compliant file → every `aef:uid`/`aef:position` was silently
dropped → the editor auto-laid-out. This affected the **entire corpus and the editor's own
golden fixture**, not just this file. The earlier "coordinate-authoring" hypothesis was
disproved: the golden also auto-laid-out through `parseBpmnXml`. Fix = align the editor's
`aef:` namespace to the spec (both import + export). A secondary coordinate re-spacing of
the YAML (proper lane bands + fan gaps) rides along so the now-honoured layout is legible.

## Acceptance Criteria

### Agent
- [ ] Editor `aef:` namespace aligned to canonical `http://anchorpoint.framework/aef/extensions`
      on **both** import (`parseBpmnXml` AEF_NS) and export (serialize `xmlns:aef`) in
      `src/aef-workflow-designer.html` — `grep -c "aef.anchorpoint.dev/extensions"` returns 0
- [ ] After the fix, `parseBpmnXml` on the corpus BPMN preserves authored `aef:uid` and
      `aef:position` (verified in-browser: uids `n_request`/`n_end_go`… survive, x=1860 honoured)
- [ ] Every node's `y` in `examples/aef-processes/inception-review.workflow.yaml` falls
      inside its lane band (agent[62,262] / framework[262,522] / human[522,722]) and no two
      same-lane boxes overlap — `python3 tools/check-lane-bands.py …` exits 0
- [ ] Bridge re-renders clean + validates + corpus round-trip green
      (`yaml-to-bpmn.py`, `validate-workflow.py`, `tests/run-bridge-tests.sh` all exit 0)
- [ ] Re-rendered diagram Playwright-screenshotted and READ — nodes honour authored
      positions, lanes correctly contain their nodes, no overlap (evidence in ## Visual Verification)

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
grep -c "aef.anchorpoint.dev/extensions" src/aef-workflow-designer.html | grep -qx 0
python3 tools/yaml-to-bpmn.py examples/aef-processes/inception-review.workflow.yaml --out examples/aef-processes/rendered/inception-review.bpmn
python3 tools/validate-workflow.py examples/aef-processes/rendered/inception-review.bpmn
bash tests/run-bridge-tests.sh
python3 tools/check-lane-bands.py examples/aef-processes/inception-review.workflow.yaml

## RCA

**Symptom:** The rendered `inception-review` diagram loaded with the correct nodes but a
congested, auto-laid-out layout — end-events crammed on the left, decision scriptTasks in a
type-ordered row — completely ignoring the authored `aef:position` coordinates.

**Root cause:** A **namespace-constant drift in the editor**. `parseBpmnXml` (import) and
the serializer (export) in `src/aef-workflow-designer.html` used the aef namespace
`https://aef.anchorpoint.dev/extensions`, while the bridge, `tools/validate-workflow.py`,
the golden fixture `tests/fixtures/valid/investigate.bpmn`, and the spec
`docs/designer/schema.md` all use the canonical `http://anchorpoint.framework/aef/extensions`.
`byAef` resolves elements via `getElementsByTagNameNS(AEF_NS, …)`, so with the wrong URI it
matched **zero** `aef:*` elements on any spec-compliant file. Every `aef:uid` and
`aef:position` was silently dropped, and the editor fell through to its `sameLane.length*90`
auto-layout. (The default `investigate` looked fine only because it loads from an embedded
JS object, never through `parseBpmnXml`.)

**Why structurally allowed:** Nothing tested the editor's XML *import* path. The validator
and round-trip suite exercise the bridge and the Python validator (both canonical-NS), but
the editor is a standalone HTML file with no headless test loading a corpus file through
`parseBpmnXml` and asserting positions survive. The two namespaces could — and did — drift
apart undetected. A false "coordinate" hypothesis (my own, initially) nearly sent the fix to
the wrong file; only an in-browser probe of `parseBpmnXml` on the *golden* file (which also
auto-laid-out) revealed the editor as the culprit.

**Prevention:**
1. `grep -c "aef.anchorpoint.dev/extensions" src/aef-workflow-designer.html == 0` in the
   Verification block — pins the editor to the canonical namespace; a future drift fails the gate.
2. `tools/check-lane-bands.py` — pure-structural geometry gate (node in its lane band, no
   same-lane overlap), so authored coordinates that *are* honoured can still be checked
   mechanically rather than only by eye.
3. Follow-up (filed separately): a headless test that loads each corpus `.bpmn` through the
   editor's `parseBpmnXml` and asserts uid/position round-trip — the missing import test.

## Visual Verification

Playwright, editor at `http://127.0.0.1:8010/src/aef-workflow-designer.html`, loaded
`examples/aef-processes/rendered/inception-review.bpmn`:

- `t042-inception-review-fixed.png` — **before the namespace fix**: auto-layout, end-events
  crammed left, decision scriptTasks in a horizontal row, uids auto-generated.
- `t042-inception-review-after-nsfix.png` / `t042-inception-review-fullwidth.png` — **after**:
  authored positions honoured. Three lanes (Initiative/Authority/Sovereignty) each correctly
  contain their nodes; start→fill "re-request review" loop; "Recommendation ready?" and
  "Decision?" gateways; no node overlap; labels legible. Verified by READ, not DOM math.
- Known residual (separate task): the diagram's authored width (~1900px, to x=1860) exceeds
  the canvas viewport, so the go/no-go/defer fan + end-events are clipped off the right edge;
  the canvas does not scroll to them. This is a canvas-fit/zoom concern, not congestion.

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

### 2026-07-03T08:34:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-042-fix-inception-review-diagram-layout-cong.md
- **Context:** Initial task creation
