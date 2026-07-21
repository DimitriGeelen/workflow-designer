---
id: T-226
name: "S3 /api/list uuid + ghosts[] extension + registry twin (.context/designer/registry.yaml) with 3 ghost-drop rules (T-218 GO slice 3)"
description: >
  S3 /api/list uuid + ghosts[] extension + registry twin (.context/designer/registry.yaml) with 3 ghost-drop rules (T-218 GO slice 3)

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
created: 2026-07-21T20:04:35Z
last_update: 2026-07-21T20:04:35Z
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

# T-226: S3 /api/list uuid + ghosts[] extension + registry twin (.context/designer/registry.yaml) with 3 ghost-drop rules (T-218 GO slice 3)

## Context

**S3 of the T-218 (GO 2026-07-21) off-page connector seam build; depends on S1/T-224 (uuid, DONE); parallels S2/T-225.**
Additive server changes in `tools/gallery-serve.py` `/api/list` (`build_map_list()` :152) plus a STORE-side
registry twin. Mirror AEF's live half (rail offsets 111-113): `maps[].uuid` (additive), a NEW top-level
`ghosts[]:[{uuid,name,referenced_by:[{id,node,nodeName}],task,first_seen}]`, registry
`.context/designer/registry.yaml = {ghosts:[], claims:[]}` (atomic YAML), and the 3 ghost-DROP rules at sync.

Spec: `docs/plans/T-220-offpage-seam-editor-build-decomposition.md` §S3. See `[[aef-integration-rail]]`.

**⚠ SIZING — decompose before building (Task Sizing Rules):** this slice bundles a read-only extension and a
stateful registry subsystem. Recommend splitting:
- **S3a (read-only, ships first):** `maps[].uuid` (read workflowMeta.uuid from each map's bpmn) + read-only
  `ghosts[]` derived by scanning every map's `<aef:link workflowRef>` refs and collecting those whose uuid
  matches no known map uuid. No file writes. Testable by extending `tools/_gallery-list-verify.py`.
- **S3b (stateful):** persist `.context/designer/registry.yaml` {ghosts,claims}; wire `/api/save` rescan
  (merge refs→ghosts, name-dedup) + `/api/delete` back-ref strip; implement the 3 ghost-DROP rules
  (offset 113): (1) DROP when referenced_by empty AND no task; (2) KEEP when empty+task+named target still
  absent; (3) DROP when empty AND ghost name now matches a live slug even with a task. uuid-pinned
  (workflowRef) ghosts exit ONLY via explicit claim (that's S4).

## Acceptance Criteria

### Agent
<!-- Full-S3 criteria; if split, S3a takes the first three, S3b the rest. -->
- [ ] `/api/list` `maps[]` gains an additive `uuid` field per map (read from the map's `<aef:workflowMeta uuid=…>`; null when absent — legacy/rendered maps with no uuid yet); existing `maps[]` shape otherwise unchanged (no field renamed/removed)
- [ ] `/api/list` response gains a NEW top-level `ghosts[]` array: each entry `{uuid, name, referenced_by:[{id,node,nodeName}], task, first_seen}` derived by scanning every listed map's `<aef:link workflowRef>` refs and keeping those whose uuid resolves to no live map uuid; resolved refs (uuid matches a map) produce NO ghost
- [ ] `ghosts[]` is a SEPARATE top-level array (NOT status-flagged inside `maps[]`) so a 0.3.0 picker never tries to open a versionless ghost (openTarget-break avoidance, ratified offset 109/113)
- [ ] Registry `.context/designer/registry.yaml` `{ghosts:[], claims:[]}` is created/updated via atomic write (temp-file + rename); malformed/missing → treated as empty, never crashes `/api/list`
- [ ] `/api/save` rescans the saved map's `aef:link` refs and merges unresolved ones into `registry.ghosts` (name-dedup); `/api/delete` strips the deleted map from every ghost's `referenced_by`
- [ ] The 3 ghost-DROP rules apply at sync exactly as ratified (offset 113); uuid-pinned (`workflowRef`) ghosts are never auto-dropped (exit only via claim, S4)
- [ ] `tools/_gallery-list-verify.py` extended to assert `maps[].uuid` present + `ghosts[]` shape on a fixture with a resolved and an unresolved ref; passes
- [ ] Existing `/api/list` read-only guarantees hold (no corpus/version writes from a GET); existing gallery tests still pass

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

### 2026-07-21T20:04:35Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-226-s3-apilist-uuid--ghosts-extension--regis.md
- **Context:** Initial task creation
