---
id: T-902
name: "YAML form has no element-level authority gate — the GAP T-889 declared rather
  than papered over"
description: >
  T-889 added E-XML-META-AUTHORITY (element-level authority vocabulary gate) to the
  XML form only, and classified it GAP in tests/test_rule_form_parity.py PARITY rather
  than PAIRED. The YAML form CAN express element authority: 'authority' is in the
  bridge's META_KEYS (tools/yaml-to-bpmn.py:56), so a step's aef bag may carry it,
  and no YAML rule gates that value against AUTHORITIES. Calling it PAIRED to silence
  the harness would assert a counterpart that does not exist - the exact T-317 one-form-only
  failure the harness catches. Deliverable: either add the YAML-form element gate
  (making the pair PAIRED) or record why the YAML form is out of scope for element
  authority. Do not close by reclassifying the entry.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [arc:designer-authoring-surface]
components: [src/aef-workflow-designer.html, tests/run-bridge-tests.sh, tests/test_rule_dialect_axis.py, tests/test_rule_form_parity.py, tools/_t534-d2-queue-tier-teeth.py, tools/_t889-authority-on-the-element-teeth.sh, tools/validate-workflow.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-27T14:01:28Z
last_update: 2026-09-28T23:37:58Z
date_finished: 2026-09-28T23:37:58Z
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
bvp_scores_proposed: []
bvp_scores:
  D1: 4
  D2: 4
  D3: 3
  D4: 2
  F-RECALL: 2
  F2: 0
  F4: 1
  F3: 0
  F1: 1
confirmed_by: agent:auto (BVP_AUTO_CONFIRM)
confirmed_at: '2026-09-28T23:35:28Z'
cost_estimate_proposed:
  - ts: '2026-09-28T23:37:36Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      blast_radius: 5
      tier: 2
      effort: 8
    rationale: blast_radius=5 (5-components-medium-blast); tier=2 
      (workflow:build); effort=8 (lines=263,acs=9)
    rubric_sha: e4a00f38e801
---

# T-902: YAML form has no element-level authority gate — the GAP T-889 declared rather than papered over

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `tools/validate-workflow.py` gains `E-META-AUTHORITY` on the YAML form: a node whose `aef.authority` is present and not in the module-scope `AUTHORITIES` set is an ERROR naming the node uid and the value, mirroring `E-XML-META-AUTHORITY` — the set is REUSED, not re-listed (T-322: one vocabulary, never a second copy)
- [x] **Absent is silent, present-and-valid is silent:** a node with no `aef.authority`, and a node with `aef.authority: sovereignty`, produce no finding; only an out-of-vocabulary value fires. Pinned by fixtures in both directions, the silent ones first as controls
- [x] **The population the gap covered is measured, not assumed:** the corpus YAML maps that carry node-level `aef.authority` today are enumerated by the teeth (count > 0, proving the carrier is in use) and every one validates clean under the new rule — so the gate lands on real data without a false red
- [x] `tests/test_rule_form_parity.py` reclassifies `E-XML-META-AUTHORITY` from GAP to PAIRED with `E-META-AUTHORITY`, and `EXPECTED_GAPS` moves 13 → 12 with the delta named in the file's own ledger comment and re-derived in `docs/reports/T-320-rule-form-parity-census.md`, as the harness's failure text instructs — not nudged
- [x] `tests/test_rule_dialect_axis.py` registers `E-META-AUTHORITY` with carrier `aef.authority` and polarity CONSTRAINS, matching its XML twin; both parity suites are green after the change
- [x] `tools/_t902-yaml-meta-authority-teeth.sh`: controls first, then the firing case, with a `--mutation` mode that removes the gate from a COPY of the validator and requires the firing case to go red while every control stays green, reporting `MUTATION SETUP BROKEN` if a control dies under the mutant
- [x] **Scope fence recorded:** T-889's clause-2 "element wins" reading in the XML IW-9 check has no YAML twin either (`_check_iw9_authority` reads the lane only, `validate-workflow.py:896`); that is a second gap, filed as an observation and NOT built here — one bug, one task

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

# Teeth: controls (absent silent, valid silent, corpus population clean, vocabulary reused) then the gate; --mutation removes the gate from a copy.
out=$(bash tools/_t902-yaml-meta-authority-teeth.sh 2>&1); echo "$out" | grep -qE '^PASS [0-9]+ / FAIL 0$'
out=$(bash tools/_t902-yaml-meta-authority-teeth.sh --mutation 2>&1); echo "$out" | grep -q 'MUTATION OK'
# Both parity registries agree with the code: the pair is PAIRED, the gap count re-derived, the carrier classed.
python3 -m pytest tests/test_rule_form_parity.py tests/test_rule_dialect_axis.py -q
grep -q '"E-XML-META-AUTHORITY": (PAIRED, "E-META-AUTHORITY")' tests/test_rule_form_parity.py
grep -q '^EXPECTED_GAPS = 12$' tests/test_rule_form_parity.py
grep -q '"E-META-AUTHORITY":         (("aef:meta/@authority",), CONSTRAINS)' tests/test_rule_dialect_axis.py
# The census carries the re-derivation, dated and naming the closed gap.
grep -q '^## 2026-09-29 — EXPECTED_GAPS re-derived, 13 → 12 (T-902)' docs/reports/T-320-rule-form-parity-census.md
# The rule is wired into the YAML dispatch and its body reuses the module-scope set (property, not prose).
grep -q '^        self._check_meta_authority(nodes)$' tools/validate-workflow.py
# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).
#
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

## RCA

**Symptom:** The XML form gated a node's own authority value (`E-XML-META-AUTHORITY`, T-889); the YAML form, which carries the same fact as `aef.authority` on six corpus maps today, gated nothing — the registry said GAP and was right.
**Root cause:** T-889 built one side and, correctly, refused to assert a twin that did not exist. The twin was never built.
**Why structurally allowed:** The parity harness detects a MISclassified pair, not an unbuilt one — a GAP with a reason is a valid state indefinitely. Nothing ages a declared gap.
**Prevention:** The twin now exists and is PAIRED, so the harness holds both forms to the same vocabulary from here on; the census ledger records the close with its arithmetic. The remaining relation-shaped gap (element-wins in the YAML IW-9 check) is filed as its own observation so it cannot hide behind this close.

## Evolution

### 2026-09-29 — the carrier was in use, not merely expressible
- **What changed:** The task's premise was "the YAML form CAN express element authority". Measured: six of the corpus YAML maps already DO — `arc-lifecycle`, `promotion-pipeline`, `task-lifecycle`, `healing-loop`, `inception-review`, `tier0-escalation` carry `aef.authority` on nodes — so the gap was live on real data, and the first control in the teeth is that all six validate clean under the new rule (they do).
- **Plan impact:** One correction from the dialect-axis harness: it names carriers by their STANDARD path whichever form reads them (the YAML `E-AUTHORITY` is registered against `aef:laneMeta/@authority`), so the twin is registered against `aef:meta/@authority`, not `aef.authority`. The harness refused the wrong spelling on the first run, which is the harness working.
- **Triggered:** Observation filed: `_check_iw9_authority` on the YAML form reads the lane only (`validate-workflow.py:896`), so T-889's clause-2 "element wins" has no YAML twin. A relation-shaped gap, not a vocabulary one; not built here.

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
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

### 2026-09-27T14:01:28Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-902-yaml-form-has-no-element-level-authority.md
- **Context:** Initial task creation

### 2026-09-28T23:35:25Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-19e4c220
- **Timestamp:** 2026-09-28T23:38:05Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-28T23:37:58Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
