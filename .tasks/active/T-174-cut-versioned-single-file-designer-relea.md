---
id: T-174
name: "Cut versioned single-file designer release + release mechanism (phase-1, AEF integration)"
description: >
  832-side deliverable of T-173 GO: publish a versioned, pinnable single-file designer build that AEF vendors; document the pull (re-pin) and upstream-improvement paths.

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
created: 2026-07-10T09:56:33Z
last_update: 2026-07-10T09:56:33Z
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

# T-174: Cut versioned single-file designer release + release mechanism (phase-1, AEF integration)

## Context

832-side build authorised by the **T-173 GO** (2026-07-10, mechanism M3 + `fw designer`, phase-1 unit =
single-file editor). See `docs/reports/T-173-aef-integration-inception.md` (Joint recommendation + IW-6
bidirectional flow). Deliverable: 832 publishes a **versioned, pinnable single-file build** of the
designer (`src/aef-workflow-designer.html`) that AEF vendors as a pinned copy and serves via `fw
designer`. Must document **both** flow directions (IW-6): PULL = AEF re-pins a new 832 release;
IMPROVEMENTS = AEF files upstream to 832 via the cross-agent channel, never patching its vendored copy.

**Cross-repo dependency:** the AEF side (`fw designer` route) is a **separate task on the AEF repo**,
owned by the AEF agent (`aef` / `/opt/999-Agentic-Engineering-Framework`), coordinated over termlink
thread T-173. This task is the 832 half only.

**Phase boundary:** phase-1 is authoring-only (the self-contained HTML — diagram + BPMN import/export).
Project browser / Save-to-project / version history (Flask server `/api/list`,`/api/save`,
`.editor-versions/` + corpus) are **out of scope** — phase-2, deferred pending demand.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] A versioned release artifact of the single-file designer exists (a build named with an explicit
      version, e.g. `dist/aef-workflow-designer-<version>.html`), byte-identical to the committed
      `src/aef-workflow-designer.html` at that version (`diff -q` clean).
- [ ] The version is discoverable/reproducible — a recorded version string (e.g. a `VERSION` file or a
      manifest entry) that a consumer can pin to, and a documented command to reproduce the build.
- [ ] A release mechanism exists (a script or documented `fw`/make target) that produces the versioned
      artifact from `src/` deterministically (re-running it on the same source yields an identical file).
- [ ] `docs/` documents the **bidirectional protocol** (IW-6): (a) how AEF pulls/re-pins a new version,
      (b) how AEF sends improvements upstream to 832 (cross-agent channel; never patch the vendored copy).
- [ ] The existing self-contained invariant still holds: the released artifact opens and authors offline
      (no server) — diagram + BPMN import/export work with no network calls.

### Human
- [ ] [REVIEW] Released designer artifact authors correctly offline
  **Steps:**
  1. Open the released `dist/aef-workflow-designer-<version>.html` directly in a browser (file:// or a
     static server), with no Flask server running.
  2. Create a couple of nodes, connect them, then use BPMN export; then re-import the exported file.
  **Expected:** Authoring works fully offline; export/import round-trips; no console errors.
  **If not:** Note which capability failed and whether it silently depended on the server.

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

### 2026-07-10T09:56:33Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-174-cut-versioned-single-file-designer-relea.md
- **Context:** Initial task creation
