---
id: T-199
name: "O-3 hole: a laneSet-less process silently accepts an inception — fix the early return + lock every absent-authority case"
description: >
  BUG in T-196's _check_iw9_authority (tools/validate-workflow.py): it opens with `if lane_set is None: return`, so a process carrying NO bpmn:laneSet at all skips O-3 entirely and an inception is ACCEPTED — the single case with no authority signal whatsoever is the one case not checked. Verified: (a) lane named 'Human' with no laneMeta -> ERROR, (b) laneMeta without @authority -> ERROR, (d) authority=external -> ERROR, (e) inception outside every lane -> ERROR, but (c) NO laneSet -> *** ACCEPTED ***. This makes 832's reference validator MORE LENIENT than AEF's compiler, which already fail-fasts on 'no lane / no human signal at all' (their offset 48) — and 832 vetoed AEF's name-only leniency on rail offset 49 while carrying a wider hole of its own. Fix the early return so an absent laneSet yields absent authority (=> O-3 ERROR), keep O-1 WARN quiet for lane-less diagrams (authority None is not a mismatch), and lock every absent-authority case in tests/test_validate_iw9.py so the ruling issued to AEF is guarded rather than asserted. PL-034 class — a promise with no guard.

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [arc:designer-authoring-surface, conformance]
components: []
related_tasks: [T-196, T-189, T-195]
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-17T10:58:04Z
last_update: 2026-07-17T10:59:16Z
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

# T-199: Lock the O-3 name-only-lane reading with regression tests (conformance ruling issued to AEF)

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] `_check_iw9_authority` no longer returns early on a missing `bpmn:laneSet`: an inception in a laneSet-less process raises `E-INCEPTION-NOT-SOVEREIGN` (absent laneSet ⇒ absent authority ⇒ not sovereignty)
- [x] O-1 stays quiet for lane-less diagrams: a `serviceTask`/`userTask`/`scriptTask` in a process with no laneSet emits NO `W-TYPE-LANE-MISMATCH` (absent authority is not a disagreement — there is nothing to disagree with) — locked by case (l)
- [x] `tests/test_validate_iw9.py` locks every absent-authority path, each asserted independently: (f) lane named "Human" with no `laneMeta`, (g) `laneMeta` present without `@authority`, (h) NO `laneSet` at all, (i) `authority="external"`, (j) inception outside every lane — all ⇒ `E-INCEPTION-NOT-SOVEREIGN`
- [x] Positive control still passes: `authority="sovereignty"` ⇒ no O-3 finding — cases (a)/(b2) green, `inception-gonogo.bpmn` still exit 0
- [x] The block message names the absent-authority cause ("its lane authority is absent" vs "is 'initiative'") — locked by case (k)
- [x] Test proves it is a real test: against the pre-fix validator from `git show HEAD:tools/validate-workflow.py` it reports 2 failures — `(h/no-laneSet-at-all) inception ... was ACCEPTED — O-3 not enforced` and `(k) ... does not name the cause`; against the fixed validator all 14 pass
- [x] Zero corpus regression: 5/5 BPMN fixtures exit 0, 24/24 rendered maps exit 0, full suite green (12/12)
- [x] The reading issued to AEF on rail offset 49 is now guarded by (f)+(g), not merely asserted

**Evidence.** All 8 verified 2026-07-17. `OK: IW-9 validator rules (O-1
W-TYPE-LANE-MISMATCH, O-3 E-INCEPTION-NOT-SOVEREIGN) — 14 checks pass, incl. the
full absent-authority family (T-199)`.

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

python3 tests/test_validate_iw9.py
for f in tests/fixtures/aef-bpmn/*.bpmn; do python3 tools/validate-workflow.py "$f" >/dev/null 2>&1 || exit 1; done
for f in examples/aef-processes/rendered/*.bpmn; do python3 tools/validate-workflow.py "$f" >/dev/null 2>&1 || exit 1; done
python3 tests/test_mapping_standard_conformance.py
python3 tests/test_forward_fixtures.py

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

**Symptom:** A BPMN process carrying an inception (`subProcess` with
`aef:meta workflowType="inception"`) but NO `bpmn:laneSet` at all validated
clean — exit 0, no findings. Every *other* absent-authority shape was correctly
rejected (name-only lane, `laneMeta` without `@authority`, `authority="external"`,
inception outside every lane), so the one diagram with no human signal whatsoever
was the only one that passed.

**Root cause:** `tools/validate-workflow.py:_check_iw9_authority` (shipped by
T-196) opened with `lane_set = process.find(...); if lane_set is None: return`.
The guard was written as "no lanes ⇒ nothing to check about lanes", which is true
for O-1 (a *comparison* between task-type and lane needs a lane) but false for
O-3 (an *existence* requirement: §7 demands a sovereignty lane, and no lane means
that demand is unmet). Conflating "nothing to compare" with "nothing to enforce"
inverted the rule at its most severe input: the check got weaker as the evidence
got worse.

**Why structurally allowed:** T-196's tests covered wrong-authority
(`authority="initiative"`) but never absent-authority. Absent-authority reads as
a *milder* case than wrong-authority — a gap, not a violation — so it was never
written down as a case to test. IW-9 v1.1 says the opposite in one word:
`aef:laneMeta authority` is the **SOLE** authority-of-record, so absent authority
is not a weaker signal than wrong authority, it is the same failure. The standard
was unambiguous; the test suite simply never asked. Nothing forced the
enumeration of the closed value set's *empty* case, and a corpus where 80/80
lanes carry explicit authority meant no fixture could ever expose it.

**Prevention:** The absent-authority family is now enumerated and locked as
cases (f)–(j) plus (k) cause-naming and (l) the O-1 no-false-positive control —
proven real by running them against the pre-fix validator (2 failures). The
durable lesson is PL-035, not the five test cases: when a spec makes X the *sole*
source of a decision, absence of X is a violation of the same severity as a wrong
X, and the absent case is the one nobody writes a fixture for.

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

### 2026-07-17 — the ruling we issued is what exposed the hole in ourselves
- **What changed:** This task was filed to *lock* a reading 832 had already issued
  to AEF (rail offset 49: a name-only "Human" lane MUST hard-fail). Writing the
  test cases — rather than trusting the ruling — surfaced that 832's own validator
  had a wider hole than the leniency it had just vetoed: a laneSet-less process
  accepted an inception outright. AEF's compiler already fail-fasts there (their
  offset 48, "no lane / no human signal at all -> FAIL FAST"). We were stricter
  than them in prose and more permissive in code.
- **Plan impact:** Scope moved from test-only (`workflow_type: test`) to a real
  bug fix (`build`) with an RCA. The ruling itself survives unchanged — it was
  correct; only our implementation of it was incomplete.
- **Triggered:** Fix to `_check_iw9_authority`'s early return; 7 new locked cases;
  PL-035 (sole-source specs make absence a violation, and absence is the case
  nobody fixtures). AEF owed a correction notice on the rail — we vetoed their
  leniency while carrying a bigger one, and they should hear that from us.

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

### 2026-07-17T10:58:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-199-lock-the-o-3-name-only-lane-reading-with.md
- **Context:** Initial task creation

### 2026-07-17T10:59:16Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
