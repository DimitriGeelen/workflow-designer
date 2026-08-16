---
id: T-320
name: "Rule-form parity census: validator rules that exist on one form and not the
  other (T-317 generalization)"
description: >
  T-317 found W-XML-GW-AMBIGUOUS missing on the XML form while the YAML form had it,
  and the gap was concealing a live instance of itself (investigate.bpmn sat in fixtures/valid/
  asserting a cleanliness no rule could evaluate on its form). That is a class, not
  a site. Census every rule on both validator forms; classify each asymmetry as correctly-out-of-scope
  (the other form does not carry the construct, measured) or GAP (it does). File each
  real GAP as its own task, and leave behind a parity guard so a rule added to one
  form without a parity decision fails the build.

status: work-completed
workflow_type: build
owner: claude-code
horizon:
tags: []
components: [tests/test_rule_form_parity.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T12:05:57Z
last_update: '2026-08-16T14:33:27Z'
date_finished: 2026-07-31T12:21:42Z
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
  - ts: '2026-08-16T12:33:49Z'
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
  - ts: '2026-08-16T14:33:27Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 4
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F2=0 (no-signal); F4=4 
      (prose:routing-structural); F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:20Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 1
    rationale: blast_radius=1 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-320: Rule-form parity census: validator rules that exist on one form and not the other (T-317 generalization)

## Context

T-317 added `W-XML-GW-AMBIGUOUS` because the YAML form had a branch-ambiguity rule
and the XML form did not. The gap was concealing a live instance of itself:
`tests/fixtures/valid/investigate.bpmn` had silently dropped both gateway conditions
its YAML twin carries, and sat in `fixtures/valid/` asserting a cleanliness that no
rule could evaluate on its form. That is a class, not a site (G-009: a copy-paste
defect class needs a tree sweep). AEF independently reached the same conclusion on
their side at rail 354 and is sweeping in parallel — method posted at rail 355 before
results, deliberately, so we do not inherit each other's blind spot in the method.

**Discriminator (this is the whole task).** Asymmetry is NOT the finding. The test
is whether the OTHER form carries the CONSTRUCT the rule describes:

- asymmetric + construct absent on the other form  → correctly out of scope
- asymmetric + construct PRESENT on the other form → GAP; files on that form can
  assert a cleanliness that was never evaluable

Decided by measuring the corpus, not by taste — same method that settled T-317's
labelled-branch question at 0 of 113.

**Live-violation count is priority, not classification.** A gap with zero current
violations is still a gap: the absence of a rule is what makes the absence of
violations unfalsifiable.

> The paragraph that stood here at filing used `W-XML-LANE-GEOMETRY` as the
> canonical out-of-scope case, "because YAML carries no coordinates". That was
> false and it was also posted to AEF. See the first Evolution entry — the
> correction is the most useful thing this task produced.

Related: PL-030 (aspect-by-aspect seam guards can all pass while the seam is broken),
PL-035 (when a spec names X the sole source of a decision, ABSENCE of X is a
violation), PL-034 (self-consistency cannot detect a broken promise).

## Acceptance Criteria

### Agent
- [x] Census enumerates every rule id emitted by BOTH `Validator` (YAML form) and
      `XmlValidator` (XML form) in `tools/validate-workflow.py`, extracted
      mechanically from the emit sites — not hand-listed, so it cannot drift
      → 45 rules classified (26 YAML + 19 XML), scraped by `EMIT` regex
- [x] Every rule appears in exactly one bucket: PAIRED, OUT-OF-SCOPE (with the
      measured evidence that the other form does not carry the construct), or GAP
      → 34 PAIRED, 3 OUT-OF-SCOPE, 11 GAP (8 gap families)
- [x] Each OUT-OF-SCOPE classification carries a corpus MEASUREMENT, not an
      assertion — a count of how many corpus files on the other form carry the
      construct, and that count is 0
      → only the `scopeOf` family qualifies: 0 of 96 authored BPMN. Re-measured
      every run, not recorded once
- [x] **AMENDED MID-TASK** — every GAP is registered in the enforced `PARITY`
      table (printed as a NOTE each run, count asserted); tasks filed for the two
      actionable ones (T-321, T-322) rather than all eight. Rationale in Evolution
- [x] A parity guard exists as a test wired into the gating runner
      (`tests/run-bridge-tests.sh`) that fails when a rule id is added to either
      form without a parity classification
      → `tests/test_rule_form_parity.py`, bridge leg added
- [x] The parity guard is proven RED by mutation on the REAL tree: adding a rule
      emit to one form without classifying it fails the guard (PL-061 teeth)
      → two mutations of `tools/validate-workflow.py`, both RED, tree restored
- [x] The guard is unevaluable-is-RED: if either validator class cannot be located
      or yields zero rules, the guard errors rather than passing quiet (T-312 class)
      → negative controls (d) and (e)
- [x] Bridge suite green with the new leg; validator suite green; corpus geometry
      sweep unchanged
      → bridge 62/0 (was 61), validator 38/0, geometry 24 clean

## Evidence

**Census:** `docs/reports/T-320-rule-form-parity-census.md`.
26 YAML rules, 19 XML rules, 11 pair cleanly. Residue measured over 25 canonical
YAML maps and 96 authored BPMN: **8 gap families, exactly 1 correctly out of
scope** (`scopeOf`, 0/96 — the only classification resting on a measured zero
rather than an argument).

**The gap runs both directions**, which I did not expect at filing.
`W-TYPE-LANE-MISMATCH` and `E-INCEPTION-NOT-SOVEREIGN` — the IW-9 rules deciding
whether an inception is human-sovereign — exist on the XML form and have no
counterpart on the canonical YAML form. Filed as T-322.

**Live hole proven by mutation.** `<bpmn:serviceTask>` → `<bpmn:serviceTaks>` in
`tests/fixtures/valid/investigate.bpmn` yields `VALID -- no findings`, rc=0. No
node-type vocabulary gate on the XML form at all. The only witness is an
`I-XML-LANE-CAPACITY-SKIP` note from the lane-capacity rule, which noticed solely
because T-313 built it to refuse to guess an occupancy it does not know — an
unrelated rule's unevaluable-must-be-visible discipline leaking a detector for a
class nobody designed for. Filed as T-321, with the constraint that the fix is
**not** a copy of `NODE_TYPES` (the XML vocabulary is a genuine superset: 19
catch/throw/boundary occurrences across 8 deliberate fixtures).

**Guard teeth, on the real tree, both directions:**
- added `self.warn("W-XML-MUTANT-PROBE", …)` to `XmlValidator` → FAIL naming it, rc=1
- renamed `W-XML-DEADEND` → `…-RENAMED` → two FAILs (unclassified new id *and*
  stale classification inflating the gap count), rc=1
- tree restored byte-clean after each (`git diff --stat` empty), guard green again

**Five negative controls**, all passing: (a) unclassified rule RED, (b) an
OUT-OF-SCOPE classification whose construct has appeared RED — the anti-staleness
property, (c) OUT-OF-SCOPE with no probe RED (unfalsifiable classification
rejected), (d) validator with no locatable rule classes RED, (e) missing validator
RED.

**T-316 caught this file as an orphan** before it was wired — second real (not
synthetic) catch in two days.

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
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "^rule-form parity: OK$"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -qE "^bridge round-trip: [0-9]+ passed, 0 failed$"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -qE "^== summary: [0-9]+ passed, 0 failed ==$"
# the parity leg is actually wired into the GATING runner, not merely present
grep -q "tests/test_rule_form_parity.py" tests/run-bridge-tests.sh
# the census artifact backing every classification exists
test -f docs/reports/T-320-rule-form-parity-census.md

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

### 2026-07-31 — the discriminator was wrong, and I had already posted it

- **What changed:** I filed this task and posted the method to AEF (rail 355) using
  `W-XML-LANE-GEOMETRY` as the canonical example of *correctly out of scope*, on
  the grounds that "YAML carries no coordinates." That is false — the canonical
  YAML form carries `x`, `y` on every node and `height` on every lane. What I
  actually had was an older measurement, *0 violations today*, which I collapsed
  into *out of scope*.
- **Plan impact:** the discriminator needed splitting into two axes. Construct
  carried → classification (GAP vs out-of-scope). Violations today → priority
  only, never classification. Under the corrected rule, lane geometry is a GAP
  with 0 live violations, and the out-of-scope bucket shrank from "several
  obvious ones" to exactly one family.
- **Triggered:** the `OUT_OF_SCOPE_PROBES` mechanism — every out-of-scope claim
  must name a probe and is re-measured each run. An unfalsifiable classification
  is now itself a failure (control c). Correction owed to AEF on the rail.
- **Note:** this is the same move AEF made at rail 354 in the other direction
  ("not in the latest tag" collapsed into "not published"). Two instances, one
  week apart, opposite directions, same shape: **a measurement that supports a
  weaker claim, silently promoted to a stronger one.** The measurement is honest
  both times; the promotion is not measured at all.

### 2026-07-31 — AC amended: register-in-guard instead of eight task files

- **What changed:** the filed AC said "each GAP is filed as its own task (one gap
  = one task)". Eight task files whose content is a row of a table would go stale
  the moment the table moved, and the framework's own lesson from T-317 is that a
  register living where nothing executes stops being enforced.
- **Plan impact:** all 11 gaps are registered in the `PARITY` table, which prints
  every gap as a NOTE on every run and asserts the count — a counted tolerance in
  a place that still executes. Tasks filed only for the two actionable gaps:
  **T-321** (XML node-type vocabulary hole, proven live) and **T-322** (IW-9
  authority rules missing on the YAML form, governance-bearing).
- **Triggered:** T-321, T-322. The other six families stay in the table only, and
  the AC is marked AMENDED rather than silently reinterpreted — a scope change is
  the operator's to see, not mine to absorb.

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

### 2026-07-31T12:05:57Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-320-rule-form-parity-census-validator-rules-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-b9ffc49f
- **Timestamp:** 2026-07-31T12:23:03Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-07-31T12:21:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
