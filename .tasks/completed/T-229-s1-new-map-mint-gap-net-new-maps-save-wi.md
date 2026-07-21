---
id: T-229
name: "S1 new-map mint gap: net-new maps save without workflowMeta uuid"
description: >
  Net-new maps created via the + button (createNewWorkflow) emit workflowMeta without a uuid; mint only fires on the import/load path (line 8007). A map born in the S1 editor must carry identity from birth. Found by AEF S4 e2e (rail offset 139).

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
created: 2026-07-21T22:24:48Z
last_update: 2026-07-21T22:26:00Z
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

# T-229: S1 new-map mint gap: net-new maps save without workflowMeta uuid

## Context

S1 seam-identity gap found by AEF's S4 e2e run against the served `:8834` (rail offset 139,
`[[aef-integration-rail]]`). `createNewWorkflow()` (the **+** button — the operator's net-new
authoring path, `src/aef-workflow-designer.html:2180`) builds `workflowMeta` with **no `uuid`**.
The uuid mint only fires on the import/load path (`:8007`, one-time backfill) and on rename-invariance
(T-224). So a map *born* in the editor and saved without ever being reopened emits
`<aef:workflowMeta>` without `uuid` → `/api/list` reports `uuid:null` for it → it is a
rendered-class citizen (no seam identity) until someone reopens it via a load path. Off-page
connectors that pin `workflowRef` cannot resolve to a never-loaded new map. Fix: mint the uuid at
new-map creation (identity from birth), matching the pre-pristine-seed semantics AEF recommended.

## Acceptance Criteria

### Agent
- [ ] `createNewWorkflow()` mints a v4 uuid into `workflowMeta.uuid` at creation (via the existing `mintUuid()`), so a net-new map carries seam identity from birth — no load-path round-trip required
- [ ] After creating a new map via the served editor and saving through `/api/save` (no reopen), `/api/list` reports a **non-null** `uuid` (36-char v4) for that map
- [ ] uuid is invariant across a subsequent rename (`renameActiveWorkflow`) and a reopen (load-path backfill at `:8007` is a no-op when uuid already present — no double-mint / churn)
- [ ] Existing behaviour unchanged for legacy maps loaded without a uuid (backfill still mints on load) and for the emit path (uuid emitted only when present)
- [ ] A verify path (Playwright against served `:8834`) exercises: new map via + → save → `/api/list` uuid non-null; then rename + reload → same uuid. Screenshots/response captured
- [ ] No regression: `_gallery-list-verify.py`, `_gallery-registry-verify.py` still green; editor byte-diff vs deployed `designer.html` limited to this change

<!-- No Human ACs: the fix is a deterministic serialization behaviour (uuid present in
     /api/list), fully agent-verifiable through the served surface + gallery verifiers. -->

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
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-registry-verify.py
# T-229 prevention: the new-map BIRTH path must mint identity. `uuid: mintUuid()`
# (object-literal form) is unique to createNewWorkflow; the load-path uses assignment.
grep -q 'uuid: mintUuid()' src/aef-workflow-designer.html

## RCA

**Symptom:** A net-new map created via the editor + button and saved (without ever being
reopened) emits `<aef:workflowMeta>` with no `uuid`; `/api/list` reports `uuid:null` for it.
It has no seam identity, so off-page `workflowRef` connectors cannot resolve to it.

**Root cause:** uuid minting was attached to the *load/import* path (`:8007` one-time backfill)
and to rename-invariance (T-224), on the assumption that every map passes through a load path.
`createNewWorkflow()` (`:2180`) constructs `workflowMeta` inline and never mints — a birth path
that bypasses the only mint site. Identity was treated as a load-time property, not a
creation-time invariant.

**Why structurally allowed:** S1 (T-224) verified mint via the import fixture path only; there was
no test that a map *born* in the editor carries a uuid. The gallery list-verifier asserts uuid is
present when the XML has one, but nothing asserted the new-map creation path produces one — so the
gap was invisible to CI and only surfaced when AEF drove the live + button (rail offset 139).

**Prevention:** (a) mint at creation so identity is a birth invariant, not load-dependent;
(b) add a Playwright/served-surface assertion (this task's verify) that new-map→save→/api/list
yields a non-null uuid, closing the CI blind spot that let a whole authoring path ship uuid-less.

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

### 2026-07-21T22:24:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-229-s1-new-map-mint-gap-net-new-maps-save-wi.md
- **Context:** Initial task creation

### 2026-07-21T22:26:00Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
