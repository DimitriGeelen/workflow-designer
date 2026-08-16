---
id: T-330
name: "XML form has no shape checks for lanes or nodes: three YAML required-field
  rules have no BPMN counterpart"
description: >
  T-328 spike finding, filed as one task because it is one family (missing shape validation
  on the BPMN form), not three unrelated bugs. E-LANE-FIELD: a lane missing a required
  field bridges to a <bpmn:lane> with no <aef:laneMeta> at all, and no XmlValidator
  rule requires one. E-LANES-EMPTY: an empty lanes list bridges to an empty <bpmn:laneSet>,
  and no rule requires at least one lane. E-NODE-FIELD: a node missing a required
  field bridges to a flow node without its position, and no rule checks node shape.
  In all three the bridged document STILL CARRIES the defect (distinguishing these
  from E-TOPLEVEL-MISSING, where the bridge repairs it by synthesising bpmn:process
  from workflowMeta.id). Held as counted, printed tolerances in tests/test_harness_cross_form_agreement.py;
  when a hole is closed its entry is DELETED, not decremented. Sibling of T-329 (E-AUTHORITY
  enum, filed separately because its carrier and fix differ).

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tests/test_rule_dialect_axis.py, tests/test_rule_form_parity.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-01T22:55:48Z
last_update: '2026-08-16T14:33:28Z'
date_finished: 2026-08-01T23:32:06Z
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
  - ts: '2026-08-16T14:33:28Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 1
      F3: 4
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=1 (prose:routing/geometry-incidental); 
      F3=4 (prose:seam-fixture-or-pin); F1=1 
      (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:21Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-330: XML form has no shape checks for lanes or nodes: three YAML required-field rules have no BPMN counterpart

## Context

**As filed** (premise, kept verbatim because the correction is the finding):
three of the four genuine coverage holes T-328 measured. The YAML form requires
a shape of every lane (`REQUIRED_LANE_FIELDS`) and every node
(`REQUIRED_NODE_FIELDS`) and errors when it is missing; the BPMN form has no
shape check at all. The bridged document still CARRIES each defect — that is
what separates these three from `E-TOPLEVEL-MISSING`, where the bridge repairs
the document and XML silence is correct.

**As measured** (see `## Spike measurement`): the last sentence is false for two
of the three. The bridge REPAIRS `E-LANE-FIELD` (defaults `height` to 120) and
`E-NODE-FIELD` (defaults the missing coordinate to 0, the T-312 unpositioned
sentinel). Only `E-LANES-EMPTY` is carried through. So this task builds ONE
rule, reclassifies two, and closes the harness blind spot that let a repair be
declared a hole — a `KNOWN_DISAGREEMENT` was answerable only to itself, while
`BRIDGE_REPAIRED` was already answerable to the tree.

The design constraint, and the reason this is not a transliteration job: the
required-carrier set must be DERIVED FROM WHAT THE EMITTERS EMIT, not copied
from the YAML field list. `authority` and `height` are lane fields in YAML but
`aef:laneMeta` attributes in BPMN; `x`/`y` are node fields in YAML but live in
the DI plane in BPMN; `type` is a node field in YAML and is the element tag in
BPMN (already gated by `E-XML-NODE-TYPE`). A rule written from the YAML list
would demand carriers that do not exist on this form and fire on every
conformant document — the T-321 failure mode, where a naive copy of
`NODE_TYPES` hard-failed 8 of our own fixtures. Derivation must be checked
against BOTH emitters (`tools/yaml-to-bpmn.py` and the designer's export):
agreement with one emitter is not agreement.

## Acceptance Criteria

### Agent
- [x] AC1 — The required-carrier sets for lanes and for nodes are MEASURED off
      the corpus and both emitters before any assertion is written, and the
      measurement is recorded in `## Spike measurement` below. Any carrier that
      is absent on a conformant document is excluded, with the reason stated.
- [x] AC2 — `E-XML-LANES-EMPTY`: a `<bpmn:process>` declaring no lane is an
      ERROR on the XML form, counterpart to the YAML form's `E-LANES-EMPTY`.
- [x] AC3 — CORRECTED BY AC1's MEASUREMENT, not dropped for convenience.
      `E-LANE-FIELD` and `E-NODE-FIELD` are NOT coverage holes: the bridge
      REPAIRS both (measured below), so the bridged document carries no defect
      and XML silence is correct. Both are reclassified from
      `KNOWN_DISAGREEMENTS` to `BRIDGE_REPAIRED` with the repair NAMED. No XML
      rule is written for either — writing one would report a conformant
      bridged document as broken, which is the two-outcome defect T-328 exists
      to prevent.
- [x] AC4 — THE BLIND SPOT THAT LET AC3 HAPPEN IS CLOSED. Every
      `KNOWN_DISAGREEMENT` gains an executable CARRIES-probe asserting the
      BRIDGED document still carries the defect. Without it a declared
      tolerance is unfalsifiable in the direction "this tolerance should not
      exist" — the harness sees YAML-fires/XML-silent, finds the entry in the
      table, and reports it as expected, exactly as it did for these two.
- [x] AC5 — SILENCE ON THE CONFORMANT CORPUS: the three new rules produce zero
      findings across every `.bpmn` file in the tree. A shape check that fires
      on documents both emitters produce is a false positive, not a closed
      hole; this AC is what distinguishes the two.
- [x] AC6 — Teeth: each new rule is proven RED by a mutation of a REAL corpus
      document, each mutation asserts it LANDED with an exact count before any
      verdict is read, each red names its OWN rule id (not merely rc!=0), and
      the tree is restored byte-identical.
- [x] AC7 — The three T-330 entries are DELETED from `KNOWN_DISAGREEMENTS` in
      `tests/test_harness_cross_form_agreement.py` — deleted, never
      decremented-with-a-placeholder. `EXPECTED_DISAGREEMENTS` 4 → 1 (only
      `E-AUTHORITY`/T-329 remains), `EXPECTED_REPAIRED` 1 → 3, AGREE 14 → 15.
      `E-LANES-EMPTY` reports AGREE, which is the proof that hole closed.
- [x] AC8 — CORRECTED BY MEASUREMENT. `tests/test_rule_form_parity.py` stays
      green and its gap count does NOT move: all three rules were ALREADY
      classified PAIRED (against `E-XML-STRUCTURE`, which never fires on any of
      these documents), so the census counted zero gaps here while two were
      repairs and one was a live hole. That is parity-proves-existence in its
      purest form and the reason the gap count is the wrong instrument for this
      task. What must change is the recorded counterpart: `E-LANES-EMPTY` now
      names `E-XML-LANES-EMPTY`, and the new rule is registered on both the
      parity census and the T-325 dialect axis.
- [x] AC9 — CORRECTED BY MEASUREMENT. The raised count is on the VALIDATOR
      suite (`tests/run-validator-tests.sh`, 43 → 44, fixtures auto-discovered),
      not the bridge suite, which stays at 66 because no new leg was added.
      Both report 0 failed. Naming the wrong suite here would have been the
      G-013 shape: an honest number whose scope is not in the sentence.

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

Namespace constants IMPORTED from `validate-workflow.py`, never re-typed. The
first run of the measurement hardcoded `AEF_NS = "urn:aef:workflow:1"` and
reported 481 lanes with no `aef:laneMeta` and 2072 nodes with no `aef:uid` —
all false. The tell was that two INDEPENDENT properties failed at the identical
count 2072: identical counts across independent predicates means a shared cause
upstream of both, which was the constant. A probe that fails when the claim is
right (`probes-that-fail-when-right`).

**Carrier presence — 175 files → 174 documents, 481 lanes, 2072 nodes:**

| candidate carrier | offenders | verdict |
|---|---|---|
| lane `@id`, `@name` | 0 | safe |
| `aef:laneMeta@authority`, `@height` | 0 | safe |
| `aef:laneMeta@abbr` | 0 | present everywhere, but NOT required in YAML — EXCLUDED. Universal presence proves a check is safe, never that it is correct; requiring it would make the XML form stricter than the YAML form, a new divergence pointing the other way. |
| node `@id`, `@name`, `aef:uid@value` | 0 | safe |
| `aef:position@x/@y` | 2 | both in `tests/fixtures/aef-bpmn/lane-geometry-unpositioned.bpmn`, the T-312 HONEST-DEGRADATION fixture whose entire purpose is nodes with no position — the geometry rule must SKIP it, not fail it |
| `bpmndi:BPMNShape` / `dc:Bounds` | 2072 | ZERO files carry a DI plane. Position rides `<aef:position>`. A dc:Bounds requirement would have fired on every node in the tree. |

**What the bridge actually emits for the three fixtures — the measurement that
overturned the premise:**

| YAML fixture | defect | bridged BPMN | verdict |
|---|---|---|---|
| `E-LANE-FIELD` — lane `agent` has no `height` | | `<aef:laneMeta abbr="agt" authority="initiative" height="120"/>` | **REPAIRED** — height synthesised |
| `E-NODE-FIELD` — node `n_b` has no `x` | | `<aef:position x="0" y="100"/>` | **REPAIRED** — coordinate defaulted to 0, which is the T-312 unpositioned SENTINEL |
| `E-LANES-EMPTY` — `lanes: []` | | `<bpmn:laneSet>` with zero `<bpmn:lane>` | **CARRIED** — genuine hole |

So of the three holes T-330 was filed to close, exactly ONE is a hole. Two are
bridge repairs I declared as coverage holes in T-328 by reasoning from the YAML
rule instead of measuring the bridged bytes — the same error as `E-EDGE-FIELD`
last session, and the exact inverse of the loaded-gun warning I gave AEF about
inferring repair from silence.

Two kinds of repair are now distinguishable and both make XML silence correct,
but they are not equally benign:
- **repair-by-recovery** (`E-TOPLEVEL-MISSING`): `bpmn:process` reconstructed
  from `workflowMeta.id` — information recovered from the document.
- **repair-by-default** (`E-LANE-FIELD`, `E-NODE-FIELD`): `height=120`, `x=0`
  invented. The document is well-formed and the underspecification is now
  invisible on the BPMN form. The YAML form is the only place it can be seen.

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

# AC2: the new rule fires on its fixture and names itself.
out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-LANES-EMPTY.xml 2>&1); echo "$out" | grep -q "\[E-XML-LANES-EMPTY\]"
# AC5: silence on every .bpmn in the tree. Zero, asserted as a count, not eyeballed.
test "$(for f in $(find . -name '*.bpmn' -not -path './node_modules/*' -not -path './.git/*'); do python3 tools/validate-workflow.py "$f" 2>&1; done | grep -c 'E-XML-LANES-EMPTY')" -eq 0
# AC7: the counts, and the shape of the outcome table.
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "19 pairs compared, 15 AGREE, 1 known DISAGREE"
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "3 bridge-repaired, 1 untestable"
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "cross-form agreement: OK"
# AC3/AC7: the two reclassified rules are BRIDGE_REPAIRED and gone from the tolerances.
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "BRIDGE_REPAIRED  E-LANE-FIELD"
out=$(python3 tests/test_harness_cross_form_agreement.py 2>&1); echo "$out" | grep -q "BRIDGE_REPAIRED  E-NODE-FIELD"
test "$(grep -c 'T-330' tests/test_harness_cross_form_agreement.py)" -eq 4
# AC4: the CARRIES-probe exists and is wired into the DISAGREE branch.
grep -q "_carries_out_of_enum_authority" tests/test_harness_cross_form_agreement.py
# Anchored on a literal that is CONTIGUOUS IN THE SOURCE. The first version of
# this line grepped "does NOT carry the defect", which exists only after runtime
# string concatenation ("...document does " + "NOT carry the defect...") — the
# teeth leg matched it because teeth read the OUTPUT, and P-011 caught it
# because this reads the FILE. Same anchor discipline, two different haystacks.
grep -q "NOT carry the defect" tests/test_harness_cross_form_agreement.py
# AC8: both censuses green, gap count deliberately unmoved, new rule registered.
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "47 rules classified, 11 gaps"
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "rule-form parity: OK"
out=$(python3 tests/test_rule_dialect_axis.py 2>&1); echo "$out" | grep -q "47 validator rules classified"
# AC9: both gating suites, 0 failed, counts named with their own subject.
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -q "44 passed, 0 failed"
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

### 2026-08-01T22:55:48Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-330-xml-form-has-no-shape-checks-for-lanes-o.md
- **Context:** Initial task creation

### 2026-08-01T23:12:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-15c281d4
- **Timestamp:** 2026-08-01T23:34:01Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-01T23:32:06Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
