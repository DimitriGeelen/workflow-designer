---
id: T-062
name: "Reconcile ~70 silently-dropped aef keys across 14 corpus maps (surfaced by
  T-061 warn)"
description: >
  T-061 added a loud WARN for unknown aef.* keys; it surfaced that 14 existing corpus
  maps carry ~70 aef.* keys that have been silently dropped since authoring (state,
  note, guard, reads, writes, terminalKind, trigger, gate, exitCode, gatewayKind,
  autoTrigger, gates, umbrellaBypass, rule, sources, sideEffects, handoffTo, collection,
  softFail, external, section, ladder, etc). Prior sessions authored these believing
  aef: was free-form passthrough. Per-key decision: PROMOTE common/meaningful ones
  to known vocab (bridge META_KEYS + editor metaKeys, kept in parity by test_editor_bridge_meta_parity.py)
  vs RENAME one-off ones to aef.x-* explicit passthrough. Then corpus runs warn-clean.
  Bounded per-map mechanical work; NOT a bug fix (data was never in BPMN) — a reconciliation.
  Depends on T-061.

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
created: 2026-07-03T23:46:01Z
last_update: '2026-08-16T14:33:09Z'
date_finished: 2026-07-04T00:15:28Z
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
  - ts: '2026-08-16T12:33:34Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:09Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 1
      F3: 2
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=1 
      (prose:routing/geometry-incidental); F3=2 (prose:seam-namespace); F1=0 
      (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:15Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:docs/reports/T-062-aef-key-reconciliation.md,tests/run-bridge-tests.sh,tools/yaml-to-bpmn.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-062: Reconcile ~70 silently-dropped aef keys across 14 corpus maps (surfaced by T-061 warn)

## Context

T-061 added a loud WARN for unknown `aef.*` keys and it surfaced that 14 corpus maps carry
~70 `aef.*` keys silently dropped since authoring (`state`, `note`, `guard`, `reads`, `writes`,
`terminalKind`, `trigger`, `gate`, `exitCode`, `gatewayKind`, `autoTrigger`, `gates`,
`umbrellaBypass`, `rule`, `sources`, `sideEffects`, `handoffTo`, `collection`, `softFail`,
`external`, `section`, `ladder`, …). Not a bug (data never reached BPMN) — a reconciliation.
Per-key decision: PROMOTE common/meaningful keys to the known vocabulary (bridge `META_KEYS` +
editor `metaKeys`, kept in parity by `test_editor_bridge_meta_parity.py`) vs RENAME one-off keys
to the explicit `aef.x-*` passthrough channel (T-061). Depends on T-061 (done). List of all
occurrences: run the bridge over `examples/aef-processes/*.workflow.yaml` and read stderr.

## Acceptance Criteria

### Agent
- [x] Every `aef.*` key across the corpus is reconciled — meaningful/repeated keys promoted to
      known vocab (bridge + editor, parity-tested); one-off keys renamed to `aef.x-*`
- [x] The bridge runs WARN-clean over the whole corpus (0 `unknown aef key` lines on stderr)
- [x] Any promoted key keeps editor↔bridge parity (`test_editor_bridge_meta_parity.py` passes)
- [x] Full bridge suite passes (26 checks, 0 fail); geometry sweep unaffected
- [x] `## Decisions` records the promote-vs-x-prefix split with rationale (which keys, why)

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

# warn-clean check: no 'unknown aef key' on stderr across the corpus
out=$(for f in examples/aef-processes/*.workflow.yaml; do python3 tools/yaml-to-bpmn.py "$f" --out /dev/null 2>&1 1>/dev/null; done); echo "$out" | grep -q 'unknown aef key' && exit 1 || true
bash tests/run-bridge-tests.sh

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

### 2026-07-04 — promote-vs-x-* routing rule (full split in docs/reports/T-062-aef-key-reconciliation.md)
- **Chose:** a single routing rule — *frequency + real-shared-concept*. 12 recurring
  scalars naming genuine modelling concepts PROMOTED to first-class vocab (bridge
  `META_KEYS` + editor `metaKeys`, parity-tested): terminalKind, state, note, softFail,
  section, guard, external, exitCode, autoTrigger, trigger, gatewayKind, gate. 3 synonyms
  ALIGNED to existing canonical keys (reads→contextReads, writes→artifactsWrites,
  sideEffects→sideEffect). 12 one-offs RENAMED to the explicit `aef.x-*` channel (8 scalar;
  4 structured — gates/ladder/sources/grouping — flattened to scalar x-* notes).
- **Why:** the existing vocabulary already encoded intent (a scalar attribute channel + an
  x-* opt-in); matching authored keys to that intent adds the fewest new first-class fields
  while making every author's data survive. Promotion is cheap and reversible here — the
  corpus is the only consumer and is edited in the same pass.
- **Rejected:** (a) x-* EVERYTHING — safe but refuses to name real recurring concepts
  (terminalKind/state/exitCode are clearly first-class); (b) promote everything — bloats the
  canonical schema with map-specific one-offs (branchesModeledOf, umbrellaBypass); (c) give
  structured one-offs dedicated emit — real feature work (FC-11), out of scope for a
  reconciliation.

### 2026-07-04 — structured one-offs flattened, not given a constituent channel
- **Chose:** flatten gates/ladder/sources/grouping to readable scalar `x-*` notes.
- **Why:** the scalar `<aef:meta>` channel can't carry structure; a real constituent channel
  is FC-11 feature work. Flattening preserves the information (it was fully dropped before)
  as visible text — proportionate for a reconciliation.
- **Rejected:** dropping them (lossy); building `<aef:constituents>` now (scope creep).

### 2026-07-04 — structured META_KEYS drops deferred to a follow-up task
- **Chose:** the T-062 hardening (WARN when a META_KEYS/x-* key holds a dict/list) surfaced
  5 KNOWN keys silently dropped as structured values — emits (×5), aggregation, compensates,
  multiInstance, timer. Filed as a follow-up rather than fixed here.
- **Why:** distinct class (known keys wanting *structured representation*, a feature) vs
  T-062's unknown-key reconciliation. One-finding-one-task — mirrors T-061→T-062.
- **Rejected:** flattening them into T-062 (they deserve structure, not a lossy string);
  ignoring the WARN (that is the silent-drop failure mode T-061/T-062 exist to kill).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-03T23:46:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-062-reconcile-70-silently-dropped-aef-keys-a.md
- **Context:** Initial task creation

### 2026-07-03T23:47:16Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-04T00:15:28Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
