---
id: T-565
name: "IW-0 exit condition: measure the byte impact of always emitting aef:workflowMeta across the 24 rendered maps"
description: >
  T-501 IW-0 is DEFERRED, not answered — the operator has not ruled on whether export should always emit <aef:workflowMeta>. This task produces the evidence that deferral names as its exit condition and NOTHING ELSE: measure whether always emitting the element changes the bytes of any of the 24 rendered maps, and run the T-308/T-358 byte-identity gates against the result. It does NOT change the emitter. If nothing moves, the carve-out's motivating risk is absent; if something moves, the failure is attributable to this change alone.

status: started-work
workflow_type: test
owner: agent
horizon: now
tags: []
components: []
related_tasks: [T-501, T-562]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-20T09:48:13Z
last_update: 2026-08-23T21:49:38Z
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

# T-565: IW-0 exit condition: measure the byte impact of always emitting aef:workflowMeta across the 24 rendered maps

## Context

T-501 IW-0 is `disposition: deferred`, and the deferral names its own exit condition
(T-501 lines 157-163): *"measure whether emitting `<aef:workflowMeta>` on every export
changes the bytes of any of the 24 rendered corpus maps, and run T-308/T-358's
byte-identity gates against the result."* This task produces that evidence and nothing
else. It does NOT change the emitter — that is T-501's carved-out item and remains the
operator's ruling.

**First measurement, taken before the ACs were written, because it decides what the
other ACs can honestly claim:** all 24 of `examples/aef-processes/rendered/*.bpmn`
already contain exactly one `aef:workflowMeta`. A population in which the condition
("document lacks the element") occurs zero times cannot falsify a change conditioned
on it. The exit condition as written names a corpus that cannot exercise the change —
the same population-pin shape as T-423's `aef:forceStraight` (0 instances, guard green
forever) and G-015. So answering IW-0 honestly requires finding the population that
CAN move, which T-501 IW-1 already located: the documents with no `<aef:workflowMeta>`
that reach the id fallback chain.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The named population is measured and reported as exercising or not exercising
  the change.** Count, over all 24 rendered maps, how many carry `<aef:workflowMeta>`
  and how many do not. If the not-carrying count is zero, that is stated as
  UNEXERCISED and explicitly NOT reported as "always-emit is safe" — a no-op over a
  population containing none of the condition is not evidence about the condition.
  **MEASURED: 24 carry it, 0 do not.** The exit condition IW-0 wrote for itself names a
  population in which the change is unexercisable. `_t565-workflowmeta-emission-census.mjs`
  prints UNEXERCISED and refuses to convert that into a safety claim; the wired leg
  returns rc 2 if the moving population is ever empty, so a run with nothing to check
  cannot report itself as a pass.
- [x] **The population that CAN exercise the change is enumerated across the whole
  corpus, not just the rendered 24**, with a per-document list, so the operator's
  ruling is made against documents that would actually move rather than against a
  count that cannot move.
  **MEASURED, 58-document corpus over the four directories T-501 names:** rendered 24/0
  lacking, aef-bpmn 19/0, third-party 11/**10**, lane-provenance 4/**4** — **14 movers**,
  reproducing T-501's 14 exactly. Every one is named in the census output.
  **DENOMINATOR DISCREPANCY, reported rather than smoothed:** T-501 states "60 documents,
  46 carry, 14 do not" (three times: :330, :420, :508). Those four directories hold **58**
  today and `git log --diff-filter=AD` shows **no `.bpmn` has ever been deleted from them**,
  so they cannot have held 60. The two adjacent fixture directories (`aef-inbound`,
  `exported`) contain documents that **all carry the element**, so whatever the extra two
  were they sat in the carrying bucket. I have not reconstructed T-501's walk and do not
  claim a mechanism — the load-bearing number (14) reproduces exactly; the denominator does
  not, and the difference is recorded as measured, not explained.
- [x] **The byte delta of always-emit is measured on that population** — for each
  document lacking the element, what bytes an always-emit export would add — and
  reported as a per-document figure, not a single aggregate.
  **MEASURED per document, 101–131 bytes**, e.g. `third-party/caseagile-local-ns.bpmn`
  101 B, `lane-provenance/later-laneset-ignored.bpmn` 131 B. The figure is the emitted
  `<aef:workflowMeta …/>` block, **deliberately not the whole-document delta**: since
  T-423, DI is emitted unconditionally, so a document diff is dominated by 2012 added DI
  elements and would answer a question nobody asked. The block is the cost attributable to
  this item alone, which is what carving it out was for.
  **AND THE FINDING THE AC DID NOT ANTICIPATE: all 14 already gain the element on export
  today.** Measured by round-tripping each through the real designer, not by reading
  `buildBpmnXml`. So IW-0 asks whether export *should* always emit; the exporter already
  does, unconditionally. The item is not a proposed byte change to weigh — it is a
  description of current behaviour, and the bytes it would "add" are bytes the tree
  already writes.
- [x] **T-308 and T-358 byte-identity gates are run and their verdicts recorded**
  against the current tree, so the ruling has the gate state it was promised.
  * `_t308-export-byte-identity-cdp.mjs` — **rc 0, 24 identical / 0 drifted / 0 unusable.**
    Its own emitted metadata says `does_not_cover: third-party documents`, and its corpus
    contains **zero** of the 14 movers. It passes, and it cannot see this change.
  * `_t358-byteid-thirdparty.mjs` — **rc 1. 0 identical / 11 drifted**, and it prints
    `*** PRECONDITION VIOLATED — this comparison is NOT sound` on `boundary-events` (2
    same-lane x tie groups) and `kitchen-sink` (14). Its uid-only normaliser is unsound
    while a uid can reach an emitted element id, and it correctly refuses to certify.
  * **Nothing runs the second one.** `run-bridge-tests.sh` has no leg for it; its only
    executable-code caller is `_t364-byteid-precondition-teeth.py:40`, which
    `_t509-instrument-sweep.sh:66` EXCLUDES by design. So the gate the deferral named as
    its safety net for the population holding 10 of the 14 movers is red, and no runner has
    ever seen it red. Filed as **T-579**, not fixed here — one bug, one task.
  * **T-364 predicted this in writing** ("boundary-events (2 groups) and kitchen-sink (11
    groups) already hold uid-less collision groups in their DI, so adopting DI as geometry
    supplies the missing ingredient"), and T-423 adopted DI. boundary-events matches the
    predicted 2 exactly; kitchen-sink is 14 against a predicted 11.
- [x] **The evidence is surfaced to the operator on `/approvals`** with the exact
  decision text, and the deferral's exit condition is annotated in T-501 with what was
  measured — without flipping the disposition, which is the operator's to flip.
  **DONE both halves.** T-501's IW-0 block carries `EXIT CONDITION EXECUTED 2026-08-23`
  with the three measurements and an explicit `DISPOSITION UNCHANGED`. The ruling itself is
  surfaced as the `### Human` `[REVIEW]` AC below, with the evidence, the copy-pasteable
  command, and the reason step 4 is left to the operator.
  **HOW IT REACHES THE ROUTE, stated because it is not obvious:** `/approvals` has four
  sections — Tier 0 approvals, pending GO/NO-GO inception decisions, paused dispatches, and
  tasks with unchecked Human ACs. There is **no section for an agent-surfaced technical
  decision**, and `fw approvals` has only `pending`/`status`/`expire` — no `add` verb. So
  the only mechanism that carries an item like this to the route is the fourth one, an
  unchecked Human AC on an active task, which is what was used. That is a real limit of the
  route, not a workaround: an operator decision that is not Tier 0, not an inception
  GO/NO-GO, and not a dispatch has no first-class home there, and reaches the page only by
  being attached to a task that stays open.

### Human

- [ ] [REVIEW] **Rule on T-501 IW-0 — "should export always emit `<aef:workflowMeta>`?"**
  The exit condition the deferral wrote for itself has been executed. The measurement
  changes what is being asked: **the exporter already always emits it**, so this is not a
  proposed byte change to weigh against a risk, it is a description of shipped behaviour.
  The ruling available is whether to KEEP it, not whether to make it.

  **Evidence, all measured today (`tools/_t565-workflowmeta-emission-census.mjs`, wired as
  a bridge-suite leg):**
  * The 24 rendered maps the deferral named **all already carry the element** — 0 can
    exercise the change. That population cannot answer the question.
  * The 14 that can (10 `tests/fixtures/third-party`, 4 `lane-provenance`) **all gain the
    element on export today**, measured by round-tripping each through the real designer.
    Cost 101–131 bytes each, the `<aef:workflowMeta …/>` block only.
  * The safety net the deferral named does not cover it: `_t308` passes 24/24 but its own
    metadata says `does_not_cover: third-party`; `_t358-byteid-thirdparty` does reach 10 of
    the 14, **exits 1 today** with `PRECONDITION VIOLATED`, and **no runner invokes it**
    (filed T-579). The 4 `lane-provenance` movers are watched by neither.

  **Steps:**
  1. Read the annotated block in `.tasks/active/T-501-*.md` under `IW-0` (search
     `EXIT CONDITION EXECUTED`), which carries the three measurements above.
  2. Decide: **KEEP** current unconditional emission, or **CHANGE** it (which would mean
     making emission conditional — a new behaviour, not a revert).
  3. Record the ruling, single line, from any directory:

     `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw context add-decision "T-501 IW-0: KEEP unconditional <aef:workflowMeta> emission" --task T-501 --rationale "<your reason>"`

  4. Then flip `disposition: deferred` to `disposition: answered` on IW-0 in
     `.tasks/active/T-501-map-id-round-trip-defect-triage-aef-cons.md`. **Left for you
     deliberately** — an agent flipping it would convert a carve-out into a ruling nobody
     made, which is the substitution T-501 §0 was written to undo.

  **Expected:** a decision id (`PD-NNN`) is printed, and IW-0 reads `disposition: answered`.

  **If not:** if the evidence does not settle it, the missing piece is most likely T-579 —
  the gate that watches 10 of the 14 movers is red and unrun, so "what would break" cannot
  currently be answered for that population. Say so and leave IW-0 deferred; that is a
  legitimate outcome and the deferral is cheaper than a ruling made without the gate.

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

# The census runs and holds its invariant: every corpus document lacking
# <aef:workflowMeta> gains one on export. rc 2 = REFUSED (empty moving population).
timeout 500 node tools/_t565-workflowmeta-emission-census.mjs > /tmp/t565-verify.out 2>&1

# The named population is reported as UNEXERCISED rather than as a pass. If this stops
# matching, the census has started treating a no-op over an absent condition as
# evidence, which is the failure this task was opened to avoid.
grep -q "UNEXERCISED" /tmp/t565-verify.out

# The moving population is non-empty and counted. A census ranging over zero movers
# would print a clean report and mean nothing.
grep -qE "14 can be changed by an always-emit rule" /tmp/t565-verify.out

# The measured answer to IW-0 lives in the instrument's output, not only in prose here.
grep -q "ALWAYS-EMIT IS ALREADY THE BEHAVIOUR" /tmp/t565-verify.out

# The leg is wired into the suite, not merely referenced in prose. This task's own
# finding is that a stated safety net nobody runs is not a safety net (T-579), so the
# instrument it produces must not join that set — and a task file naming a tool is
# exactly the prose-only edge T-578 measured at 110 of 237.
grep -q '_t565-workflowmeta-emission-census.mjs' tests/run-bridge-tests.sh

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

### 2026-08-20T09:48:13Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-565-iw-0-exit-condition-measure-the-byte-imp.md
- **Context:** Initial task creation

### 2026-08-20T09:48:26Z — status-update [task-update-agent]
- **Change:** horizon: now → next

### 2026-08-23T21:37:19Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
