---
id: T-141
name: "Guard Save-to-project against the pristine unedited seed"
description: >
  Save to project on the untouched starter seed silently creates an investigate version entry (self-inflicted residue source, see T-140). Add a confirm() guard in saveToProject: if the bytes to save equal the pristine seed BPMN, ask before writing. Self-contained; does not touch T-127 autosave.

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-07T18:08:12Z
last_update: 2026-07-07T18:17:38Z
date_finished: 2026-07-07T18:16:51Z
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

# T-141: Guard Save-to-project against the pristine unedited seed

## Context

Follow-up to T-140 (NOT-A-BUG closure). The version store is written only by a manual
"Save to project" click. Saving the pristine, unedited starter seed creates an
`investigate` version entry — the source of the self-inflicted residue T-140 chased.
Add a lightweight confirm() guard so an accidental/automated click on the untouched seed
asks first, while a deliberate operator can still proceed. Self-contained in
`saveToProject()`; compares against `_seedBpmn`, the processed seed bytes captured at the
end of Init. Does NOT touch the T-127 autosave seam (localStorage-only).

## Acceptance Criteria

### Agent
- [x] `saveToProject()` compares the bytes it is about to POST against `_seedBpmn` — the
      PROCESSED seed captured at the end of Init (after refreshDisplayIds()+renderAll(),
      before autoLoadStored()). Two false starts captured as PL-022: (1) capturing at
      seed-creation throws — buildBpmnXml deps (TYPE_TAG) are in TDZ; (2) comparing against a
      raw `getInvestigateWorkflow()` never matches — Init populates node refs the raw seed lacks
- [x] When the bytes match, the guard calls `confirm()`; on cancel it returns WITHOUT
      calling `/api/save` (button label restored) — verified: dialog fired, Cancel wrote nothing
- [x] Guard does not fire once the document is edited or a different map is loaded
      (compare is on exact BPMN bytes, so any change diverges) — verified editedMatches=false
- [x] No change to autosave / T-127 code paths (`grep` shows autosave still localStorage-only)
- [x] Editor loads with no new console error and Init completes (regression check — the
      first attempt threw a TDZ error at Init; this AC guards against reintroducing it)
- [x] Editor JS synced byte-identical to build/gallery/designer.html (mirror invariant)
- [x] Functional proof via headless browser: click Save on fresh seed → guard confirm
      fired and, on dismiss, `/api/versions?id=investigate` stayed `[]` (no write, no dir);
      after a node move, `buildBpmnXml(state) === _seedBpmn` is false (guard steps aside)

### Human
- [ ] [REVIEW] The guard feels right — an unedited starter map warns before saving, a real
      edited map saves with no friction
  **Steps:**
  1. Reuse the running gallery on :8834 (or `tools/serve-gallery.sh 8834`)
  2. Open the editor fresh (no `?load`); immediately click "⤓ Save to project"
  3. Observe the confirm dialog; click Cancel
  4. Move any node, then click "Save to project" again
  **Expected:** Step 2-3 shows a confirm naming the starter example; Cancel writes nothing.
  Step 4 saves silently (no confirm) as a real version.
  **If not:** Note whether the confirm failed to appear on the pristine seed, or wrongly
  appeared after an edit.

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
grep -q "const _seedBpmn = buildBpmnXml(state);" src/aef-workflow-designer.html
grep -q "bpmn === _seedBpmn" src/aef-workflow-designer.html
grep -q "localStorage.setItem(AUTOSAVE_KEY" src/aef-workflow-designer.html
diff -q src/aef-workflow-designer.html build/gallery/designer.html

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

### 2026-07-07 — confirm() (soft guard) rather than hard block
- **Chose:** When the save bytes equal the pristine seed, ask via `confirm()` and honour
  Cancel by returning before `/api/save`. A deliberate operator can still proceed by
  accepting.
- **Why:** Antifragility/usability — an accidental or automated click (the actual residue
  source in T-140) is stopped, but no capability is removed; saving the starter example
  on purpose remains possible.
- **Rejected:** (a) Hard block / disable the button on the seed — removes a capability and
  is surprising. (b) Auto-rename the seed on save — silently mutates the operator's id.

### 2026-07-07 — capture the baseline at end-of-Init, compare exact BPMN bytes
- **Chose:** `const _seedBpmn = buildBpmnXml(state)` immediately after Init's
  refreshDisplayIds()+renderAll(), before autoLoadStored(); guard compares `bpmn === _seedBpmn`.
- **Why:** That is the only point where `state` is the fully-processed pristine seed AND
  every buildBpmnXml dependency is initialized. Byte comparison means any real edit or a
  loaded map diverges automatically — no separate dirty-flag plumbing, no T-127 coupling.
- **Rejected:** (a) capture at seed-creation — throws (TYPE_TAG TDZ, PL-022); (b) compare
  to a fresh `getInvestigateWorkflow()` — never matches (Init post-processing, PL-022);
  (c) a dirty flag hooked into edit paths — more surface area, risks touching T-127.

## Recommendation

**Recommendation:** GO (finalize — agent ACs complete and browser-verified, ship to human REVIEW)

**Rationale:** All 7 Agent ACs are implemented and proven in a real headless browser: the
guard confirm fires on the pristine seed, Cancel leaves the version store empty (`[]`, no
dir), and after a node edit the predicate is false so genuine saves are frictionless. The
mirror invariant holds byte-identical and Init loads with no console error (the TDZ
regression from the first attempt is fixed and now has a dedicated regression AC). The one
remaining AC is a Human REVIEW of whether the guard *feels* right — subjective UX taste.

**Evidence:**
- Browser: click Save on fresh seed → confirm dialog with the exact guard message; Cancel → `/api/versions?id=investigate` = `[]`, no `.editor-versions/investigate/` dir created
- Browser eval: pristine `buildBpmnXml(state) === _seedBpmn` → true; after node move → false
- `diff -q src/aef-workflow-designer.html build/gallery/designer.html` → identical
- Init console: 0 errors on load (was 2 — a TDZ throw — in the first attempt)

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-07T18:08:12Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-141-guard-save-to-project-against-the-pristi.md
- **Context:** Initial task creation

### 2026-07-07T18:16:51Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed

## Reviewer Verdict (v1.5)

- **Scan ID:** R-15f46c79
- **Timestamp:** 2026-07-27T21:20:17Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none
