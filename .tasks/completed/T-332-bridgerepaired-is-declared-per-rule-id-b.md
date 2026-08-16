---
id: T-332
name: "BRIDGE_REPAIRED is declared per rule id but E-LANE-FIELD covers four carriers
  with different repair characters"
description: >
  BRIDGE_REPAIRED is declared per rule id but E-LANE-FIELD covers four carriers with
  different repair characters

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
created: 2026-08-02T05:53:57Z
last_update: '2026-08-16T13:58:53Z'
date_finished: 2026-08-02T06:00:10Z
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
  - ts: '2026-08-16T12:33:50Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 7
    rationale: blast_radius=7 
      (paths:tests/run-bridge-tests.sh,tests/run-validator-tests.sh,tests/test_harness_cross_form_agreement.py,tests/test_rule_dialect_axis.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:53Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tests/run-validator-tests.sh,tests/test_harness_cross_form_agreement.py,tests/test_rule_dialect_axis.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-332: BRIDGE_REPAIRED is declared per rule id but E-LANE-FIELD covers four carriers with different repair characters

## Context

`BRIDGE_REPAIRED` (tests/test_harness_cross_form_agreement.py) declares, per
**rule id**, that the bridge repairs a defect so XML silence is correct rather
than blind. `E-LANE-FIELD` is one of the three entries. But that rule fires on
**four carriers** — `REQUIRED_LANE_FIELDS = ["id", "name", "authority",
"height"]` — and its fixture omits `height` only.

**Measured (2026-08-02), the `authority` sub-case behaves differently:**

| | `height` sub-case (what was measured) | `authority` sub-case |
|---|---|---|
| YAML form | ERROR `E-LANE-FIELD` | ERROR `E-LANE-FIELD` |
| bridge | `height="120"` | `authority="none"` (`yaml-to-bpmn.py:191`) |
| XML form | silent — genuinely repaired | **WARN `W-LANE-NO-OWNER`** |

So the entry's claim ("the bridged document is genuinely well-formed and XML
silence is correct") is true for one carrier and false for another. The
`authority` sub-case is not repaired: it is **carried, at reduced severity,
under a different rule id** — the `E-EDGE-FIELD` shape, where the pair table
named the wrong counterpart.

**And it was worse until today.** `W-LANE-NO-OWNER` shipped hours ago in T-331.
Before that, a lane missing `authority` was ERROR on the YAML form and
**completely silent** on the XML form, while the tolerance table declared it
repaired. T-331 closed the silence by accident; this task closes the false
declaration, which is the part that would have hidden the next one.

**The class:** a tolerance declared per RULE ID, where the rule spans several
carriers, is measured on whichever carrier the fixture happens to use and
generalised over the rest. Same shape as the rail-95 scope error (checked two
node types, wrote a sentence about three) — recurring inside my own instrument
rather than in prose.

## Acceptance Criteria

### Agent
- [x] **AC1 — The other carriers are measured, not assumed.** Each field in
      `REQUIRED_LANE_FIELDS` is driven through the bridge and validated on both
      forms; the per-carrier result (repaired / carried-same-id /
      carried-different-id / silent) is recorded in `## Spike measurement`.
      `REQUIRED_NODE_FIELDS` is measured the same way, since `E-NODE-FIELD` is
      also a `BRIDGE_REPAIRED` entry over multiple carriers.
- [x] **AC2 — Declarations state their measured scope.** Every
      `BRIDGE_REPAIRED` entry names WHICH carrier(s) the repair claim was
      verified against, so a reader cannot take a one-carrier measurement for a
      whole-rule guarantee.
- [x] **AC3 — The generalisation cannot silently recur.** A check fails when a
      `BRIDGE_REPAIRED` rule spans more carriers than its declaration accounts
      for. A note is not sufficient — the entry must be answerable.
- [x] **AC4 — Teeth AND discrimination.** A mutation proves the new check
      FIRES; a second leg proves it SEPARATES (a correctly-scoped declaration
      must pass while an over-scoped one fails).
- [x] **AC5 — No regression.** validator 46/0, bridge 66/0, cross-form 20 pairs
      / 17 AGREE / 0 DISAGREE, parity 49/11, dialect 49, geometry 24 clean —
      each RUN, not cited (the T-331 correction).

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

## Spike measurement

Each required field dropped in turn from a minimal two-lane map, bridged, and
validated on both forms. **Baseline-subtracted**: the probe document emits
`W-XML-LANE-GEOMETRY` of its own, and the first run reported it on almost every
row — which would have produced the headline "0 of 10 carriers repaired". That
is the controls-inherit-the-discriminator trap; the tell was a rule appearing on
rows that had nothing to do with it. Verdicts below are `added = xml(mutated) −
xml(baseline)`.

| rule | carrier | verdict | what fires on the XML form |
|---|---|---|---|
| `E-LANE-FIELD` | `id` | CARRIED-WARN | `W-XML-NODE-UNASSIGNED` |
| | `name` | REPAIRED | — |
| | **`authority`** | **CARRIED-WARN** | `W-LANE-NO-OWNER` — **silent before T-331** |
| | `height` | REPAIRED ✓ | — *(the carrier the entry was measured on)* |
| `E-NODE-FIELD` | `uid` | CARRIED-ERROR | `E-XML-FLOW-DANGLING`, `W-XML-NODE-UNASSIGNED` |
| | `type` | CARRIED-ERROR | `E-XML-NODE-TYPE` |
| | `name` | REPAIRED | — |
| | `lane` | CARRIED-WARN | `W-XML-NODE-UNASSIGNED` |
| | `x` | REPAIRED ✓ | — *(the carrier the entry was measured on)* |
| | `y` | INFO | `I-XML-LANE-GEOMETRY-SKIP` (T-312 sentinel) |

**Both declarations are correct for exactly the carrier their fixture omits and
wrong for 6 of the other 8.** Not a coincidence: the fixture is what was
measured, and the claim was recorded against the rule.

### The class the table had no word for

`CARRIED-ERROR` is mis-attribution, not a hole — `uid`/`type` are still caught,
just under another id. `CARRIED-WARN` is different: the YAML form calls it an
**ERROR** and the XML form a **WARN**. A defect that changes severity across the
seam reads as agreement to a harness that classifies by rule-id presence, and as
"repaired" when no id pairs at all.

`authority` is its worst instance. Until `W-LANE-NO-OWNER` shipped in T-331 —
hours before this task — the XML form was **silent** on a missing lane authority
while this table declared it repaired. T-331 closed the silence incidentally;
this task closes the false declaration, which is the half that would have hidden
the next one.

## Verification

python3 tests/test_harness_cross_form_agreement.py
python3 tests/test_rule_form_parity.py
python3 tests/test_rule_dialect_axis.py
python3 tests/test_validate_iw9.py
bash tests/run-validator-tests.sh
# the carrier list is IMPORTED from the validator, never re-typed
grep -q "carriers = set(getattr(vw, source_name))" tests/test_harness_cross_form_agreement.py
# every carrier of both multi-carrier rules has a recorded verdict
# CORRECTED: the first version read m.vw, but the harness binds the validator
# as a FUNCTION-LOCAL (line 286), not a module attribute -- so it raised rather
# than asserting. P-011 caught it; the guard itself was never in doubt.
python3 -c "import importlib.util as I; s=I.spec_from_file_location('h','tests/test_harness_cross_form_agreement.py'); m=I.module_from_spec(s); s.loader.exec_module(m); s2=I.spec_from_file_location('v','tools/validate-workflow.py'); v=I.module_from_spec(s2); s2.loader.exec_module(v); assert set(m.CARRIER_VERDICTS['E-LANE-FIELD'])==set(v.REQUIRED_LANE_FIELDS); assert set(m.CARRIER_VERDICTS['E-NODE-FIELD'])==set(v.REQUIRED_NODE_FIELDS)"
# the declarations state their measured scope rather than implying the rule
grep -q "MEASURED ON .height. ONLY" tests/test_harness_cross_form_agreement.py
grep -q "MEASURED ON .x. ONLY" tests/test_harness_cross_form_agreement.py
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "20 pairs compared, 17 AGREE"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "46 passed, 0 failed"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "66 passed, 0 failed"

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

### 2026-08-02 — the first measurement was contaminated and would have overstated the finding

- **What changed:** run 1 reported CARRIED-OTHER-ID on all 10 carriers, i.e.
  "nothing is repaired". The tell was `W-XML-LANE-GEOMETRY` appearing on rows it
  had no relationship to. The probe document emits it unmutated; the verdicts
  were baseline noise, not consequences of the dropped field.
- **Plan impact:** verdicts recomputed as `xml(mutated) − xml(baseline)`. The
  corrected result is weaker in count (4 of 10 repaired, not 0) and stronger in
  content: the two declarations are right for exactly the carrier each fixture
  omits, which is the actual mechanism of the defect rather than a blanket
  failure.
- **Triggered:** had I reported run 1 to AEF it would have been the third scope
  error on this rail in two days, and mine. Measure the control, then the case.

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

### 2026-08-02T05:53:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-332-bridgerepaired-is-declared-per-rule-id-b.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-620aaf39
- **Timestamp:** 2026-08-02T06:01:58Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-02T06:00:10Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
