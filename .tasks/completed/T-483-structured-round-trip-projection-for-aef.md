---
id: T-483
name: "Structured round-trip projection for the seven non-scalar semantic values (filed as aef:io alone; the census found seven)"
description: >
  T-482 projected the eight SCALAR semantic keys in the editor round-trip fixed point and deliberately excluded aef:io. io is not an aef.X scalar: it is built from the inputs/outputs ARRAYS (src:9337-9345), so adding 'io' to METAKEYS would be read as undefined and skipped - coverage in the list, none in the behaviour, a green that cannot go red. It needs a structured projection (element shape, not String(aef[k])), in BOTH copies of the harness list, falsified per key on the projection-equality signal rather than exit status. A T-482 P-011 leg currently asserts 'io' is NOT in the list; that leg must be replaced, not deleted, when the structured form lands.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T22:59:02Z
last_update: 2026-08-12T23:07:34Z
date_finished: 2026-08-12T23:07:34Z
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

# T-483: Structured round-trip projection for the seven non-scalar semantic values

## Context

<!-- One sentence for small tasks. Link to design docs for substantial ones. -->

## Acceptance Criteria

### Agent
- [x] AC1 — Census of the STRUCTURED (non-scalar) values the round-trip fixed point does
      not project, measured against current `src/`, with corpus population per value.
      T-482 scoped itself to scalar `aef.X` keys and found eight; this task takes what that
      scoping deliberately left. Filed scope was `aef:io` alone — if the census is larger,
      the census wins and the task name is corrected to match (T-482 precedent).
- [x] AC2 — Each structured value is projected by a projection that VARIES WITH ITS
      CONTENT. Specifically NOT `String(aef[k])`: for the dict-valued members that yields
      the constant `[object Object]`, which sits in the projection looking like coverage
      while comparing equal to itself for every possible mutation. Demonstrated, not
      asserted — see AC4.
- [x] AC3 — Projected in BOTH copies of the harness list/projection in
      `tools/_roundtrip-serialization-cdp.mjs`, with a P-011 leg pinning it structurally
      (the fix-one-of-N trap this file has now sprung twice).
- [x] AC4 — The naive fix is falsified explicitly: a run projecting a dict-valued member
      via `String()` must FAIL to detect a mutation of that member, and the structural
      projection must detect the same mutation. This is the evidence for AC2 and the reason
      the obvious patch is rejected; without it "we projected it" is unfalsifiable.
- [x] AC5 — Every structured value with a non-zero corpus population is falsified both
      ways (blind without / catching with), judged on the projection-equality signal and
      not on any exit status. Any value with population zero is reported UNFALSIFIABLE with
      its denominator and is NOT counted as a pass (T-482 `linkId` precedent, PL-084).
- [x] AC6 — Projecting more does not turn the EXISTING guard red on the current corpus. If
      it does, that is a live round-trip defect and gets its own task, not absorption here.
- [x] AC7 — The T-482 leg asserting `'io',` is ABSENT from the list is REPLACED by a leg
      asserting the structural projection is present — replaced, not deleted. A deleted
      leg silently restores the exact hazard it was written to prevent.
- [x] AC8 — Zero bytes moved outside `tools/`: `git diff` empty on `src/`,
      `docs/standards/`, `examples/`, `tests/fixtures/`, `.agentic-framework/`.

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

## Findings

### AC1 — filed scope was `aef:io`; the census found seven, and a third node shape

T-482 excluded `aef:io` and filed it as the follow-up. Measuring the exclusion properly
found six more values in the same blind spot, and `io` itself is not even the shape T-482
assumed:

    value           corpus pop   model location            wire shape
    io                     65    node.io   (NOT node.aef)  inputs/outputs child elements
    constituents           10    aef.constituents          array of dicts
    emits                   5    aef.emits                 array of strings
    multiInstance           3    aef.multiInstance         dict
    aggregation             2    aef.aggregation           dict
    compensates             1    aef.compensates           array of strings
    timer                   1    aef.timer                 dict

`io` is a **sibling of `aef` on the node** — `node.io`, parsed at src:10029-10044, emitted
at src:9337-9345. So across T-482 and T-483 the model has three shapes, not two: scalar
`aef.X`, structured `aef.X`, and `node.X`. T-482's finding said "no `aef.io` scalar exists,
so listing it would be skipped as undefined" — correct conclusion, incomplete reason. It is
not a missing scalar; it is not on `aef` at all.

All seven have non-zero corpus population, so all seven are falsifiable and none is
projected on faith (contrast T-482's `linkId`, population 0).

### AC2/AC4 — the obvious patch would have covered seven and detected two

The naive fix is to append these names to `METAKEYS`, whose body is `String(aef[k])`.
Measured against a real mutation of each value, three projections compared:

    value           excluded    String() patch    structural
    emits             blind        CATCHES          catches
    compensates       blind        CATCHES          catches
    constituents      blind        BLIND            catches
    aggregation       blind        BLIND            catches
    multiInstance     blind        BLIND            catches
    timer             blind        BLIND            catches
    io                blind        BLIND            catches

**Five of seven stay blind under the String() patch.** Every dict yields the constant
`[object Object]`, and so does an array of dicts — which is why `constituents` fails
despite being array-valued at the top level. `String()` only survives contact with arrays
of *strings*, which is exactly the two members that happen to work.

That patch is worse than the gap it closes. An absent key is a known hole. A key present
in the list whose projected value is a constant is a hole that **reports itself closed** —
it would satisfy any leg counting names in the list, and any reviewer reading the list.
This is the same hazard T-482 rejected for `io` on inspection; here it is measured, across
five values, rather than argued.

The implemented projection is structural: `canon()` recursively sorts object keys (so a
pure attribute-order difference cannot masquerade as semantic drift) and the value is
carried as data rather than stringified.

### One deliberate non-mirroring, and why it is not a bug

`structOf()` does NOT apply the emitter's name-filter (src:9263-9264) to `io.inputs` /
`io.outputs`. Mirroring it would restrict the comparison to entries the emitter already
keeps — PL-031's first trap, where a guard adopts the lossy step's own definition of
content and thereby loses the ability to see that class of loss. A nameless io entry
SHOULD surface as drift. The corpus currently contains none, so this costs nothing today
and preserves the detection.

### Self-inflicted, worth recording

The first run of the extended guard died with `.filter is not a function` at load. Cause:
I wrote a backtick into a comment that lives **inside a JS template literal** — the exact
hazard T-480 documented in a comment two lines above where I was typing, and which that
task's own note warns about in the same file. Fixed by removing it; the T-483 probe is
built entirely with string concatenation rather than template literals so the hazard has
no surface. Reading a warning is not the same as being protected by it.

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


# AC3 — the structured-value list is present in BOTH copies of the harness projection.
test "$(grep -c 'var STRUCTKEYS = ' tools/_roundtrip-serialization-cdp.mjs)" = "2"

# AC3 — and both projections actually CALL it. A list defined and never used is the same
# class of defect as a key projected through String(): present, inert, reads as covered.
test "$(grep -c 'structOf(n)' tools/_roundtrip-serialization-cdp.mjs)" = "4"

# AC7 — the T-482 guarantee, restated here so it stays live now that T-482 is archived:
# 'io' must NOT be in METAKEYS. It is projected structurally instead. This leg REPLACES
# T-482's (which no longer runs), it does not delete it.
test "$(grep -c "'io'," tools/_roundtrip-serialization-cdp.mjs)" = "0"

# Harness still parses as JS. It did not, twice, because of a backtick inside a comment
# that lives in a template literal.
node --check tools/_roundtrip-serialization-cdp.mjs

# AC4/AC5 — falsification probe; its own exit code is the verdict.
timeout 400 node tools/_t483-structured-projection-falsify.mjs > /tmp/t483-falsify.out 2>&1

# AC5 — no value fell to INCONCLUSIVE. Asserted on the structured field, not the exit code.
grep -q '"failures": \[\]' /tmp/t483-falsify.out

# AC5 — and nothing was counted as a pass over an empty population (PL-084).
grep -q '"unfalsifiable": \[\]' /tmp/t483-falsify.out

# AC4 — the naive-patch evidence is actually reported, not merely claimed in prose.
grep -q '"blindUnderStringPatch"' /tmp/t483-falsify.out

# AC6 — the existing guard still passes on the real corpus with the richer projection.
timeout 400 node tools/_roundtrip-serialization-cdp.mjs > /tmp/t483-guard.out 2>&1

# AC8 — zero bytes moved outside tools/.
git diff --quiet -- src/ docs/standards/ examples/ tests/fixtures/ .agentic-framework/

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

### 2026-08-12T22:59:02Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-483-structured-round-trip-projection-for-aef.md
- **Context:** Initial task creation

### 2026-08-12T23:02:01Z — status-update [task-update-agent]
- **Change:** horizon: later → now

### 2026-08-12T23:02:01Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-16541266
- **Timestamp:** 2026-08-12T23:07:38Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T23:07:34Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
