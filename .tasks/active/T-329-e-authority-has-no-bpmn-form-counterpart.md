---
id: T-329
name: "E-AUTHORITY has no BPMN-form counterpart: an out-of-enum IW-9 lane authority passes the form the designer and AEF both use"
description: >
  T-328 spike finding. The YAML validator rejects a lane authority outside the section 5 enum (E-AUTHORITY, tools/validate-workflow.py:_check_lanes). yaml-to-bpmn.py carries the bad value faithfully into <aef:laneMeta authority='overlord'/>, and NO XmlValidator rule inspects it -- the bridged document validates clean. So the check exists only on the canonical YAML form, while BPMN is the form the designer authors and the form AEF consumes. tests/test_rule_form_parity.py is green on this because it compares rule IDs and never validates a document; PARITY pairs E-AUTHORITY with 'E-INCEPTION-NOT-SOVEREIGN / laneMeta authority', a pairing the behavioural measurement shows does not hold. This is IW-9 governance data (O-1/O-3 family, PL-035 territory), so a silent pass is a governance gap rather than a lint gap. Fix is an XmlValidator rule reading aef:laneMeta/@authority against the same enum, single-sourced from the YAML side rather than a second copy of the enum.

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
created: 2026-08-01T22:49:21Z
last_update: 2026-08-01T23:35:22Z
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

# T-329: E-AUTHORITY has no BPMN-form counterpart: an out-of-enum IW-9 lane authority passes the form the designer and AEF both use

## Context

The YAML form errors when a lane's `authority` is outside the §5 enum
(`E-AUTHORITY`, `validate-workflow.py:294`). The BPMN form has no such rule:
`yaml-to-bpmn.py` carries `authority="overlord"` faithfully into
`<aef:laneMeta>` and no `XmlValidator` rule reads it. After T-330 this is the
LAST remaining entry in the cross-form harness's `KNOWN_DISAGREEMENTS`, and its
CARRIES-probe confirms the bridged document still carries the defect.

**Scope correction from the rail (AEF 371).** T-328 reported this as "passes
the form the designer AND AEF both use". That is wrong about their consumer:
`bpmn_to_tasks.py` hard-fails an inception subProcess outside a sovereignty
lane and WARNs on any authority outside its `AUTHORITY_OWNER` map. They ran the
`overlord` document and got a warning naming the lane, the value and every
affected node. So the hole is OURS alone — it is our XmlValidator that is
blind, not the seam. The task stands; its blast radius does not.

**Design constraint, carried from T-322 and non-negotiable:** the enum must be
read from the existing module-scope `AUTHORITIES`, never copied into the XML
class. A second copy would let the two forms drift on the governance question
itself, which is the defect T-322 exists to close — and a copied enum is
exactly how the "one form only" family reproduces itself one level down.

## Acceptance Criteria

### Agent
- [x] AC1 — `E-XML-AUTHORITY`: a `<aef:laneMeta authority="...">` value outside
      `AUTHORITIES` is an ERROR on the XML form, naming the lane and the value.
- [x] AC2 — SINGLE-SOURCED: the rule reads the module-scope `AUTHORITIES` set
      directly. Verified structurally, not by eye: `AUTHORITIES` is defined
      exactly once and exactly two call sites test membership against it, one
      per form.
      CORRECTED — as first written this AC said "no second literal listing of
      the authority vocabulary exists anywhere", and the teeth probe built from
      that wording went red on 5 occurrences of `"sovereignty"`, all legitimate:
      O-3 compares against that ONE value (`authority != "sovereignty"`) and the
      rest are docstrings. Comparing to a single member is not re-listing a
      vocabulary, so the probe failed while the claim was right. The property
      the AC is actually about is the SET, not the words.
- [x] AC3 — SILENCE ON THE CONFORMANT CORPUS: zero findings across every
      `.bpmn` in the tree, asserted as a count. Measured BEFORE the assertion is
      written, per the T-330 order: what the emitters actually put on a lane
      decides the rule, not what the YAML field list says.
- [x] AC4 — Fixture in `tests/fixtures/invalid/` demonstrating the rule, picked
      up by the validator suite (44 → 45), so the rule is exercised rather than
      merely present.
- [x] AC5 — Registered on BOTH censuses: PAIRED in `test_rule_form_parity.py`
      against `E-AUTHORITY`, and carrier-classified in `test_rule_dialect_axis.py`.
      `aef:laneMeta/@authority` is already SEMANTIC_MUST there, so the XML rule
      must land UNIVERSAL — if it classifies otherwise, the two forms disagree
      about what kind of claim the same rule makes and that is a finding, not a
      table to adjust.
- [x] AC6 — `E-AUTHORITY` is DELETED from `KNOWN_DISAGREEMENTS` in
      `tests/test_harness_cross_form_agreement.py` — deleted, not decremented —
      `EXPECTED_DISAGREEMENTS` 1 → 0, and the pair reports AGREE. With this the
      table is empty: every remaining cross-form difference is either a declared
      repair or declared untestable.
- [x] AC7 — The empty-table case is not left to trivially pass. With
      `KNOWN_DISAGREEMENTS` empty, a NEW disagreement must still fail the build,
      and a teeth leg proves it (the T-328 `PAIRS = {}` lesson: an empty
      collection satisfies every assertion written over it).
- [x] AC8 — Teeth: the new rule proven RED by mutation, landing-asserted with an
      exact count, each red naming its OWN rule id, tree restored byte-identical.

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


# AC1/AC4: the rule fires on its fixture, which is itself emitter-produced
# (generated by yaml-to-bpmn.py from the YAML twin, per T-327).
out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-AUTHORITY.xml 2>&1); echo "$out" | grep -q "\[E-XML-AUTHORITY\]"
# AC2: single-sourced. One definition of the set, both forms reading it.
test "$(grep -c '^AUTHORITIES = ' tools/validate-workflow.py)" -eq 1
test "$(grep -c 'not in AUTHORITIES' tools/validate-workflow.py)" -eq 2
# AC3: silence across every .bpmn in the tree, asserted as a count.
test "$(for f in $(find . -name '*.bpmn' -not -path './node_modules/*' -not -path './.git/*'); do python3 tools/validate-workflow.py "$f" 2>&1; done | grep -c 'E-XML-AUTHORITY')" -eq 0
# AC6: the tolerance table is EMPTY and the harness says so in its own numbers.
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "19 pairs compared, 16 AGREE, 0 known DISAGREE"
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "cross-form agreement: OK"
grep -q "^KNOWN_DISAGREEMENTS = {}" tests/test_harness_cross_form_agreement.py
grep -q "^EXPECTED_DISAGREEMENTS = 0" tests/test_harness_cross_form_agreement.py
# AC5: registered on both censuses; the XML rule lands UNIVERSAL like its twin.
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "48 rules classified, 11 gaps"
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "rule-form parity: OK"
out=$(python3 tests/test_rule_dialect_axis.py 2>&1); echo "$out" | grep -q "41 universal"
# Both gating suites, each count named with its own subject.
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "45 passed, 0 failed"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -q "bridge round-trip: 66 passed, 0 failed"

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

### 2026-08-01T22:49:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-329-e-authority-has-no-bpmn-form-counterpart.md
- **Context:** Initial task creation

### 2026-08-01T23:35:22Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
