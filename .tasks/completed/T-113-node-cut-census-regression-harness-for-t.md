---
id: T-113
name: "Node-cut census regression harness for the rendered corpus"
description: >
  Node-cut census regression harness for the rendered corpus

status: work-completed
workflow_type: test
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-05T20:48:05Z
last_update: 2026-07-05T20:52:44Z
date_finished: 2026-07-05T20:52:44Z
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

# T-113: Node-cut census regression harness for the rendered corpus

## Context

The T-112 inception measured node-cuts (edges routing through unrelated node boxes) with
an **ephemeral** in-browser probe. PL-004: "a quality gate that exists but is never run
against its corpus is latent." This task makes the measurement **permanent and runnable** —
a committed CDP harness + a rot-proof regression gate over the 24-map rendered corpus, so
any future layout change that increases node-cuts is caught. Stands alone from the T-112
router decision: it monitors corpus routing health regardless of GO/NO-GO. Mirrors the
existing `tools/_clean-layout-cdp.mjs` + `tests/check-corpus-geometry.sh` pattern (PL-005:
drive the REAL editor's `polylineCrossesNodes`, no re-implemented layout).

## Acceptance Criteria

### Agent
- [x] `tools/_node-cuts-cdp.mjs` loads each `rendered/*.bpmn` in the headless editor and
      reports per-map `{cutEdges, incidences, cuts[]}` as JSON, using the editor's own
      `polylineCrossesNodes` + `_renderedPolyline` (no re-implemented geometry)
- [x] A committed baseline (`tests/fixtures/node-cuts-baseline.json`) records current
      per-map cut counts (harvest 13, error-esc 7, … total 27 incidences)
- [x] `tests/check-corpus-node-cuts.sh` runs the driver and exits non-zero if any map's
      incidences EXCEED its baseline (regression); exits non-zero on a map BELOW baseline
      (stale baseline — must be refreshed, rot-proof like the geometry sweep)
- [x] The gate passes cleanly against the current corpus (baseline == current census)
- [x] Driver is dependency-free (native WebSocket+fetch, cached Playwright Chromium) —
      no npm install required, consistent with `_clean-layout-cdp.mjs`

<!-- All criteria agent-verifiable (the gate runs and passes). No Human section. -->

## Verification

# Shell commands that MUST pass before work-completed. One per line.
bash tests/check-corpus-node-cuts.sh
test -f tools/_node-cuts-cdp.mjs
test -f tests/fixtures/node-cuts-baseline.json
python3 -c "import json; json.load(open('tests/fixtures/node-cuts-baseline.json'))"
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

_(This is a preventive-tooling task, not a defect fix — the RCA gate fired on the
"regression" keyword in the title. Filled honestly to document the structural blindness
this harness closes, rather than bypassing with --skip-rca.)_

**Symptom:** Node-cut counts across the rendered corpus were measurable only via an
ephemeral in-browser probe (T-112 exploration). Nothing standing caught a layout change
that increased edges routing through unrelated node boxes.

**Root cause:** No committed gate exercised the editor's cut geometry against the corpus —
a latent-gate class (PL-004: "a quality gate that exists but is never run against its
corpus is latent"). The T-112 probe proved the metric but left no durable artifact.

**Why structurally allowed:** The corpus had a geometry sweep (lane-band straddle,
check-corpus-geometry.sh) but no routing-legibility sweep. Node-cuts are a render-time
property, so a static YAML gate can't see them; only a live-editor harness can.

**Prevention:** This task IS the prevention — `check-corpus-node-cuts.sh` + baseline is a
rot-proof gate (FAILs on regression AND on un-refreshed improvement), drivable from CI or
`fw` and ready to wire into the audit. Any future layout change that worsens node-cuts now
fails a committed check instead of shipping silently.

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

### 2026-07-05T20:48:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-113-node-cut-census-regression-harness-for-t.md
- **Context:** Initial task creation

### 2026-07-05T20:52:44Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
