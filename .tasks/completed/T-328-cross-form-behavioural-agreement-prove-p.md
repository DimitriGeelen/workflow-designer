---
id: T-328
name: "Cross-form behavioural agreement: prove paired validator rules AGREE, not merely
  that both forms name them"
description: >
  The T-320 parity guard extracts rule IDs from each validator class's source span
  and never validates a document, so PAIRED proves both forms NAME a rule, never that
  the two implementations agree about when it fires. T-309 IW-2 found a live latent
  instance: W-GW-AMBIGUOUS tests falsy (not e.get('condition')) while W-XML-GW-AMBIGUOUS
  tests existence (find(conditionExpression) is None), so an empty condition reads
  unconditioned on one form and conditioned on the other. Currently unreachable (both
  emitters truthiness-gated, 0 empty elements in 100 carrying files) and therefore
  latent, not dead. Build a harness that drives the SAME document through both forms
  via yaml-to-bpmn.py and asserts the paired rules return the same verdict.

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
created: 2026-08-01T22:43:26Z
last_update: '2026-08-16T13:57:21Z'
date_finished: 2026-08-01T23:01:01Z
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
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tests/run-bridge-tests.sh,tests/test_harness_cross_form_agreement.py,tests/test_rule_form_parity.py,tools/yaml-to-bpmn.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-328: Cross-form behavioural agreement: prove paired validator rules AGREE, not merely that both forms name them

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Spike measurement (2026-08-02) — run BEFORE the harness existed

19 yaml-side PAIRED rules; 18 have a fixture (`E-NOT-MAPPING` has none and is untestable in
principle — YAML that is not a mapping cannot be bridged at all). All 18 convert through
`tools/yaml-to-bpmn.py` with rc=0, which is itself notable: **the bridge happily converts documents
the YAML validator calls invalid.**

Driving each fixture through both forms: **12 AGREE, 6 do not.** The 6 are not one class, and
calling them "6 disagreements" would be the coarse-number error this arc keeps paying for:

| rule | does the bridged doc still carry the defect? | verdict |
|---|---|---|
| `E-TOPLEVEL-MISSING` | **no — bridge REPAIRS it**, synthesising `<bpmn:process id="Pool_t" name="t">` from `workflowMeta.id` | XML silence is CORRECT |
| `E-EDGE-FIELD` | yes | caught, but under a **different id** (`E-XML-FLOW-DANGLING`, + deadend/unreachable) → the pair table names the wrong counterpart |
| `E-LANE-FIELD` | yes — lane emitted with no `<aef:laneMeta>` at all | **genuine XML coverage hole** |
| `E-LANES-EMPTY` | yes — empty `<bpmn:laneSet>` emitted | **genuine XML coverage hole** |
| `E-NODE-FIELD` | yes — node emitted without its position | **genuine XML coverage hole** |
| `E-AUTHORITY` | yes — `authority="overlord"` carried faithfully into `<aef:laneMeta>` | **genuine XML coverage hole** |

**So: 4 genuine holes, 1 mis-pairing, 1 correct-by-repair.** Every one of the six was invisible to
`tests/test_rule_form_parity.py`, which is green on all of them because both ids exist.

**The one to escalate: `E-AUTHORITY`.** An `authority` value outside the §5 enum passes the BPMN
form entirely. That is IW-9 governance data, and BPMN is the form the designer authors and the form
AEF consumes — so the check exists only on the form neither of them uses. Rail-worthy, and a
candidate for its own build task rather than a fix folded in here (one bug = one task).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

- [x] **AC1 — The pair table is DECLARED, never parsed out of `PARITY`'s prose.** Measured first
      (PL-071): `PARITY`'s counterpart field is free text — `E-XML-STRUCTURE` covers six YAML rules
      as `"E-NOT-MAPPING / E-TOPLEVEL-MISSING / *-FIELD"`, and entries carry parentheticals such as
      `"W-XML-GW-AMBIGUOUS (T-317)"`. Parsing that is the anchor-in-prose defect (four instances this
      arc). The harness declares its own `{yaml_rule: {xml_rule, ...}}` table.

- [x] **AC2 — That table is drift-guarded BIDIRECTIONALLY against `PARITY`.** Every rule classified
      PAIRED/PAIRED_SAME_ID in `PARITY` must appear in the pair table, and every pair-table entry
      must be PAIRED in `PARITY`. Adding a paired rule without deciding its behavioural status fails
      the build. A table that could silently omit a rule would report agreement it never tested.

- [x] **AC3 — For every behaviourally-testable pair, the SAME document is driven through both forms
      and the verdict is one of THREE outcomes, not two.** A YAML document that fires the YAML rule
      is converted via `tools/yaml-to-bpmn.py`; both validators run. 1:many pairs compare at set
      level — form A reports some member of the pair-set iff form B does.
      **AC3 was rewritten after the spike measured the real surface (PL-071, second time this task).**
      As first written it asserted "the verdicts must match", which is WRONG: for
      `E-TOPLEVEL-MISSING` the bridge *repairs* the defect (it synthesises
      `<bpmn:process id="Pool_t">` from `workflowMeta.id`), so the bridged document is genuinely
      clean and XML silence is CORRECT. A two-outcome harness reports that as a defect — a probe
      that fails when the code is right. The three outcomes are:
      - **AGREE** — both forms fire, or both are legitimately silent.
      - **DISAGREE** — the bridged document still CARRIES the defect and the XML form is silent.
        This is the finding class.
      - **BRIDGE-REPAIRED** — the bridged document no longer carries the defect. Declared per pair
        with the repair named, never inferred at runtime from "XML said nothing".

- [x] **AC4 — Untestable pairs are DECLARED with a reason, PRINTED every run, and COUNT-ASSERTED.**
      Some pairs have no reachable cross-form document (`E-NOT-MAPPING` fires on YAML that is not a
      mapping, which cannot be bridged at all). Untestable is a legitimate verdict; an *unbounded*
      untestable set is not. Count asserted so the set cannot grow silently into a blanket exemption
      (T-324 discipline: a tolerance is counted and printed, or it is a suppression).

- [x] **AC5 — Teeth prove the harness DISCRIMINATES, not merely that it fires (PL-070).** Mutate one
      implementation's predicate so the two genuinely disagree → harness RED, and the failure text
      must NAME the disagreeing pair and the direction (which form fired). A red that only exits
      non-zero proves the harness runs, not that it compares. Every mutation asserts it LANDED with
      an exact occurrence count before any verdict is read (probes-that-fail-when-right), and the
      tree is restored byte-identical.

- [x] **AC6 — Negative control: the unmutated tree is GREEN, and the green is falsifiable.** Includes
      the (0) branch — if the pair table or the fixture set resolves empty, the harness must RAISE
      rather than pass, since an empty comparison set trivially satisfies every assertion above.

- [x] **AC7 — Wired into the GATING runner** (`tests/run-bridge-tests.sh`), not merely present on
      disk — T-316's lesson: a suite nobody runs cannot report a failure. Bridge leg count 65 → 66.

- [x] **AC8 — The known latent divergence is dispositioned explicitly, not left implicit.**
      `W-GW-AMBIGUOUS` tests falsy (`:417`), `W-XML-GW-AMBIGUOUS` tests existence (`:949`). Either
      the predicates are aligned, or the divergence is declared latent with its reachability
      condition recorded (both emitters truthiness-gated; 0 empty elements in 100 carrying files).
      Silently leaving it undeclared is what kept it invisible for the whole arc so far.

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
#
# T-328 verification. Anchored on structural literals with EXACT counts — never
# `grep -qv` (which inverts per LINE and succeeds whenever any single line lacks
# the pattern) and never a bare rule token (which matches prose, filenames and
# our own canonical type names). Capture-then-grep per L-387.

# 1. the guard itself is green
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "cross-form agreement: OK"

# 2. the counts are the measured ones, not merely "some number"
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "19 pairs compared, 14 AGREE, 4 known DISAGREE"

# 3. wired into the GATING runner exactly once (T-316: on disk is not wired)
test "$(grep -c 'test_harness_cross_form_agreement.py' tests/run-bridge-tests.sh)" -eq 1

# 4. every declared tolerance cites an OPEN task — a tolerance citing nothing is a suppression
test "$(ls .tasks/active/ | grep -cE '^T-329-|^T-330-')" -eq 2

# 5. the whole gating suite, with this leg counted in
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "bridge round-trip: 66 passed, 0 failed"
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

### 2026-08-01T22:43:26Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-328-cross-form-behavioural-agreement-prove-p.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-e4125c5f
- **Timestamp:** 2026-08-01T23:02:27Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-01T23:01:01Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
