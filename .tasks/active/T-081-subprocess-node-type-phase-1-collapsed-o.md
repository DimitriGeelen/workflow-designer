---
id: T-081
name: "subProcess node type phase 1: collapsed-only node + aef:constituents + scopeOf marker"
description: >
  Build authorized by T-068 GO (2026-07-04). Scope per docs/reports/T-068-constituents-inception.md §Spike B staged path, phase 1 ONLY: (1) schema: subProcess node type + constituents: list + optional scopeOf: back-reference; (2) bridge: bpmn:subProcess element (TYPE_MAP passthrough) + aef:constituents emission mirroring the multiInstance pattern; (3) editor: NODE_DEFAULTS entry, collapsed box glyph with plus marker + constituent-count badge, parse/build of aef:constituents (G-002: add cross-seam consistency test); (4) validator: new node type + constituents rules; (5) migrate the 4 x-* corpus maps (verification-gate g_gates, git-commit-flow x-checks, resume-status x-sources, session-capture x-captures). OUT: any child flow-node nesting (phase 2 — own inception; parser-scoping hazard fenced there).

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
created: 2026-07-04T13:34:26Z
last_update: 2026-07-04T14:32:40Z
date_finished: 2026-07-04T14:32:01Z
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

# T-081: subProcess node type phase 1: collapsed-only node + aef:constituents + scopeOf marker

## Context

Build authorized by T-068 GO (recorded 2026-07-04 via Watchtower). Design: docs/reports/T-068-constituents-inception.md §Spike B staged path — phase 1 ONLY (collapsed-only node; child flow-node nesting is phase 2 behind its own inception; the recursive-parser flattening hazard is fenced there). The `<aef:constituents>` element mirrors the T-063 `multiInstance` structured-dict pattern at the bridge seam.

## Acceptance Criteria

### Agent
- [x] Schema doc (`docs/designer/schema.md`) documents the `subProcess` node type, the `constituents:` list (`{id, name, ref?}` entries), and the optional `scopeOf:` back-reference, including the phase-1 fence (no child nesting) — new §4.4, type-table row, §7.2 elements, §8.1 history entry
- [x] Validator (`tools/validate-workflow.py`) accepts `subProcess` in NODE_TYPES and enforces constituents shape rules — `_check_constituents`: E-CONST-SHAPE, E-CONST-DUP, W-CONST-FIELD, E-SCOPEOF-SELF, E-SCOPEOF-DANGLING, W-SCOPEOF-TYPE; validator suite 34/34, full corpus exit 0
- [x] Bridge (`tools/yaml-to-bpmn.py`) emits `<bpmn:subProcess>` (TYPE_MAP passthrough) and `<aef:constituents>` via new STRUCTURED_ITEMLIST_KEYS channel; regenerated rendered/*.bpmn — 4 migrated maps carry both (grep-verified), bridge suite 31/31
- [x] Editor: `subProcess` in NODE_DEFAULTS/palette/glyph ([+] bottom-right, ▣N count badge on any constituents-bearing node), props Constituents editor, parse/build itemlist channel; in-browser round-trip byte-identical on all 4 migrated maps + 2 controls; parity test extended to guard the itemlist channel incl. field tuples (G-002)
- [x] The 4 x-* sites migrated: verification-gate `g_gates` (8 gates), git-commit-flow `g_hooks` (4 checks), resume-status `n_intel` (3 sources, → subProcess), session-capture `n_capture` (4 actions, → subProcess); x-checks/x-sources/x-captures removed, header comments updated
- [x] Corpus regression: geometry-signature sweep HEAD vs working tree — only n_capture/n_intel type strings differ, positions and all other 20+ maps byte-identical; lane-band sweep 24 clean; gallery designer.html + rendered copies in sync

### Human
- [ ] [REVIEW] Collapsed subProcess glyph reads clearly
  **Steps:**
  1. Open http://192.168.10.107:8834/ and view verification-gate and session-capture maps
  2. Look at the migrated nodes (g_gates, n_capture): box with [+] marker and constituent-count badge
  3. In the editor, click a subProcess node and check the properties panel lists its constituents
  **Expected:** The composite nature is visible at a glance; constituent list readable in props panel
  **If not:** Note which map/node reads poorly and what is confusing

## Verification

grep -q '"subProcess"' tools/validate-workflow.py
grep -q "STRUCTURED_ITEMLIST_KEYS" tools/yaml-to-bpmn.py
grep -q "structItemList" src/aef-workflow-designer.html
grep -q "subProcess:        { w: 120" src/aef-workflow-designer.html
out=$(python3 tests/test_editor_bridge_structured_parity.py 2>&1); echo "$out" | grep -q "itemlist: constituents"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "31 passed, 0 failed"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "34 passed, 0 failed"
out=$(bash tests/check-corpus-geometry.sh 2>&1); echo "$out" | grep -q "24 clean, 0 known-legacy, 0 new-fail"
python3 tools/validate-workflow.py examples/aef-processes/session-capture.workflow.yaml --quiet
python3 tools/validate-workflow.py examples/aef-processes/verification-gate.workflow.yaml --quiet
grep -q "aef:constituent " examples/aef-processes/rendered/verification-gate.bpmn
grep -q "bpmn:subProcess" examples/aef-processes/rendered/session-capture.bpmn
# the 4 in-scope sites carry no x-* workaround keys anymore (tier0-escalation/task-lifecycle sites are T-086 scope)
! grep -n "x-checks:\|x-sources:\|x-captures:" examples/aef-processes/session-capture.workflow.yaml examples/aef-processes/resume-status.workflow.yaml examples/aef-processes/git-commit-flow.workflow.yaml examples/aef-processes/verification-gate.workflow.yaml | grep -q .
diff -q src/aef-workflow-designer.html build/gallery/designer.html
awk '/<script>/{f=1;next}/<\/script>/{f=0}f' src/aef-workflow-designer.html > /tmp/t081-check.js && node --check /tmp/t081-check.js

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

### 2026-07-04 — constituents legal on any node type, not only subProcess
- **Chose:** `aef.constituents` validates on ANY flow node; `subProcess` is the task-like composite host, not a prerequisite.
- **Why:** 2 of the 4 real FC-11 sites are exclusiveGateways (verification-gate g_gates, git-commit-flow g_hooks). Forcing them to subProcess would change flow semantics (gateway routing rules, ≥2 outgoing) to satisfy a metadata need.
- **Rejected:** constituents-only-on-subProcess (breaks the gateway sites); converting gateways to subProcess (semantic distortion).

### 2026-07-04 — wire format: new list-of-dicts channel + scopeOf on the meta channel
- **Chose:** `<aef:constituents><aef:constituent id name ref?/></aef:constituents>` via a third structured channel (STRUCTURED_ITEMLIST_KEYS), parity-guarded incl. per-field tuples; `scopeOf` rides the existing `<aef:meta>` scalar channel (META_KEYS/metaKeys both sides).
- **Why:** entries have 3 fields — neither the scalar-list nor the dict channel fits; the meta channel is the cheapest lossless path for a scalar and the meta-parity test guards it for free.
- **Rejected:** flattening entries to scalars (loses ref); a dedicated `<aef:scopeOf>` element (more seam surface for zero gain).

### 2026-07-04 — [+] marker bottom-right, not BPMN's bottom-centre
- **Chose:** collapsed-marker in the bottom-right corner of the rect; count badge (▣N) bottom-left.
- **Why:** node names wrap centre-aligned; 5-line names (session-capture n_capture) collide with a bottom-centre marker — verified via rendered screenshot, the first placement was visibly broken.
- **Rejected:** bottom-centre (text collision); taller subProcess box (breaks shared 64px alignment rows from T-079).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Recommendation

**Recommendation:** GO
**Rationale:** Phase 1 lands the full FC-11 fix authorized by the T-068 GO — subProcess node type, first-class constituents on all four evidence sites, scopeOf marker — with every seam guarded: new itemlist channel covered by the extended structured-parity test, corpus round-trip byte-identical in-browser on all migrated maps, bridge/validator suites green, geometry regression zero outside the two intended type conversions. Child nesting stays fenced behind the phase-2 inception exactly as scoped.
**Evidence:** bridge 31/31, validator 34/34, parity+seam tests 6/6, lane-bands 24 clean; byte-identical round-trip on session-capture/resume-status/git-commit-flow/verification-gate + 2 control maps; screenshots in ## Visual Verification.

## Visual Verification

- `.playwright-mcp/t081-glyph-fixed.png` — subProcess glyph (n_capture): purple rect, [+] bottom-right, ▣4 badge bottom-left, 5-line label inside the box (read + confirmed)
- `.playwright-mcp/t081-props-constituents.png` — props panel: subProcess header, Extensions incl. Scope of, "CONSTITUENTS · 4" textarea editor (read + confirmed)
- `.playwright-mcp/t081-gateway-badge.png` — g_gates exclusiveGateway with ▣8 badge (read + confirmed; surrounding label collisions are pre-existing T-082/T-083 scope)
- `.playwright-mcp/t081-subprocess-glyph-zoom2.png` — first glyph iteration showing the bottom-centre marker colliding with the label (the defect that drove the bottom-right decision)

## Updates

### 2026-07-04T13:34:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-081-subprocess-node-type-phase-1-collapsed-o.md
- **Context:** Initial task creation

### 2026-07-04T14:01:55Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T14:32:01Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
