---
id: T-321
name: "XML form has no node-type vocabulary gate: a typo'd element validates clean (T-320 gap)"
description: >
  T-320 proved by mutation on tests/fixtures/valid/investigate.bpmn that renaming <bpmn:serviceTask> to <bpmn:serviceTaks> yields 'VALID -- no findings', rc=0. E-NODE-TYPE exists on the YAML form only; the XML form has no vocabulary gate at all. The fix is NOT a copy of NODE_TYPES: porting NODE_TYPES verbatim would hard-fail eight of our own fixtures. (Filing called the XML vocabulary a genuine superset; measured, it is a TRANSLATION of NODE_TYPES plus exactly one extension, boundaryEvent -- corrected in Evolution.) Requires a declared XML vocabulary. Note the only current witness to a bogus type is an I-XML-LANE-CAPACITY-SKIP note from an unrelated rule that refuses to guess occupancy.

status: work-completed
workflow_type: build
owner: claude-code
horizon: null
tags: []
components: [tests/fixtures/invalid/E-XML-NODE-TYPE.xml, tests/test_rule_form_parity.py, tests/test_xml_node_type_vocab.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-31T12:15:56Z
last_update: 2026-08-01T13:55:03Z
date_finished: 2026-08-01T13:55:03Z
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

# T-321: XML form has no node-type vocabulary gate: a typo'd element validates clean (T-320 gap)

## Context

The last open gap from the T-320 census (`docs/reports/T-320-rule-form-parity-census.md`),
and the one with a live hole rather than a theoretical one: renaming `<bpmn:serviceTask>` to
`<bpmn:serviceTaks>` in `tests/fixtures/valid/investigate.bpmn` yields `VALID — no findings`,
rc=0. `E-NODE-TYPE` gates the YAML form; the XML form has **no vocabulary gate at all**.

**The obvious fix is wrong, and that is the whole difficulty.** Copying `NODE_TYPES` across
would hard-fail eight of our own fixtures. So the deliverable is a **declared XML
vocabulary**, derived by measuring what the corpus actually authors and what the bridge and
designer actually emit — not by transcribing the YAML set.

*(Filing said the XML vocabulary is a "genuine superset". Measured, it is a **translation**
plus one extension — see `## Evolution`. The filing's operational conclusion held; its model
did not.)*

**PL-064 governs the derivation** (surfaced at work-on): absence of a construct in the corpus
is NOT absence of demand for it. A vocabulary scraped from today's corpus alone would reject
the first legitimately-new element type someone authors. The vocabulary must come from the
*emitters* (bridge + designer), with the corpus as a cross-check, and any element the corpus
carries that the emitters cannot produce is itself a finding worth reporting rather than
silently blessing.

**Also settle where the type vocabulary lives.** `NODE_TYPES` (YAML) and the new XML set
describe the same modelling language through two serialisations. If they are two hand-written
lists they will drift, which is the T-322 lesson one level up. Prefer one declared mapping
with the XML superset expressed as an explicit extension of it, so the *difference* between
the forms is stated in one place and is readable.

Note the only witness to a bogus type today is an `I-XML-LANE-CAPACITY-SKIP` INFO from the
lane-capacity rule, which noticed solely because T-313 built it to refuse to guess an
occupancy it does not know. An unrelated rule's unevaluable-must-be-visible discipline is
currently doing the job of the missing gate.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Measured over **96 authored BPMN** and **both** emitters before any code: corpus carries 12 distinct flow-node elements; the bridge (`TYPE_MAP`) and the designer (`TYPE_TAG`) produce **exactly the same 10 element names as each other**. Full table in `## Evolution`. Original AC: every flow-node local name the authored BPMN corpus carries, with counts and files, plus every type the bridge (`tools/yaml-to-bpmn.py`) and the designer can emit. Recorded in `## Evolution` with the populations named.
- [x] Two found and both reported rather than folded in: **`boundaryEvent`** (2 occ, `boundary-events.bpmn`) — legal BPMN, unproducible, admitted as the one declared extension with a written reason; **`linkEventThrow`** (3 occ, `offpage-seam.bpmn`) — not a BPMN element at all, filed as **T-324**. Reverse direction: emitters produce nothing the corpus lacks. Original AC: — or vice versa — is reported explicitly rather than silently folded into the vocabulary. Per PL-064, a corpus-only derivation is not acceptable.
- [x] `E-XML-NODE-TYPE` emits from `XmlValidator`; `XML_NODE_TYPES` is **derived** — `{XML_TYPE_MAP.get(t,t) for t in NODE_TYPES} | XML_ONLY_NODE_TYPES` — so adding a YAML type automatically admits its XML spelling, and the difference between the forms is one small declared set. Original AC: for an unknown flow-node element, and the vocabulary is expressed as a declared extension of the YAML `NODE_TYPES` rather than a second hand-written list, so the superset relationship is stated in one readable place.
- [x] 96 authored BPMN scanned: exactly **one** file fires, and it is a true positive (`offpage-seam.bpmn`, T-324). The 8 fixtures carrying catch/throw/boundary events are silent — this is the AC the naive `NODE_TYPES` copy fails. Original AC: across authored BPMN and `tests/fixtures/` — specifically the 8 fixtures carrying catch/throw/boundary events must NOT fire. This is the AC the naive fix fails.
- [x] The T-320 witness reproduced on the real tree: renaming `agt_1_decompose` to `<bpmn:serviceTaks>` in `tests/fixtures/valid/investigate.bpmn` gives pre-change `VALID — no findings`, post-change `ERROR [E-XML-NODE-TYPE]` rc=2. Tree restored (`git diff -- tests/fixtures/` = 0 lines). **First attempt was a null result** — a `sed` that matched nothing produced a clean-looking pass; caught by asserting the occurrence count before reading the verdict. Original AC: the T-320 witness (`<bpmn:serviceTaks>` in `tests/fixtures/valid/investigate.bpmn`) now fires and exits non-zero, the pre-change build calls the same bytes clean, and the tree is restored byte-identical.
- [x] `tests/fixtures/invalid/E-XML-NODE-TYPE.xml`, carrying an in-file silence control (`<bpmn:boundaryEvent>` must NOT fire). Drift guard `tests/test_xml_node_type_vocab.py` wired into `tests/run-bridge-tests.sh` (T-316 orphan discipline). Bridge 62 → **63 passed, 0 failed**; validator 42 → **43 passed, 0 failed**. Original AC: so the GATING runner exercises the rule, and both suites stay green.
- [x] `E-NODE-TYPE` → PAIRED, new `E-XML-NODE-TYPE` → PAIRED, `EXPECTED_GAPS` 12 → 11, census number set updated in the same commit to **7 gap families / 11 gap rule ids / 0 out of scope**. Two stale figures found while reconciling (the T-323 block, and T-323's completed Verification line) and both fixed. Original AC: with `EXPECTED_GAPS` re-derived, and the census artifact's number set is updated in the same commit so guard and report cannot disagree (the T-323 reconciliation lesson).

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

out=$(python3 tests/test_xml_node_type_vocab.py 2>&1); echo "$out" | grep -q "^xml node-type vocabulary: OK"
out=$(python3 tests/test_rule_form_parity.py 2>&1); echo "$out" | grep -q "^rule-form parity: OK$"
out=$(bash tests/run-bridge-tests.sh 2>&1); echo "$out" | grep -qE "^bridge round-trip: [0-9]+ passed, 0 failed$"
out=$(bash tests/run-validator-tests.sh 2>&1); echo "$out" | grep -qE "^== summary: [0-9]+ passed, 0 failed ==$"
out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-NODE-TYPE.xml 2>&1); echo "$out" | grep -q "E-XML-NODE-TYPE"
# the silence control in that same fixture: boundaryEvent must NOT be reported.
# Anchored on the BRACKETED rule id: the bare token also matches the fixture's own
# FILENAME in the summary line, which made this assert 2 and read as a real failure
# (same anchoring class as the prose-in-the-haystack findings — match a structural
# literal that cannot occur in a path or a comment).
out=$(python3 tools/validate-workflow.py tests/fixtures/invalid/E-XML-NODE-TYPE.xml 2>&1); test "$(echo "$out" | grep -c '\[E-XML-NODE-TYPE\]')" = "1"
# exactly one authored file fires (3 findings, all offpage-seam) — the T-324 true
# positive. Scope note: this globs *.bpmn, so the new *.xml fixture is deliberately
# outside it; the fixture is asserted separately above.
test "$(for f in $(find examples tests/fixtures -name '*.bpmn'); do python3 tools/validate-workflow.py "$f" 2>&1; done | grep -c '\[E-XML-NODE-TYPE\]')" = "3"
grep -q "tests/test_xml_node_type_vocab.py" tests/run-bridge-tests.sh

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

### 2026-08-01 — "superset" was the wrong diagnosis, and it would have produced the wrong fix

- **What changed:** the census (and this task's own filing) said the XML vocabulary is a
  *genuine superset* — "catch/throw/boundary events, 19 occurrences in 8 fixtures".
  Measured, that conflates three different things. `intermediateCatchEvent` (10) and
  `intermediateThrowEvent` (7) are **not extra vocabulary**: they are what
  `linkEventCatch`/`linkEventThrow` and `eventError`/`eventTimer`/`eventMessage` are
  *called* on this form. A **translation**, not a superset. Both emitters produce exactly
  the same 10 names as each other. The genuine extension is **one** element,
  `boundaryEvent`.
- **Plan impact:** decisive. "Declare a superset" would have meant hand-writing a second
  vocabulary beside `NODE_TYPES` — the T-322 defect one level up. The shipped fix derives
  the XML set from the YAML one through the translation table, so the two cannot drift,
  and `XML_ONLY_NODE_TYPES` holds exactly the elements no emitter can write.
- **Note on the census's operational claim:** "copying `NODE_TYPES` verbatim hard-fails 8
  fixtures" was **correct** — just for a reason it had not identified. A right conclusion
  off a wrong model is not a validated model.

### 2026-08-01 — the measurement, stated with its populations

| element | occ | files | producible by an emitter? |
|---|---|---|---|
| scriptTask / endEvent / exclusiveGateway / serviceTask / startEvent / userTask / parallelGateway / subProcess | 1108 | up to 96 | yes, 1:1 |
| intermediateCatchEvent | 10 | 5 | yes — translation of linkEventCatch / eventError / eventTimer / eventMessage |
| intermediateThrowEvent | 7 | 3 | yes — translation of linkEventThrow |
| **boundaryEvent** | 2 | 1 | **no** — declared extension |
| **linkEventThrow** | 3 | 1 | **no** — not a BPMN element (T-324) |

Populations named deliberately: **96 authored BPMN** (`.editor-versions/` excluded as version
churn) and **both** emitters. PL-064 governed the derivation — absence from the corpus is not
absence of demand, so the vocabulary comes from the emitters with the corpus as cross-check,
not the other way round.

### 2026-08-01 — day-one true positive, on bytes we may not touch

- **What changed:** the gate fired immediately on `tests/fixtures/aef-bpmn/offpage-seam.bpmn`
  — 3 × `<bpmn:linkEventThrow>`, an element neither emitter can write, so those bytes did not
  come from our toolchain. The file is byte-pinned and AEF cross-validates it.
- **Plan impact:** severity stays ERROR (parity with the YAML rule, and it is a genuine
  defect), with a **counted tolerance** in `test_corpus_fixture_pins.py` — prints every run,
  count asserted, a 4th occurrence fails the build. Suppression was not on the table.
- **Triggered:** **T-324**, a coordinated re-pin with the peer, same shape as T-314.

### 2026-08-01 — a mutation that matched nothing looked exactly like a pass

- **What changed:** the first teeth run used a `sed` whose pattern did not match. Output read
  `pre-change VALID / post-change 0 findings` — indistinguishable at a glance from "the rule
  is inert", and one careless reading away from "teeth confirmed" in the opposite direction.
  Caught only because the script printed the occurrence count before the verdict.
- **Plan impact:** none to the deliverable. Recorded because it is the cheapest possible
  version of a lesson this arc keeps paying for: **assert the mutation landed before reading
  what it produced.** A null result and a clean result render identically.

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

### 2026-07-31T12:15:56Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-321-xml-form-has-no-node-type-vocabulary-gat.md
- **Context:** Initial task creation

### 2026-08-01T13:40:12Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

## Reviewer Verdict (v1.5)

- **Scan ID:** R-fc103fbe
- **Timestamp:** 2026-08-01T13:56:23Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 2

**Per-AC findings:**

- **AC#1 (Agent)** — Measured over **96 authored BPMN** and **both** emitters before any code: corpus carries 12 distinct flow-node elements; the bridge (`TYPE_MAP`) and the designer (`TYPE_TAG`) produce **exactly the sam
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/yaml-to-bpmn.py in: Measured over **96 authored BPMN** and **both** emitters before any code: corpus carries 12 distinct flow-node elements; the bridge (`TYPE_MAP`) and t`
- **AC#5 (Agent)** — The T-320 witness reproduced on the real tree: renaming `agt_1_decompose` to `<bpmn:serviceTaks>` in `tests/fixtures/valid/investigate.bpmn` gives pre-change `VALID — no findings`, post-change `ERROR 
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tests/fixtures/valid/investigate.bpmn in: The T-320 witness reproduced on the real tree: renaming `agt_1_decompose` to `<bpmn:serviceTaks>` in `tests/fixtures/valid/investigate.bpmn` gives pre`

### 2026-08-01T13:55:03Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
