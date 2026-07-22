---
id: T-232
name: "S5a off-page seam parity guard pure-Python no-silent-drop on T-219 byte-fixture"
description: >
  S5a off-page seam parity guard pure-Python no-silent-drop on T-219 byte-fixture

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_offpage-seam-parity-verify.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-22T06:22:01Z
last_update: 2026-07-22T06:27:18Z
date_finished: 2026-07-22T06:27:18Z
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

# T-232: S5a off-page seam parity guard pure-Python no-silent-drop on T-219 byte-fixture

## Context

**S5a** of the off-page connector seam (last slice, split from S5 — the sibling S5b is the
gallery ghost-cards UI, filed separately). The whole arc has carried a PL-005/PL-030 drift
risk: the editor (JS export) and the bridge/parser (Python import) can diverge on the
`aef:link` field set, and aspect-by-aspect guards can all pass while a real gap survives
(PL-030). The counter (PD-015): a **STATIC seam test asserting key-set equality on the
SHARED byte-fixture** — `tests/fixtures/aef-bpmn/offpage-seam.bpmn` (T-219, byte-pinned both
sides, sha `0bc15bfac8…449d`). This slice turns S2's one-time round-trip check into a
STANDING pure-Python guard that runs even when the chromium harness skips (the established
832 pattern — cf. `tests/test_typed_event_fixture_contract.py`, T-212). The fixture's 3 legs:
resolved `workflowRef=1f9b5f0c…` + `name`, ghost `workflowRef=2222…` + `name`, legacy
`targetWorkflow=review-map` (no workflowRef/name). See `[[aef-integration-rail]]` and
`docs/plans/T-220-offpage-seam-editor-build-decomposition.md` §S5.

## Acceptance Criteria

### Agent
- [x] A pure-Python, stdlib-only guard (`tools/_offpage-seam-parity-verify.py`) loads the byte-pinned shared fixture `tests/fixtures/aef-bpmn/offpage-seam.bpmn` and asserts its sha256 matches the pin (`0bc15bfac81d80cc13df527a09056dda6170def304d5a43c038bb504b691449d`) before checking anything — a fixture edit fails loud (re-pin + notify AEF), never silently re-baselines
- [x] **No-silent-drop / key-set parity (PL-030 core):** every `<aef:link>` element in the fixture is accounted for by exactly one 832 parser path — `_link_refs_from_text` (uuid-pinned) ∪ `_legacy_refs_from_text` (legacy) — i.e. `count(<aef:link> in raw XML) == len(uuid_refs) + len(legacy_refs)`; no link is dropped by BOTH and none double-counted
- [x] **Field-set completeness per leg:** `_link_refs_from_text` returns exactly the 2 uuid-pinned legs with their FULL field set — `{workflowRef:1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7, name:aef-task-lifecycle}` and `{workflowRef:22222222-2222-4222-8222-222222222222, name:publish-map}` — each with a resolved id-bearing host `node`/`nodeName` (the nearest-ancestor climb); `_legacy_refs_from_text` returns exactly the 1 legacy leg `{slug:review-map}` with a resolved host node
- [x] **Cross-side anchor:** the resolved leg's `workflowRef` equals AEF's live uuid `1f9b5f0c-0be4-4cfe-9158-d9e6f0c1d4c7` (the pinned pair-draft-#3 resolved target — this is the byte the two sides agree on)
- [x] The guard reuses gallery-serve.py's OWN parser functions (imported by path — no re-implementation; single source of truth, so a future parser change re-runs through the guard); passes; existing verifiers still green (list 22/22, registry 17/17, claim 11/11, save-allowlist 6/6, corpus-adopt OK, serve-gallery 9/9, bpmn-claim-cli 15/15) and `tests/test_corpus_fixture_pins.py` still green

### Human
<!-- All criteria are agent-verifiable (static Python guard on a pinned fixture). No Human ACs. -->

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
python3 -m py_compile tools/_offpage-seam-parity-verify.py
python3 tools/_offpage-seam-parity-verify.py
python3 tools/_gallery-list-verify.py
python3 tools/_gallery-registry-verify.py
python3 tools/_bpmn-claim-cli-verify.py
python3 tests/test_corpus_fixture_pins.py

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

### 2026-07-22 — the "parity guard" was mostly un-covered, and its shape wasn't a round-trip
- **What changed:** A gap-scan (G-020 before filing) found the existing seam tests do NOT
  cover this: `test_bridge_seam_roundtrip.py` is a namespace-drop detector (G-002/T-042),
  `test_editor_bridge_field_coverage.py` covers canonical-YAML link rendering, and the pin
  harness only sha-pins the fixture. No standing guard asserts the `aef:link` field set
  survives 832's parsers. Also: S2/T-225 already did a one-time editor round-trip byte-check,
  so the remaining value is a STANDING guard, and the 832 idiom for that (T-212) is a
  pure-Python shape guard that runs even when chromium skips — NOT a heavy Playwright test.
- **Plan impact:** S5 as filed bundled two deliverables → split; this task (S5a) is the
  parity guard only; ghost-cards UI is S5b (filed separately). "round-trip byte-equality"
  realized as PD-015 key-set/no-silent-drop parity on the pinned bytes (the operative
  PL-030 counter), not a JS export round-trip.
- **Triggered:** Filed S5b (gallery ghost cards) as a separate task; framework surfaced
  PD-015 + PL-030 on `fw work-on`, confirming the static-seam-test design.

## Decisions

### 2026-07-22 — pure-Python static parity guard on the shared bytes (not Playwright round-trip)
- **Chose:** A stdlib-only guard that sha-pins the shared fixture then asserts key-set /
  no-silent-drop parity via gallery-serve.py's OWN parsers (`_link_refs_from_text` ∪
  `_legacy_refs_from_text`), reused by import (single source of truth).
- **Why:** PD-015 (static seam test, key-set equality) + PL-030 (assert whole-fixture
  parity, not per-field presence) + the T-212 precedent (pure-Python guard runs even when
  the chromium harness skips). Anchoring on the bytes AEF also pins makes it a true
  cross-side parity anchor, not a synthetic map.
- **Rejected:** A Playwright editor import→export round-trip (heavy, skipped in headless CI —
  fails the "runs always" goal; S2 already did the one-time version); re-implementing the
  parse in the test (would drift from the real parser — defeats the guard).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-22T06:22:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-232-s5a-off-page-seam-parity-guard-pure-pyth.md
- **Context:** Initial task creation

### 2026-07-22T06:27:18Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
