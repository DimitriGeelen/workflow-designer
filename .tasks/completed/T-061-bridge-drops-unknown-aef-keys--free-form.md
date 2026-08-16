---
id: T-061
name: "Bridge drops unknown aef: keys — free-form passthrough namespace is a closed
  whitelist"
description: >
  VERIFIED in T-058 (FC-13): yaml-to-bpmn.py emits only its known aef set (meta META_KEYS,
  decisionInput/Outputs, contextReads, artifactsWrites, io, link); any OTHER aef.*
  key is silently dropped (test: aef.enforcement=X absent from BPMN). Editor advertises
  aef: as free-form passthrough, but the bridge path is a closed whitelist. Generalized
  ROOT of T-059 + T-060. Fix (a) pass through unknown scalar aef.* as aef:meta attrs,
  or (b) drop 'free-form' language + document fixed vocab. Guard: round-trip test
  of arbitrary aef.* key. Under G-002.

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
created: 2026-07-03T22:54:23Z
last_update: '2026-08-16T13:57:15Z'
date_finished: 2026-07-03T23:46:12Z
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
      D2: 3
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=3 
      (body:component-silent-failure); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=0 (no-signal); F-AUTONOMY=0 
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:15Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tests/run-bridge-tests.sh,tests/test_bridge_aef_passthrough.py); 
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-061: Bridge drops unknown aef: keys — free-form passthrough namespace is a closed whitelist

## Context

FC-13 (verified in T-058): `yaml-to-bpmn.py` emits only a hardcoded handled set of `aef.*`
keys; any other key is silently dropped, so the `aef:` namespace the editor advertises as
"free-form passthrough" is a closed whitelist on the bridge path. Generalized root of T-059 +
T-060. Fix = the **synthesis** (steelman/strawman, this session): keep the known vocabulary,
add an explicit opt-in extension channel (`aef.x-*` scalars pass through as `<aef:meta>` attrs),
and make bare unknown keys **loud** (a stderr WARN, not a silent drop) — so no key is ever
dropped silently again. Scope = the BRIDGE only (Python side, where FC-13 was found/verified);
editor-side (JS) generic passthrough is a separate concern (G-002 / JS-DOM harness). Under G-002.

## Acceptance Criteria

### Agent
- [x] Bridge passes scalar `aef.x-*` (extension-prefixed) keys through as `<aef:meta>`
      attributes — an `aef.x-foo: bar` round-trips into the BPMN as `x-foo="bar"`
- [x] Bridge no longer drops unknown keys SILENTLY: a bare unknown `aef.foo` prints a WARN to
      stderr naming node uid + key + the `aef.x-` hint; exit code unchanged (non-strict, pipeline-safe)
- [x] New test `tests/test_bridge_aef_passthrough.py` — asserts (a) `aef.x-*` survives the
      round-trip, (b) a bare unknown key emits the warn + is absent from output; self-test included;
      wired into `tests/run-bridge-tests.sh`
- [x] Running the bridge over the corpus SURFACES pre-existing silent drops (~70 `aef.*` keys
      across 14 maps — `state`/`note`/`guard`/`reads`/`terminalKind`/`trigger`/… that prior
      sessions authored believing "free-form passthrough"). These are a distinct problem (data
      loss in authored maps, not bridge behaviour) — filed as **T-062** (corpus reconciliation);
      NOT fixed here per one-bug-one-task. The point: they are now VISIBLE, not silent.
- [x] Full bridge suite passes (26 checks — the new test included, 0 fail; warns are non-fatal)

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

python3 tests/test_bridge_aef_passthrough.py
bash tests/run-bridge-tests.sh

## RCA

**Symptom:** unknown `aef.*` keys are silently dropped by the bridge (FC-13, empirically
verified in T-058: `aef.enforcement='X'` → absent from BPMN, no warning). The editor advertises
`aef:` as a free-form passthrough namespace; the bridge path is a closed whitelist.

**Root cause:** `yaml-to-bpmn.py` emits only its hardcoded handled set (META_KEYS +
decisionInput/decisionOutputs/contextReads/artifactsWrites/io/link); every other `aef.*` key
falls through with no emit and no diagnostic.

**Why structurally allowed:** the "free-form passthrough" claim (editor/docs) and the closed
whitelist (bridge) were never reconciled, and no test asserted round-trip of an arbitrary key.
T-059 and T-060 fixed two *instances* of the missing whitelist; neither addressed the root
(that the whitelist is closed and silent).

**Prevention:** (1) an explicit `aef.x-*` extension channel so intentional custom keys pass
through; (2) a loud stderr WARN on any bare unknown key — converts silent-drop into a visible
diagnostic ("no silent failures"); (3) `test_bridge_aef_passthrough.py` asserting both, so the
contract can't silently regress.

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

### 2026-07-03T22:54:23Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-061-bridge-drops-unknown-aef-keys--free-form.md
- **Context:** Initial task creation

### 2026-07-03T23:41:05Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-03T23:46:12Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
