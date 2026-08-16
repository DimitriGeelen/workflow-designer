---
id: T-482
name: "Project the remaining scalar semantic keys in the round-trip fixed point (eight,
  not the six inherited from T-480)"
description: >
  Project the remaining SCALAR aef keys in the editor's parse->build round-trip fixed
  point.
  T-480 filed six; re-measurement (AC1) found the inherited census wrong in both directions
  — it named io and link as units when neither is an aef.X scalar, while missing that
  link
  decomposes into four projectable keys (workflowRef, name, targetWorkflow, linkId).
  The
  projectable set is eight. aef:io genuinely is not a scalar and is excluded deliberately,
  with a P-011 leg pinning its absence, because listing it would read as coverage
  while the
  projection body skipped it as undefined. Filed as T-483.

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
created: 2026-08-12T22:51:05Z
last_update: '2026-08-16T14:33:40Z'
date_finished: 2026-08-12T22:59:47Z
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
  - ts: '2026-08-16T12:34:02Z'
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
  - ts: '2026-08-16T14:33:40Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F2: 0
      F4: 0
      F3: 5
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F2=0 (no-signal); F4=0 (no-signal); F3=5 
      (prose:seam-contract); F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:24Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:tools/_roundtrip-serialization-cdp.mjs,tools/_t352-p011-errexit-probe.sh,tools/_t482-scalar-projection-falsify.mjs,tools/validate-workflow.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T13:58:56Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_roundtrip-serialization-cdp.mjs,tools/_t482-scalar-projection-falsify.mjs);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-482: Project the six remaining structured semantic elements in the round-trip fixed point

## Context

T-480 closed OBS-041 by projecting `aef:endpoint` in the editor's parse->build round-trip
fixed point, and filed a census of what is STILL not projected: `contextReads`,
`artifactsWrites`, `decisionInput`, `decisionOutputs`, `io`, `link`. Filed, not built.
This task builds it.

Scope boundary, stated because it is the thing most likely to be overclaimed: these are not
"unguarded". `test_editor_bridge_field_coverage.py` (T-059) covers the editor<->bridge axis
and `test_structured_parity` (T-063) covers a different element set. What nothing covers for
these six is the editor's OWN parse->build round trip — a drift introduced and re-emitted
symmetrically by the editor is invisible to every guard we have.

PL-023 applies directly: the six-element figure is T-480's census, not a fresh measurement.
AC1 re-measures it against current `src/` before anything is projected, because a deferred
census is a claim about a tree that has since moved.

## Acceptance Criteria

### Agent
- [x] AC1 — Census re-measured against CURRENT src (PL-023), not inherited from T-480.
      For each candidate element: does the editor parse it into node state, and does
      `buildBpmnXml` re-emit it? The T-480 figure of six is CONFIRMED or CORRECTED with
      counts, and the corrected list is what AC2 acts on. Population scoped by type
      (`*.bpmn` for corpus counts), never tree-minus-exclusions (AEF 594).
- [x] AC2 — Every element that AC1 confirms is BOTH parsed and re-emitted is projected in
      BOTH copies of the harness projection list in `tools/_roundtrip-serialization-cdp.mjs`
      (the guard at ~line 101 AND the preflight self-test at ~line 60). A P-011 leg pins the
      per-copy count structurally so a future one-sided patch goes red — the fix-one-of-N
      trap T-480 hit in this same file.
- [x] AC3 — Falsified on the SIGNAL, not the exit status (my 595 §3 rule, taken by AEF at
      597 §4). Every newly projected element WITH A NON-ZERO CORPUS POPULATION is blind
      without the key in the projection list and catching with it, read from the probe's
      structured `blindWithout`/`caughtWith` fields. Any element with population zero is
      reported as UNFALSIFIABLE alongside its denominator and is NOT counted as a pass.
      The harness exit code is not the evidence.
      NOTE — this AC was REWORDED mid-task, and the original is kept here rather than
      overwritten: it read "for each newly projected element, mutating that element's
      emitted value flips the projection-equality signal". `linkId` has corpus population
      zero, so nothing can be mutated and that criterion is unmeetable for it. The original
      wording admitted only two outcomes, pass or fail, for a key whose real state is
      "no evidence available" — and the path of least resistance would have been to tick
      it on 7/8 and let the eighth ride. The reworded form makes the third outcome
      explicit and blocks that. Scope did not change; the honesty of the reporting did.
- [x] AC4 — The mutation method does not contaminate the control signal. The determinism
      flag is IDENTICAL in the PRE and POST runs; a run where the mutation perturbs
      determinism is discarded and the method fixed, not reported. This is the exact defect
      that nearly made T-480 revert a correct fix.
- [x] AC5 — Projecting more elements does not turn the EXISTING guard red on the current
      corpus. If it does, that is a live round-trip defect and gets its own task (one bug =
      one task) rather than being absorbed here.
- [x] AC6 — Zero bytes moved outside `tools/`: `git diff` reports empty on `src/`,
      `docs/standards/`, `examples/`, `tests/fixtures/`, and `.agentic-framework/`.
- [x] AC7 — No mutant/probe artifact left in the working tree after the run.

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
#
# T-482 NOTE on leg authoring, learned the hard way in T-478/T-481: this tree's
# vendored P-011 gate (update-task.sh:978-983) strips HTML comment spans out of THIS
# BLOCK before executing it, with no quote or command-boundary awareness (OBS-043).
# A leg carrying those delimiters as grep data has its middle silently deleted and
# runs in the rewritten form. Fixed upstream by AEF's T-2921; live in our pin. So:
# no leg below carries HTML comment delimiters as data, on purpose.
#
# Population scoping per AEF rail 594: corpus legs anchor on the artefact TYPE the
# population is made of, never on the whole tree minus wherever we have been writing.

# AC2 — both copies of the projection list carry the four standalone-element keys.
# Structural anchor (PL-169): the exact list fragment, counted, not a bare prose string.
test "$(grep -c "'contextReads','artifactsWrites','decisionInput','decisionOutputs'," tools/_roundtrip-serialization-cdp.mjs)" = "2"

# AC2 — both copies carry the four aef:link binding keys, including workflowRef (the
# off-page seam binding). One anchor covers 'name' too, which is too generic to count alone.
test "$(grep -c "'workflowRef','name','targetWorkflow','linkId'" tools/_roundtrip-serialization-cdp.mjs)" = "2"

# AC1 — aef:io must NOT be in the projection list. It has no aef.io scalar, so listing it
# would be skipped as undefined: coverage in the list, none in the behaviour. This leg
# encodes that decision so a later "completeness" edit goes red instead of green.
test "$(grep -c "'io'," tools/_roundtrip-serialization-cdp.mjs)" = "0"

# Harness still parses as JS (the T-480 failure mode: a comment inside a template literal
# containing an interpolation killed the harness before it evaluated anything).
node --check tools/_roundtrip-serialization-cdp.mjs

# AC3/AC4 — falsification probe. Its own exit code is the verdict: every key with a
# non-zero corpus population must be blind WITHOUT it in the list and catching WITH it.
timeout 400 node tools/_t482-scalar-projection-falsify.mjs > /tmp/t482-falsify.out 2>&1

# AC3 — and no key regressed to INCONCLUSIVE. Asserted on the structured field rather
# than the exit status, per the rule this task is built on.
grep -q '"failures": \[\]' /tmp/t482-falsify.out

# AC5 — projecting eight more keys did not turn the existing guard red on the real corpus.
timeout 400 node tools/_roundtrip-serialization-cdp.mjs > /tmp/t482-guard.out 2>&1

# AC6 — zero bytes moved outside tools/. src, the frozen standard, the corpus, the
# fixtures, and the vendored framework are all untouched.
git diff --quiet -- src/ docs/standards/ examples/ tests/fixtures/ .agentic-framework/

# AC7 — no mutant or scratch artefact left behind in the corpus or fixture trees.
test -z "$(git status --porcelain --untracked-files=all -- examples/ tests/fixtures/)"

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

## Findings

### AC1 — the inherited census of "six" was wrong, and wrong in the dangerous direction

T-480 filed six elements as "not projected by the round-trip fixed point". Re-measured
against current `src/`, they are not one population. They are two, and only one is
projectable by the mechanism T-480 used:

    SCALAR aef.X — same shape as endpoint, directly projectable    8
      contextReads      emit src:9287  parse src:9959   attribute paths=
      artifactsWrites   emit src:9288  parse src:9961   attribute paths=
      decisionInput     emit src:9289  parse src:9963   element text
      decisionOutputs   emit src:9290  parse src:9965   element text
      workflowRef       emit src:9297  parse src:9975   aef:link attribute
      name              emit src:9299  parse src:9976   aef:link attribute
      targetWorkflow    emit src:9303  parse src:9977   aef:link attribute
      linkId            emit src:9307  parse src:9978   aef:link attribute

    NOT A SCALAR — no aef.X exists; adding to METAKEYS is a silent no-op    1
      io       src:9337-9345  built from `inputs`/`outputs` ARRAYS, not aef.io

The first four are confirmed live, not vestigial: they are editable fields
(`FIELD_DEFS` src:1862-1870) and are assigned to node types (src:1784-1805).

**I got `link` wrong on the first pass and corrected it before building.** The initial
census recorded `link` alongside `io` as "not a scalar, not projectable", reasoning from
the emission site alone — `aef:link` is assembled from a `linkAttrs` array, so there is
indeed no `aef.link`. But the PARSE side (src:9974-9979) decomposes that element into
four separate scalar keys, and those are ordinary projectable values. Reading only the
emitter would have shipped a census that silently dropped four keys — including
`workflowRef`, the off-page seam binding (S2/T-225, AEF rail 130), whose silent loss on a
round trip unbinds a cross-workflow jump with no error raised anywhere.

So the inherited figure of six was wrong in BOTH directions at once: it named two units
that are not scalars, while missing that one of them decomposes into four keys that are.
The projectable set is **eight**, not six and not four.

**Why the distinction matters more than the count.** The projection body is
`if(aef[k]!=null && aef[k]!=='') meta[k]=String(aef[k])`. For `io` and `link`,
`aef[k]` is `undefined`, so the key is skipped — silently. Adding `'io'` and `'link'`
to `METAKEYS` would change no behaviour whatsoever while making the list *read* as
though all six were covered. That is a green that cannot go red, installed by the very
act of "closing" the gap — and it would have been invisible, because the harness would
still pass and the list would still name the element.

This is the T-480 census consumed without re-measurement, which is exactly the failure
PL-023 names. The follow-up I wrote at rail 595 §4 said "six structured semantic
elements"; four is the correct figure for this mechanism, and `io`/`link` need a
structured projection, which is a different deliverable.

**Filed separately, not absorbed here** (one task = one deliverable): structured
round-trip projection for `aef:io`.

### AC3/AC4 — falsified on the signal, not the exit status

`tools/_t482-scalar-projection-falsify.mjs`, 45 corpus documents:

    key                pop   site                                blind without   caught with
    decisionInput       63   arc-lifecycle.bpmn                      yes             yes
    artifactsWrites     38   arc-lifecycle.bpmn                      yes             yes
    contextReads        37   context-memory.bpmn                     yes             yes
    decisionOutputs     30   arc-lifecycle.bpmn                      yes             yes
    workflowRef          7   bare-catch-event.bpmn                   yes             yes
    name                 7   bare-catch-event.bpmn                   yes             yes
    targetWorkflow       3   bare-catch-event.bpmn                   yes             yes
    linkId               0   ---                                 UNFALSIFIABLE

Seven of eight are falsified in both directions: with the key removed from the projection
list the mutated value is invisible, with it present the drift is caught. PRE and POST
differ by exactly one variable — membership in the list. No code was reverted, no exit
code was consulted, and the determinism flag is not part of the comparison at all, so the
T-480 contamination (a mutation perturbing a second signal that then impersonates
detection) has no surface to occur on. AC4 is satisfied structurally rather than by
observation.

**`linkId` has corpus population zero and is reported as UNFALSIFIABLE, not as a pass.**
It is parsed, emitted, and now projected, but no document in the corpus carries one, so
there is nothing to mutate and no evidence the projection would bite. Calling 8/8 here
would be a clean number over an empty population — PL-084, the exact vacuity this probe
prints its denominators to prevent. The honest figure is 7 falsified, 1 projected on
faith, and it stays labelled that way until a fixture carries a `linkId`.

### The harness self-test proves less than it appears to

`selftest.hit` is `"tier"` on every run. The preflight perturbs the FIRST key whose regex
matches and then breaks, so it demonstrates that the MECHANISM detects drift and nothing
about any individual key. That is defensible — `proj()` treats keys uniformly — but it
means "the harness is green and the self-test passes" carries no information about the
eight keys added here. It is why AC3 needed a separate probe rather than a re-run.

Related, and pre-existing: the two `METAKEYS` copies were ALREADY divergent before this
task. The guard carries `errorStatus`, `timerSpec`, `busTopic`, `hostRef`, `interrupting`;
the preflight does not. T-480 pinned the count of `endpoint` at 2 and that leg was correct,
but it should not be read as "the two lists agree" — they do not, and did not. Not fixed
here (different deliverable); recorded so the next reader does not infer parity from the
per-key legs.

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

### 2026-08-12T22:51:05Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-482-project-the-six-remaining-structured-sem.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-48e522a3
- **Timestamp:** 2026-08-12T22:59:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T22:59:47Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
