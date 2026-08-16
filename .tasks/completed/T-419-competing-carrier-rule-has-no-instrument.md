---
id: T-419
name: "Competing-carrier rule has no instrument: the premise four import rulings rest
  on is asserted in prose and cannot go red"
description: >
  Competing-carrier rule has no instrument: the premise four import rulings rest on
  is asserted in prose and cannot go red

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs, 
      tools/_t419-carrier-mutation-check.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T18:25:43Z
last_update: '2026-08-16T14:33:35Z'
date_finished: 2026-08-10T18:36:58Z
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
  - ts: '2026-08-16T12:33:57Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F-AUTONOMY=0
      (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:35Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 2
      D3: 2
      D4: 2
      F-RECALL: 2
      F2: 0
      F4: 5
      F3: 2
      F1: 1
    rationale: D1=4 (body:structural-gate); D2=2 
      (body:telemetry-or-audit-entry); D3=2 (body:default-change); D4=2 
      (body:env-class-handled); F-RECALL=2 (body:lightly-promoted); F2=0 
      (no-signal); F4=5 (prose:routing-engine); F3=2 (prose:seam-namespace); 
      F1=1 (prose:process-enablement-incidental)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:23Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 3
    rationale: blast_radius=3 (no-signal); tier=2 (no-signal); effort=8 
      (no-signal)
    rubric_sha: e4a00f38e801
---

# T-419: Competing-carrier rule has no instrument: the premise four import rulings rest on is asserted in prose and cannot go red

## Context

**PL-114 (the competing-carrier rule) decides four import rulings and is enforced by
nothing.** It states: *preserve-and-re-emit unconsumed content — unless we generate a
competing carrier for the same fact; where we do, preservation produces a
self-contradictory document and the correct answer is to consume.*

The rule's whole force comes from a factual table in
`docs/reports/T-397-import-repair-semantics-brief.md` §"competing-carrier rule":

| granularity | do we generate a competing carrier? | ruling |
|---|---|---|
| T-337 — foreign flow-node tag | no | (a) preserve — *shipped* |
| T-347 — content inside an accepted element | no | (a) preserve — recommended |
| T-340 — `bpmndi` geometry | **yes — `aef:position`** | (b) consume — recommended |

Every cell is a claim about what `buildBpmnXml` emits **today**. All three are asserted in
prose, in a brief and three task files, and measured nowhere. The day the code stops
matching the table, the table keeps reading as true and the rulings keep citing it.

**This is not hypothetical: the row most likely to expire is already an active task.**
T-357 (*Adopt BPMN DI as the designer geometry and retire `aef:position`*) proposes
deleting the exact emission the DI row depends on. If it ships, T-340's ruling silently
loses its premise — the reason DI departs from the T-337 precedent evaporates, and nothing
anywhere goes red.

**AEF hit this first and built the instrument** (rail 487, their T-2882/T-403): they pin
`test_di_drop_has_a_competing_carrier`, which asserts the carrier *exists* — delete
`aef:position` and the test goes red. T-340's Human AC recommends adopting it. This task
does that, and generalises it: AEF's test pins **one row**; the rule has **three**, and a
"no competing carrier" row expiring is just as ruling-breaking as the "yes" row expiring.

**Derived, not declared.** The carrier question is answered behaviourally — feed the
importer a document carrying fact F in *standard* form only, round-trip it, and observe
whether our exporter emits a representation of F that the input never had. That is the
definition of "we generate a competing carrier", measured rather than restated. (T-418's
discipline: a check that hardcodes the answer in hand closes the member and leaves the
class.)

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Carrier-census leg added to `tools/_t338-input-fidelity-cdp.mjs` measuring, per
      fact-class, whether the exporter emits a representation the input did not carry —
      verdict derived from the round trip, not from a hardcoded carrier list
      → leg 8 / population 7. Verdict is `ownMarkers(output) − ownMarkers(input)`; no
      carrier is named in the logic, so the check reports *which* carrier it found.
- [x] All three brief rows covered (geometry / foreign flow-node tag / element content),
      each with its own verdict, so one row expiring cannot be masked by another
      → measured 2026-08-10: `geometry CARRIER-GENERATED:aef:position` (24/24),
      `foreign-flownode CARRIER-NONE` (24/24), `element-content CARRIER-NONE` (15/24).
      The brief's table is confirmed empirically for the first time.
- [x] `EXPECTED_CARRIER` records today's measured table; drift in **either** direction
      fails loudly (a carrier appearing where the brief says none is as ruling-breaking as
      one disappearing) — mirroring the existing `EXPECTED_LOSSY` "good news is not
      silently absorbed" handling in the same file
      → verdict string carries the derived carrier name, so a *different* carrier is drift
      too, not just presence/absence.
- [x] Mutation-checked: deleting the `aef:position` emission (`src:9272`) turns the
      geometry row RED, and turns **only** it red — proven by a check that runs the
      mutation rather than by inspection
      → `tools/_t419-carrier-mutation-check.sh` M1: `CARRIER-GENERATED:aef:position →
      CARRIER-NONE`, reciprocals unmoved. M2 additionally shows a `CARRIER-NONE` row can
      report `GENERATED` (`aef:doc`) — without it, "none" is indistinguishable from a
      probe that missed. M2 is global by construction and asserts no isolation; see
      `## Evolution`.
- [x] The brief and PL-114 point at the instrument, so a future reader of the rule reaches
      the measurement from the claim rather than having to know it exists
      → brief §competing-carrier rule + PL-114 `application`. Also **T-357**, which is the
      task that would falsify the DI row: the warning sits at the point of change, not
      only in the document the changer may never open.

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
# T-419 note: the mutation check is listed FIRST and is not optional. The carrier
# table read back correctly on its first run, so the leg passing proves only that
# it agrees with the brief — not that it is capable of disagreeing. Only the
# mutation check distinguishes those. It edits COPIES of the designer source and
# never the tracked file.
bash tools/_t419-carrier-mutation-check.sh
node tools/_t338-input-fidelity-cdp.mjs
bash tests/run-bridge-tests.sh
# The rule must remain reachable FROM the claim, not merely filed near it: both
# the brief's table and PL-114 have to name the instrument, or a future reader
# re-derives the premise from prose exactly as before.
grep -q "_t338-input-fidelity-cdp.mjs" docs/reports/T-397-import-repair-semantics-brief.md
grep -q "_t338-input-fidelity-cdp.mjs" .context/project/learnings.yaml

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

**Symptom:** none observable. That is the defect. PL-114 decides four import rulings by
asserting which granularities generate a rival carrier, and every cell of that table was
prose. Nothing would have reported the day it stopped being true — the brief would keep
reading as correct and the rulings would keep citing it.

**Root cause:** the rule was promoted to a learning (PL-114) and cited in three task files
and a brief while its *factual premise* stayed unmeasured. A rule and the fact it rests on
were treated as one artifact. The rule is durable; the fact is a property of
`buildBpmnXml` on a given day, and only the fact can silently expire.

**Why structurally allowed:** every existing leg of the input-fidelity harness measures
what the importer **loses**. The competing-carrier question is about what the exporter
**generates**, which no instrument in the tree asked. The blind spot was a direction, not
a gap in coverage — six populations of loss probes, zero generation probes, and the class
that decides the rulings lived in the direction nobody instrumented.

**Prevention:** population 7 derives the table from the round trip every bridge run, and
`EXPECTED_CARRIER` fails in both directions. Distinct from the fix: the pointer added to
**T-357** — the task that would falsify the DI row — so the change most likely to break
the premise carries the warning at the point of change, rather than the guard relying on
someone reading the brief first.

**Not claimed as prevention:** this covers the three granularities the brief names. A
*fourth* fact-class acquiring a rival carrier would not be caught, because no row exists
for it — the same population problem the T-340 RCA names. The check tests the table, not
the space of possible tables.

## Evolution

### 2026-08-10 — the second mutation cannot isolate, and pretending otherwise was the tempting move
- **What changed:** M1 (retire `aef:position`) isolates cleanly — one row moves. M2 had to
  show that a `CARRIER-NONE` row is *capable* of reporting `GENERATED`, and any emission I
  could add unconditionally moves all three rows, because the verdict is a whole-document
  marker diff. The obvious repair was to make M2 isolating by teaching the importer to
  consume `documentation` first — which is **T-347's ruling**, an unshipped design decision
  smuggled in as test scaffolding.
- **Plan impact:** M2 keeps the global mutation and *declares* that it asserts no
  isolation, with the reason in the script. The two mutations answer different questions
  (M1: does this row move when only its premise changes? M2: can an absence row report
  presence at all?) and the pass message now says so instead of claiming isolation for
  both — the first draft of that message overclaimed.
- **Triggered:** no new task. Recorded because a check engineered until it passes cleanly
  is the failure mode this whole task exists to catch, one level up.

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

### 2026-08-10 — widen AEF's instrument to all three rows rather than port it

AEF pins `test_di_drop_has_a_competing_carrier`: one assertion, that the rival carrier
**exists**. T-340's Human AC recommends adopting it. Porting it verbatim would have been
the smaller change and would have covered the row most likely to move (T-357).

Widened anyway, because the rule has three rows and the "no rival carrier" rows are load-
bearing in the same way. If we ever *start* generating a carrier for foreign flow-node
tags or for element content, T-337's shipped ruling and T-347's recommended one become
wrong — silently, and in the direction that produces the self-contradictory documents
PL-114 exists to prevent. A guard on the "yes" row alone treats one direction of the rule
as the whole rule.

### 2026-08-10 — measure the answer, do not encode it

The cheap implementation is `expect(output).toContain('aef:position')`. It would pass
today, would go red under T-357, and would be one line. Rejected: it names the carrier in
the logic, so it can only ever answer the question for the carrier we already know about,
and a *different* rival carrier appearing would read as a pass. The verdict is instead a
set difference over our namespace, and the carrier's name is an *output* recorded in
`EXPECTED_CARRIER`. Directly T-418's lesson — a detector keyed on the offending value in
hand closes the member and leaves the class — applied one week later to a different seam.

### 2026-08-10 — a whole-document diff, not a per-element one

The `element-content` and `foreign-flownode` rows could be read off the specific element
carrying the probe, which is what the neighbouring content leg does (deliberately, so
relocation is distinguishable from survival). Not copied here: a rival carrier that lands
on a *different* element than the fact it duplicates is still a rival carrier, and a
per-element read is precisely blind to it. The two legs ask different questions and the
similarity is superficial.

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

### 2026-08-10T18:25:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-419-competing-carrier-rule-has-no-instrument.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-cc540a1f
- **Timestamp:** 2026-08-10T18:39:00Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-10T18:36:58Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
