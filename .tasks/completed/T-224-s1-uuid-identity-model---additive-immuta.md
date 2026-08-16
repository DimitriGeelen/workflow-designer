---
id: T-224
name: "S1 uuid identity model - additive immutable workflowMeta.uuid connector-referenceable
  rename-stable identity (T-218 GO slice 1)"
description: >
  S1 uuid identity model - additive immutable workflowMeta.uuid connector-referenceable
  rename-stable identity (T-218 GO slice 1)

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
created: 2026-07-21T19:23:57Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-21T19:50:45Z
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
  - ts: '2026-08-16T12:33:44Z'
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:build/gallery/designer.html,docs/plans/T-220-offpage-seam-editor-build-decomposition.md,docs/plans/T-221-S1-uuid-identity-model-spec.md,src/aef-workflow-designer.html);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-224: S1 uuid identity model - additive immutable workflowMeta.uuid connector-referenceable rename-stable identity (T-218 GO slice 1)

## Context

**S1 of the T-218 (GO 2026-07-21) off-page connector seam build.** Give every workflow a stable,
immutable **uuid** as the connector-referenceable identity, so an off-page `<aef:link
workflowRef="<uuid>">` survives a rename. Today identity IS the slug (`workflowMeta.id`), which
changes on rename — the "name-only" gap the seam closes. **Minimal-churn design:** add
`workflowMeta.uuid` as an ADDITIVE immutable field; library STAYS slug-keyed (no re-key).

Execution spec: `docs/plans/T-221-S1-uuid-identity-model-spec.md` (6 steps). Decomposition:
`docs/plans/T-220-offpage-seam-editor-build-decomposition.md`. Arc: designer-authoring-surface.
See `[[aef-integration-rail]]`. **NB:** the spec's line anchors (8781/8782 etc.) predate T-223's
edits and have shifted ~44 lines — re-locate live.

**Two PL-022 traps (the crux):** (1) mint the seed uuid BEFORE the `_seedBpmn = buildBpmnXml(state)`
pristine-baseline capture, or the T-141 unedited-seed guard misfires; (2) exclude a legacy-map
first-time uuid backfill from the dirty-check, or every legacy open nags "unsaved changes."

## WIP state (2026-07-21 — budget ceiling hit ~96% mid-implementation)

**DONE + committed (src/aef-workflow-designer.html), all inert/no-op until seed-mint+backfill land:**
1. `mintUuid()` helper added just above `renameActiveWorkflow` (~line 2211) — crypto.randomUUID with a non-crypto v4 fallback for file://.
2. `renameActiveWorkflow` — added a comment documenting uuid is INVARIANT across rename (code already only touches id/pool/key; no change needed — Step 5 done).
3. Export (Step 3): in `buildBpmnXml` wmAttrs (~line 8270), `if (wm.uuid) wmAttrs.splice(1, 0, uuid="…")` — emits uuid right after id. **Inert until something sets `wm.uuid`.**

**REMAINING — ALL DONE (2026-07-21, next window; committed):**
- **Step 4a — import parse (parseBpmnXml, live line 8419):** added `uuid: aefMetaEl?.getAttribute('uuid') || null,` after the `id:` line. ✓
- **Step 4b — backfill (adoptImportedXml, live line 7998, after `saveActiveToLibrary();`):** added `if (!loaded.workflowMeta.uuid) loaded.workflowMeta.uuid = mintUuid();`. ✓
- **Step 1 (second half) — seed uuid BEFORE `_seedBpmn` (live line 8848):** inserted `if (!state.workflowMeta.uuid) state.workflowMeta.uuid = mintUuid();` above the capture. PL-022 trap #1 verified intact (check1b: `buildBpmnXml(state) === _seedBpmn`). ✓
- Refreshed build/gallery/designer.html; Playwright-verified on :8834 (7/7 checks true); Verification block + tests/ suite (roundtrip + corpus-pins) green; validate-workflow.py VALID exit 0. All 7 agent ACs checked.

**Anchors verified this window (post-T-223 shift):** renameActiveWorkflow 2211; adoptImportedXml 7975; wmAttrs export ~8270 (was 8252); parseBpmnXml workflowMeta ~8399; `_seedBpmn` capture 8829; autoLoadStored() call 8831. T-141 pristine guard = saveToProject ~7451 (`bpmn === _seedBpmn`). No global dirty/beforeunload mechanism exists.

## Acceptance Criteria

### Agent
- [x] A new/seed workflow has `workflowMeta.uuid` (crypto.randomUUID v4) set BEFORE the `_seedBpmn` capture; the T-141 pristine-seed guard still fires correctly (unedited seed → save prompts; edited → saves silently) — verified: seed uuid `fa41adbc-…` is v4; `buildBpmnXml(state) === _seedBpmn` (check1b true), so the guard baseline carries the uuid and does not misfire (PL-022 trap #1)
- [x] Export emits `<aef:workflowMeta … uuid="<v4>" …>` (additive, process-level); re-import yields the same uuid (round-trip stable) — verified: export attr present, positioned right after `id=`, `parseBpmnXml(xml).workflowMeta.uuid` === seed uuid (check2)
- [x] `renameActiveWorkflow` changes the slug (`workflowMeta.id`) but `uuid` is byte-identical before/after (uuid invariant across rename) — verified: id → `renamed-probe-xyz`, uuid unchanged (check3)
- [x] A legacy map (no `uuid` on import) backfills exactly once via `mintUuid()`; opening it does NOT mark it dirty / nag unsaved changes; a subsequent save persists the uuid — verified: stripped-uuid parse → null, `mintUuid()` backfill → v4 (check4); no isDirty/beforeunload mechanism exists so adopt-open stays clean (PL-022 trap #2); subsequent `buildBpmnXml` emits the uuid (check2 path)
- [x] Two imports of the same slug resolve to distinct library keys AND distinct uuids — verified: distinct uuids per parse+backfill (check5); distinct keys via the existing `_v<n>` collision loop (unchanged)
- [x] `tools/validate-workflow.py` stays clean (exit 0) on a `uuid`-bearing exported map (validator ignores unknown `aef:workflowMeta` attrs) — verified: `VALID -- no findings`, exit 0
- [x] Visual/functional-verified in Playwright (:8834): new-map uuid present, export→import round-trip, rename-holds-uuid, legacy-open-not-dirty — evidence read back — verified via `browser_evaluate` on a cleared-localStorage fresh seed; all 7 checks returned true (JSON read back). Data-model change (no CSS/HTML), so element screenshots N/A per the Visual Verification rule.

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

# mint helper present (crypto.randomUUID)
grep -q 'crypto\.randomUUID' src/aef-workflow-designer.html
# uuid rides workflowMeta
grep -q 'workflowMeta\.uuid' src/aef-workflow-designer.html
# export emits uuid on the process-level aef:workflowMeta
grep -q "uuid=" src/aef-workflow-designer.html
# editor still parses as one well-formed HTML document (no truncation from the edits)
python3 -c "import html.parser; p=html.parser.HTMLParser(); p.feed(open('src/aef-workflow-designer.html').read()); print('html-parse-ok')"

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

### 2026-07-21 — S1 landed; the crux was ordering, not the field
- **What changed:** The uuid field itself is trivial (additive attr, `if (wm.uuid)` gated export → byte-identical corpus, confirmed by the still-green pin test). The real risk lived entirely in *ordering* against two existing invariants: (1) the T-141 pristine-seed guard captures `_seedBpmn` at Init, so the seed uuid MUST be minted on the line above that capture or the guard misfires — verified directly (`buildBpmnXml(state) === _seedBpmn` after minting); (2) legacy backfill had to ride `adoptImportedXml` (which never autosaves) rather than any dirty-marking path, which held because the editor has *no* isDirty/beforeunload mechanism at all (confirmed by read).
- **Plan impact:** T-221 spec's line anchors were ~44 lines stale (pre-T-223); re-located live (parse 8419, backfill 7998, seed-mint 8848). No design change.
- **Triggered:** Nothing new. S2 (workflowRef serialization on `<aef:link>`) is next per the T-220 decomposition — it consumes this uuid as the connector target.

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

### 2026-07-21T19:23:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-224-s1-uuid-identity-model---additive-immuta.md
- **Context:** Initial task creation

### 2026-07-21T19:50:45Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
