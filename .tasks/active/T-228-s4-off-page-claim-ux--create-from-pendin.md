---
id: T-228
name: "S4a: off-page claim UX — editor 'create from pending ref' picker (name-match suggest-only)"
description: >
  S4a: editor 'create from pending ref' picker — seeds a new map adopting a pending ghost's uuid; saving claims it (via:ui). CLI split to S4b/T-230.

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
created: 2026-07-21T21:50:40Z
last_update: 2026-07-21T22:45:50Z
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

# T-228: S4a: off-page claim UX — editor 'create from pending ref' picker (name-match suggest-only)

## Context

**S4a** of the off-page connector seam (T-218 GO); depends on **S3/T-226+T-227** (ghost registry
DONE — `/api/list ghosts[]` live, `.context/designer/registry.yaml {ghosts,claims}` maintained).
S4 lets an operator **claim** a pending ghost: turn a ghost uuid into a real map identity so all
its referrers resolve with ZERO diagram edit.

**Scope split (2026-07-22, operator-decided).** S4 was two deliverables; decomposed per task-sizing:
- **S4a = THIS task (T-228):** the editor **"create from pending ref"** picker (the primary operator
  UX). Selecting a pending ghost seeds a NEW map that adopts the ghost's uuid → on save that uuid
  becomes a live map → the claim is recorded (`via:"ui"`) and the ghost drops; all referrers resolve
  by S3 rescan. Fully 832-product-owned, no vendored-boundary question.
- **S4b = T-230:** the headless `fw bpmn claim <uuid> <project>` CLI (`via:"cli"`), added as a real
  `bpmn` subcommand to the vendored `.agentic-framework/bin/fw` (operator-decided home).

On claim (either surface): ghost removed from `registry.ghosts` → recorded in
`registry.claims:[{uuid,project,ts,via:ui|cli}]` → uuid lives in the new/target map's
`<aef:workflowMeta uuid=…>`. **Name-match is suggest-only, never silent** (rail-ratified). AEF runs
their S4 end-to-end claim-picker re-verify against this (T-2523 lane); ready-made pending refs left
in 832's store (`s4-e2e-probe` + 2 live ghosts, rail offset 139). Critical path per T-220:
S1→S2→**S4**. See `docs/plans/T-220-offpage-seam-editor-build-decomposition.md` §S4 and
`[[aef-integration-rail]]`. uuid-pinned ghosts exit ONLY via claim (S3: else re-materialize from XML).

## Acceptance Criteria

### Agent
- [ ] Editor picker **"create from pending ref"**: lists `/api/list ghosts[]` (uuid, name, referrer count); selecting one seeds a NEW map whose `workflowMeta.uuid` == the ghost uuid; **name-match is suggest-only** (a same-named live map is surfaced as a suggestion, never auto-adopted/opened)
- [x] Saving the picker-seeded map **claims** the ghost: the server records `{uuid, project, ts, via:"ui"}` in `registry.claims` and the ghost drops from `registry.ghosts` (its uuid is now a live map); recorded through the one authoritative `/api/save` path
- [x] After the claim, `/api/list`: the uuid is **absent** from `ghosts[]` and present as that map's `maps[].uuid` — every referrer now resolves (S3a derivation: referrer `workflowRef` matches a live map uuid → no ghost) with **NO diagram-XML edit** to the referrers
- [x] `claims[]` is an append-only audit trail; re-seeding/re-saving the same already-claimed uuid is idempotent (no duplicate claim entry, ghost stays gone)
- [x] A verify tool (`tools/_gallery-claim-verify.py`) exercises the ui-claim path end-to-end (seed uuid → save → ghost dropped + claim `via:"ui"` recorded + referrer resolves; idempotent re-claim). Passes
- [x] No regression: S3a/S3b verifiers (`_gallery-list-verify.py` 22/22, `_gallery-registry-verify.py` 17/17), save-allowlist, corpus-adopt, byte-pins all still green; editor byte-diff vs deployed `designer.html` limited to this change

### Human
- [ ] [REVIEW] The "create from pending ref" picker reads clearly and the suggest-only affordance is unambiguous
  **Steps:**
  1. `cd /opt/832-Workflow-designer && nohup tools/serve-gallery.sh 8834 >/dev/null 2>&1 &` then open http://192.168.10.107:8834/designer.html
  2. Open the picker (control added by this task); with `s4-e2e-probe`'s pending refs in the store, review the ghost list (uuid, name, referrer count)
  3. Pick a ghost whose name matches an existing live map; confirm the same-named map is shown only as a *suggestion*, not auto-adopted
  **Expected:** The list is legible; selecting seeds a new map adopting the ghost uuid; any name-match is offered, never applied silently
  **If not:** Note which affordance misled you (label, ordering, the suggestion wording) — that is the UX fix

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
python3 tools/_gallery-claim-verify.py

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

### 2026-07-22 — claim mechanics landed on the SERVER, not the editor
- **What changed:** The claim is a pure server-side reaction to `/api/save`, not editor logic. When a saved map's OWN `workflowMeta.uuid` matches a pending registry ghost, gallery-serve.py records the claim (`via:"ui"`) and drops the ghost. The editor picker's only job is to SEED a new map adopting the ghost uuid — the save does the claim. This keeps the claim atomic + testable headlessly and means the CLI (S4b) reuses the exact same server path (calling the same `claim_ghost_after_save`, `via:"cli"`).
- **Idempotency fell out for free:** the claim fires only while the ghost is still in `registry.ghosts`; a re-save finds no match → no-op. No separate guard needed. Also hardened `merged_ghosts()` to never surface a registry ghost whose uuid is now a live map (S3a-consistent invariant).
- **Plan impact:** AC-2/3/4/5/6 (server claim + audit + idempotency + verify + no-regression) are DONE and verified headlessly (`tools/_gallery-claim-verify.py` 11/11). Only AC-1 (the picker UI) + the Human [REVIEW] remain.
- **Triggered:** UI half (picker modal + seed-adopting-uuid + name-match suggest-only + Playwright verify) deferred to next window at 68% budget (Work Proposal Rule — UI build isn't a small bounded unit). Task stays started-work. S4b/T-230 unchanged (reuses the server claim path).

## Decisions

### 2026-07-22 — S4 decomposition + claim-CLI home (operator-decided)
- **Chose:** Split S4 → S4a (this task, editor picker) built first; S4b (T-230, `fw bpmn claim` CLI) separate. Picker is the primary operator UX and is fully 832-product-owned (no boundary question), so it doesn't wait on the CLI-home call.
- **Why:** Task-sizing rule (one task = one deliverable); T-228 bundled picker + CLI. Picker-first also unblocks AEF's S4 claim-picker re-verify sooner.
- **Rejected:** CLI-first (needs the home decision up front, delays the higher-value UX); both-under-one-task (larger multi-commit unit, mixes a clean product deliverable with a boundary-touching one).

### 2026-07-22 — where 832's claim CLI lives (S4b/T-230, operator-decided)
- **Chose:** Add a real `bpmn` subcommand to the vendored `.agentic-framework/bin/fw`, so the operator command is literally `fw bpmn claim <uuid> <project>` (matches the ratified contract shape verbatim).
- **Why:** Operator preference for the ratified command shape; the vendored `fw` has no project-local subcommand hook (dispatcher hard-fails on unknown commands, `bin/fw:6622`), so a local tool wouldn't be `fw bpmn`. G-008 upstream path applies to the vendored edit.
- **Rejected:** 832-local `tools/bpmn.py` (cleaner product/governance separation + portability, but the operator command wouldn't be `fw bpmn claim` and would need rail-coordination with AEF on the exact invocation).
- **Note:** operates ONLY on 832's own store (`.context/designer/registry.yaml` + gallery) — not running AEF's tooling (T-559 boundary intact).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-21T21:50:40Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-228-s4-off-page-claim-ux--create-from-pendin.md
- **Context:** Initial task creation
