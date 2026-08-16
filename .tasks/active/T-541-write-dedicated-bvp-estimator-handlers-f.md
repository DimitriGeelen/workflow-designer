---
id: T-541
name: "write dedicated BVP estimator handlers for the three operator-requested product
  drivers"
description: >
  write dedicated BVP estimator handlers for the three operator-requested product
  drivers

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
created: 2026-08-16T13:04:24Z
last_update: '2026-08-16T14:33:05Z'
date_finished:
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
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:13Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:.agentic-framework/.vendor-divergence.yaml,policy/value-drivers.yaml,tools/_t352-p011-errexit-probe.sh,tools/_t541-bvp-driver-handler-teeth.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:46Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:.agentic-framework/.vendor-divergence.yaml,policy/value-drivers.yaml,tools/_t541-bvp-driver-handler-teeth.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
bvp_scores_proposed:
  - ts: '2026-08-16T14:33:05Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 2
      F3: 4
      F1: 5
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=2 (prose:routing-single-element); F3=4 
      (prose:seam-fixture-or-pin); F1=5 (prose:process-composition)
    rubric_sha: e4a00f38e801
---

# T-541: write dedicated BVP estimator handlers for the three operator-requested product drivers

## Context

T-540 filed three operator-requested global drivers to the approval queue — `V_WORKFLOW_ROUTING`,
`V_AEF_INTEGRATION`, `V_SDLC_ENABLEMENT`, all weight 9 — and measured that the estimator cannot
score them. `estimate_task` dispatches on a hand-written handler table
(`estimator.py:2295-2345`); anything absent falls through to `score_free_driver`
(`estimator.py:2225`), which substring-matches the driver's *own id* in the task body. Probed over
69 active tasks: **0 of 55 non-inception tasks scored non-zero**, and the 14 that did were
inceptions echoing their `voi_score` identically for three unrelated driver ids.

This task writes the three handlers so the drivers mean something the moment the operator approves
them. The drivers stay **pending** — `policy/value-drivers.yaml` is not touched here. Handlers
latent-until-activation is an established pattern in this file (`score_f_autonomy` shipped latent
under T-2329, `score_d_disjoint` and the arc-scoped handlers are latent today).

**Two traps this task must not walk into, both measured in T-540:**

1. **A decorative ceiling.** No driver in the corpus ever scored 5; the existing handlers reserve
   their top level for exact prose phrases that never occur. Patterns here are mined from the real
   task corpus, and any level that turns out unreachable is *recorded as unreachable* rather than
   left to look like a working scale.
2. **A vacuous handler.** A driver that fires on everything ranks nothing. Each handler must be
   shown to discriminate — non-zero on a named subset, zero on a named disjoint subset — and the
   guard must fail if a handler ever degenerates to all-hit or all-miss.

## Results

Measured over the **44 non-completed, non-inception** tasks (inceptions are routed to
`_score_inception_voi` before any handler runs, so they cannot exercise these):

| driver | fires on | levels reached | distribution |
|---|---|---|---|
| `V_WORKFLOW_ROUTING` | 24/44 (55%) | 1,2,3,4,5 | `{0:20, 1:9, 2:3, 3:3, 4:7, 5:2}` |
| `V_AEF_INTEGRATION` | 27/44 (61%) | 1,2,3,4,5 | `{0:17, 1:7, 2:6, 3:2, 4:9, 5:3}` |
| `V_SDLC_ENABLEMENT` | 32/44 (73%) | 1,2,3,4 | `{0:12, 1:20, 2:7, 3:3, 4:2}` |

**Level 5 of `V_SDLC_ENABLEMENT` is reachable but unreached in production.** Its fixture scores 5,
so the level is not dead code — but every task that would earn it (Workflow Fabric,
`callActivity`, tenancy) is currently an *inception*, and inceptions never reach the handler.
Stated rather than left to look like a working part of the scale, which is the trap T-540 found in
the existing handlers (no driver in the corpus ever scores 5).

**`V_SDLC_ENABLEMENT` is the weakest of the three** — 20 of its 32 non-zero results are level 1,
driven by `\bvalidator\b` (26/58). Not tuned further: the alternative is dropping `validator`,
which would make the driver miss the validator-surfacing work that genuinely is process
enablement. Recorded as a known weakness rather than hidden by over-fitting.

### Two defects found and fixed while building this

1. **A dead rubric level.** `port-indicator` was a level-2 trigger for routing, but "port" was
   missing from that handler's entry gate — so T-294 ("Port-indicator pin click does not
   register") scored **0** and level 2 could never be returned by *any* input. Same class as
   PL-203. Fixed structurally rather than by adding the word: `_score_by_ladder` now **derives**
   the gate as the union of every ladder pattern, so a level cannot be added without becoming
   reachable. Two further mis-scores fell out of the same rewrite — T-286 (a z-order bug) scored
   4 "structural corpus change" and T-293 scored 3 "defect class"; both are now 2.

2. **The estimator scores the task TEMPLATE.** `parse_task` does not strip HTML comments, and a
   task body here is **33.6% comment on average, 64% at worst**. Measured in AEF's own code:
   `score_d3_usability`'s "default tuned" pattern matches the template's own instruction prose,
   giving **37 of 58 tasks a flat D3=2 they never earned** (52/58 non-zero → 15/58 stripped). Not
   patched — it is AEF's scoring calibration and a silent change would move every D3 in the
   register. Declared in the vendor manifest and owed upstream. These three handlers strip
   comments themselves so they cannot join it.

### A correction: the first version of the probe could not fail

Leg 5 claimed to catch the dead-level class. Mutation-tested it against a copy whose gate was
deliberately un-derived from the ladder — **the mutant scored all six fixtures correctly and the
leg stayed green.** Cause: the level-2 fixture read *"Edge arrowheads render above node-id
badges…"* and `Edge` is itself a gate word, so every fixture entered through the gate rather than
through its own level trigger. PL-206 — a control whose stimulus was built so it could never fail.
Fixtures rewritten to be gate-word-free; the mutant now produces **11 findings** and the real file
**0**. The claim is verified by mutation, not asserted.

## Acceptance Criteria

### Agent
- [x] Three handlers — `score_v_workflow_routing`, `score_v_aef_integration`,
      `score_v_sdlc_enablement` — added to `estimator.py` following the house idiom
      (`_components_text` + `_has_any`, any-signal gate, descending 5→4→3→2→1, evidence strings).
- [x] All three wired into the `handlers` dispatch table under their canonical policy names, so
      approval of the pending proposals activates them with no further code change.
- [x] **Each handler discriminates, measured on the real corpus.** 24/44, 27/44 and 32/44 — each
      strictly between 0 and the corpus size, distributions recorded above.
- [x] **Reachable levels recorded honestly.** Levels 1–5 for two handlers; `V_SDLC_ENABLEMENT`
      reaches 1–4 in production with level 5 named as reachable-but-unreached and the reason given.
- [x] **`policy/value-drivers.yaml` unchanged.** `git diff --stat policy/` is empty; all three
      proposals still read `state: pending`.
- [x] A probe (`tools/_t541-bvp-driver-handler-teeth.py`) wired into the bridge suite covering
      wired / alive / selective / graded / no-dead-levels / boilerplate-blind, with the
      dead-level leg verified by mutation (11 findings on the mutant, 0 on the real file).
- [x] **Vendored divergence declared.** `.agentic-framework/.vendor-divergence.yaml` carries the
      estimator entry; `_t517-vendor-divergence.py` returns 30 declared / 30 diverged, rc 0. The
      T-517 guard caught this change before I declared it, which is the guard working.

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
# ⚠ ERREXIT WARNING (T-352) — READ BEFORE USING THE CAPTURE PATTERN BELOW.
# P-011 runs each command under `-o pipefail` but NOT under an effective `-e`.
# Measured, not assumed (tools/_t352-p011-errexit-probe.sh): the gate runs each line as
# `if ( … eval "$cmd" ); then` (update-task.sh:1018) and that subshell is the CONDITION
# of an `if`, which neutralises errexit inside it. pipefail survives; errexit does not.
# CONSEQUENCE: a line of the form `a; b` IS JUDGED ON `b` ALONE. `a`'s exit code is
# discarded, so a command that fails outright can still leave the line green.
#   Proven false green:
#     out=$(python3 tools/validate-workflow.py BROKEN.bpmn 2>&1); echo "$out" | grep -q "VALID"
#   -> PASSES on a document the validator exits 2 on and labels INVALID, because
#      `grep -q "VALID"` matches INVALID as a SUBSTRING. Two defects stacked.
# PREFER a single command whose own exit code is the verdict — then no context question
# arises. When you must chain, the LAST command has to be the one that can fail, and its
# pattern must not be matchable by the earlier command's FAILURE output.
# Note `set -e` re-issued inside the subshell does NOT fix this: the suppressed context is
# inherited and re-setting the option does not clear it. See T-352 for the remedy.
#
# Pipefail/SIGPIPE hint (L-387): `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep
# matches and closes stdin while the upstream is still writing — verification then
# "fails" even though the pattern was present. The capture pattern below fixes THAT,
# and creates the errexit exposure described above; the file form fixes both:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out     # PREFERRED: && not ;
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"        # SIGPIPE-safe, errexit-blind
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

### 2026-08-16T13:04:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-541-write-dedicated-bvp-estimator-handlers-f.md
- **Context:** Initial task creation
