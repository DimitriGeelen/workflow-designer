---
id: T-337
name: "Import silently drops flow nodes whose BPMN tag is outside the parseBpmnXml
  allowlist"
description: >
  parseBpmnXml iterates a hard-coded nodeTags allowlist (src:9661) and selects elements
  by tag, so any flow node carrying a tag outside it is never enumerated - no error
  branch, no warning. Export writes only from state.nodes, so a load-save round trip
  deletes the node and the result validates CLEAN because E-XML-NODE-TYPE's evidence
  was destroyed with it. Measured T-309 spike 4: 15 of 24 corpus maps, 15 nodes lost.

status: work-completed
workflow_type: build
owner: agent
horizon:
tags: []
components: [tools/_t338-input-fidelity-cdp.mjs]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-02T09:33:03Z
last_update: '2026-08-16T12:33:51Z'
date_finished: 2026-08-03T11:48:32Z
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
  - ts: '2026-08-16T12:33:51Z'
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
---

# T-337: Import silently drops flow nodes whose BPMN tag is outside the parseBpmnXml allowlist

## Context

Found by T-309 spike 4 (IW-3 reachability), not by a report — see
`docs/reports/T-309-validator-surfacing.md`, section "2026-08-02 — IW-3 priced".

`parseBpmnXml` builds its node list by iterating a hard-coded allowlist and pulling elements *by
tag* (`src/aef-workflow-designer.html:9661`):

```js
const nodeTags = ['startEvent', 'endEvent', 'serviceTask', 'userTask', 'scriptTask',
                  'exclusiveGateway', 'parallelGateway', 'intermediateThrowEvent',
                  'intermediateCatchEvent', 'linkEventThrow', 'linkEventCatch',
                  'boundaryEvent', 'subProcess'];
for (const tag of nodeTags) { for (const el of byBpmn(proc, tag)) { ... } }
```

There is no complement branch. An element whose tag is not in that list is never visited, so it
never enters `state.nodes`; `buildBpmnXml` writes only from `state.nodes`, so an open→save round
trip **deletes it**. The `REVERSE_TYPE[tag] || 'serviceTask'` fallback at :9671 defends only tags
already inside the list.

**Measured (T-309 spike 4):** injecting one out-of-vocabulary tag into each rendered corpus map,
round-tripping through the real `parseBpmnXml`→`buildBpmnXml`, 15 of 24 maps carry a `serviceTask`
to mutate and **all 15 lose exactly that node**. The exported result then validates **CLEAN** —
`E-XML-NODE-TYPE` cannot fire, because the evidence was destroyed along with the node. Negative
control: all 24 unmutated maps round-trip losing nothing.

**Severity is latent, not active.** A scan of all 47 `.bpmn` files in the tree finds **zero**
out-of-allowlist `bpmn:` tags today, so nothing we currently hold triggers it. It becomes active the
moment a map uses a standard BPMN tag we have not implemented — `callActivity` (already an open
task, T-282), `inclusiveGateway`, `businessRuleTask`, `sendTask`, `receiveTask`, `manualTask`,
`eventBasedGateway` — or when either side of the seam ships a vocabulary extension before the other.
That is a corpus zero standing in for a safety property: it cannot distinguish *safe* from
*unexercised*.

**House precedent points at preservation.** T-259 (T-257 GO) fixed the same defect class one
granularity down — an unconsumed `<aef:eventDef>` was silently destroyed on layout-only open→save
(the rail-201 field defect) — and the remedy was a passthrough that captures the unknown content as
inert state so export can re-emit it. The comment at :9656 also records the ratified principle:
*"diagram XML is never silently migrated."* Both point at preserve-and-re-emit rather than
coerce-to-a-known-type.

**Not yet decided, and deliberately so:** the repair semantics change what the designer emits for
*peer* content, which is the T-559 product seam. Options are (a) preserve the element verbatim and
re-emit, (b) coerce to a fallback node type — rejected on its face, it silently rewrites a peer's
tag, (c) refuse the load and surface an error. (a) matches precedent, but node-level passthrough is
materially larger than field-level: state has no representation for an unknown element, and the
canvas needs something to draw. Scope the implementation before building.

## Acceptance Criteria

### Agent
- [x] A round-trip fidelity guard exists that loads a BPMN document containing a flow node with an
      out-of-allowlist tag, exports it, and asserts **no flow node is lost** — failing on today's
      code, passing after the fix. Teeth: mutating the fix back must turn it red.

      **The guard was NOT built here — it already existed** (`tools/_t338-input-fidelity-cdp.mjs`,
      T-338/T-339), pinned to *expect* the loss. Stating that plainly because the AC reads as if
      the instrument were a deliverable of this task; it is not, and what it cost was one line.
      What this task did was flip the expectation and prove the flip.

      | run | lossy tags | exit |
      |---|---|---|
      | baseline, before the fix | **10 / 10** (adHocSubProcess, businessRuleTask, callActivity, complexGateway, eventBasedGateway, inclusiveGateway, manualTask, receiveTask, sendTask, transaction) | 0 (matched its pinned expectation) |
      | after the fix, expectation *untouched* | **0 / 10** | **1** — `FAIL: a vocabulary gap CLOSED … remove them from EXPECTED_LOSSY so the improvement is recorded rather than assumed` |
      | after the fix, `EXPECTED_LOSSY` emptied | 0 / 10 | 0 |

      The middle row is the evidence, and it is the guard reporting its own subject's repair —
      that instrument is built so an IMPROVEMENT fails too, precisely so a fix cannot be silently
      absorbed into a permission list. Full-output `diff` of baseline vs post-fix: **one line
      changed**. Every other population (malformed ×8, refs ×4, sub-tree, content ×7, root
      siblings ×8, dangling-ref self-consistency) is byte-identical, so the change is surgical
      rather than merely net-positive.

      **Teeth, two mutants, one per side of the fix** (run against a mutated COPY via the
      harness's `T338_DESIGNER_SRC` seam — the working tree was never touched):
      - `mut-emit` — emit side reverted to `TYPE_TAG[n.type]`, import left intact → **10/10 lossy,
        exit 1**
      - `mut-parse` — complement branch neutered to `continue` → **10/10 lossy, exit 1**

      Both directions matter: a one-sided mutation test would pass if the other half were dead
      code. Failure text: `FAIL: a NEW vocabulary gap appeared — … A tag the importer does not
      know is not rejected, it is invisible, and export writes only what state holds (T-337).`

- [x] The guard runs in `tests/run-bridge-tests.sh` (the gating runner), not only standalone —
      a suite nobody runs cannot report a failure.

      `tests/run-bridge-tests.sh:595` invokes it. Confirmed by running the gating runner itself,
      not by reading the wiring: `bridge.txt:802` carries the leg header `== Input fidelity:
      load→save preserves content (T-338, G-016) ==` followed by the harness's own output.
      Whole suite: **160 PASS/OK legs, 0 FAIL, exit 0**; bridge round-trip 69/69; geometry sweep
      24 clean.

- [x] Its denominator is stated and checked: the guard must assert it actually exercised an
      out-of-allowlist tag, so it cannot pass by testing nothing.

      Two mechanisms, and **one of them I had to add** — the AC was not already satisfied.
      (1) Per-probe: the mutated source is asserted to contain `<bpmn:TAG` *before* the round
      trip, and a tag that fails to inject lands in `notInjected`, which is gated into the
      verdict. (2) Per-population: the other four populations each carried an
      `if (rows.length === 0) problems.push('… nothing was probed')` guard; **population 1 did
      not.** It did not need one while `EXPECTED_LOSSY` held all ten tags — an empty run would
      have reported ten CLOSED entries and failed. **Emptying the set removed that accidental
      protection**, so an empty `PROBE_TAGS` would from now on have scored a silent vacuous pass.
      Guard added in the same change. This is the population inverting from
      all-expected-to-DROP to all-expected-to-SURVIVE, and the two shapes fail differently.

- [x] Repair semantics chosen from (a)/(b)/(c) above and recorded in `## Decisions` with rationale,
      including whether the choice changes exported bytes for any existing corpus map.

      **(a) preserve and re-emit.** Recorded in `## Decisions` with the rejection grounds for (b)
      and (c), the argument for a node rather than a byte-level passthrough (edge-loss), the
      failure-direction argument for the exclusion set, and three stated scope boundaries.
      Byte impact: **none, measured** — 24/24 identical (next AC).

- [x] `tools/_t308-export-byte-identity-cdp.mjs HEAD` still reports byte-identical across all 24
      corpus maps — the fix must not move bytes for well-formed input.

      `{"ok": true, "maps": 24, "identical": 24, "drifted": 0, "drift": [], "errors": []}`.
      Run pre-commit, when `HEAD` was `8ee29344` — i.e. genuinely the pre-change tree.
      **The `## Verification` block pins `8ee29344` rather than `HEAD`**: once this commits, the
      `HEAD` form compares the tree against itself and is green forever. See `## Decisions`.

- [x] `python3 tests/test_finding_anchorability.py` still passes (E-XML-NODE-TYPE's population may
      move from unwitnessed to witnessed; if the never-witnessed row moves, that is a real result to
      record, not a number to adjust).

      Passes, exit 0: 23 rules over 76 documents, 22 verified against real documents, 0
      disagreements. **The contingency did not fire, and the reason is not the one the AC
      guessed:** E-XML-NODE-TYPE was *already* witnessed before this change, so there was no
      unwitnessed→witnessed move to record. The single never-witnessed row is E-XML-STRUCTURE
      (`unreachable: no emitter produces a non-<bpmn:definitions> root`), unrelated to this task
      and unmoved by it.

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
#
# T-337 note: `_t308-export-byte-identity-cdp.mjs` takes a git ref. The ref is
# PINNED to the commit before this change, deliberately — passing HEAD would make
# the tool compare the working tree against itself and pass forever (the G-015
# always-moving-global shape T-354 repaired three times in T-178).
bash tests/run-bridge-tests.sh
node tools/_t308-export-byte-identity-cdp.mjs 8ee29344
node tools/_t338-input-fidelity-cdp.mjs
python3 tests/test_finding_anchorability.py

## RCA

**Symptom:** a BPMN document containing a flow node whose tag is outside the importer's allowlist
loses that node on an open→save round trip. The saved document then validates CLEAN.

**Root cause:** `parseBpmnXml` enumerates nodes by iterating an allowlist of tags
(`src/aef-workflow-designer.html:9661`) rather than iterating the process's children and classifying
them. An allowlist-driven read has no complement: unknown input is not rejected, it is *invisible*.
Export writes from `state.nodes`, so invisible means deleted.

**Why structurally allowed:** the instrument that exists to prove the export path is safe cannot see
this class of defect. `tools/_t308-export-byte-identity-cdp.mjs` compares
`buildBpmnXml(parseBpmnXml(map))` produced by **two designer versions** against **each other**, over
the 24 well-formed corpus maps. A defect present in both versions is byte-identical and therefore
green; a defect that only malformed input can express is outside the denominator entirely. So T-309's
assumption A-4 ("surfacing findings changes no exported bytes — T-308 established the technique for
proving it") credits that harness with a property it does not have: it proves *no drift between
versions*, not *fidelity to input*. Registered as a gap, since the blindness is general and not
specific to this bug.

**Prevention:** distinct from the fix — an input-fidelity guard (node/edge/lane counts preserved
across load→save) whose population deliberately includes documents the corpus does not contain,
running in the gating runner. The fix alone would leave the next vocabulary gap equally invisible.

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

### 2026-08-03 — the fix was one line; the prevention had already shipped

- **What changed:** the filing framed this as a build task whose hard part was the repair. It
  was not. `tools/_t338-input-fidelity-cdp.mjs` (T-338/T-339) already probed all ten
  out-of-vocabulary tags, already ran in the gating runner, and already carried a comment
  saying *"Empty this after T-337 lands and the guard will tell you if you were wrong to."*
  The measurable work was: add the complement branch, add `n.foreignTag ||` to one emit
  expression, empty `EXPECTED_LOSSY`.
- **Plan impact:** AC1 is worded as though the guard were a deliverable of this task. It was
  not, and the AC is ticked with that stated rather than silently satisfied. The genuine
  design work moved to the *boundaries* — node-vs-passthrough, the exclusion set's failure
  direction, and what this fix deliberately does not cover.
- **Triggered:** T-355 (foreign-tag nodes have no visual marker — preservation shipped,
  disclosure did not).

### 2026-08-03 — emptying an expectation set can delete a control that was never named

- **What changed:** `EXPECTED_LOSSY` held all ten probe tags, which meant an empty
  `PROBE_TAGS` would have failed loudly (ten CLOSED entries). That was **accidental**
  protection — a side effect of the expectation's contents, not a guard anyone wrote. The
  other four populations each carry an explicit empty-population guard; population 1 did not,
  and nothing noticed because it did not need one **yet**.
- **Plan impact:** flipping an expectation set is not a bookkeeping edit. The population
  inverted from all-expected-to-DROP to all-expected-to-SURVIVE, and those two shapes fail in
  different directions: the old one could pass on an injection that never landed; the new one
  is only safe because the injection is asserted present. Added the missing guard in the same
  change and said so in the file.
- **Triggered:** nothing filed — but this is the same family as the T-338 header's own note
  that a population of only-expected-to-drop rows cannot tell loss from an injection that
  never landed. The instrument had written the lesson down for its *root-sibling* population
  and not applied it to its *first* one.

### 2026-08-03 — a latent defect's census is what makes "latent" a measurement

- **What changed:** the claim "severity is latent, not active" was inherited from the filing.
  Re-measured statically over all 47 `.bpmn` files: direct children of `<bpmn:process>` are
  **14 distinct tags, all allowlisted node tags or `sequenceFlow`/`laneSet`/
  `extensionElements`** — zero artifacts, zero data objects, zero out-of-vocabulary tags.
- **Plan impact:** none to the fix, but it converts two sentences from assertion to
  measurement: the byte-identity result is *explained* rather than merely observed, and the
  reason a corpus-only instrument could never find this defect is now a number rather than an
  argument. A corpus zero still cannot distinguish *safe* from *unexercised* — which is the
  whole reason the probe injects rather than surveys.

## Decisions

### 2026-08-03 — repair semantics for an out-of-allowlist flow node

- **Chose:** **(a) preserve and re-emit.** The element is imported as a real node
  carrying `foreignTag`; `buildBpmnXml` emits `n.foreignTag || TYPE_TAG[n.type]`, so the
  original tag survives the round trip verbatim.
- **Why:** it matches the house precedent one granularity down (T-259/T-257 GO captured an
  unconsumed `<aef:eventDef>` as inert state so export could re-emit it) and the ratified
  principle recorded at `parseBpmnXml`: *diagram XML is never silently migrated*.
- **Why a NODE and not a byte-level passthrough held outside the graph:** `sequenceFlow`
  endpoints are resolved through `displayIdToUid`. An element kept verbatim but outside
  `state.nodes` would preserve its own bytes and take its EDGES down with it — node-loss
  converted into edge-loss, which is the same defect wearing a quieter costume.
- **Rejected (b) coerce to a known type:** rewrites a peer's tag silently. Rejected on its
  face by the filing and nothing measured here changes that.
- **Rejected (c) refuse the load:** makes the designer unusable on any peer document that
  uses standard BPMN we have not implemented, and destroys the editing path for exactly the
  case the seam exists to serve.

**Does it change exported bytes for any existing corpus map? No — measured, not argued.**
`tools/_t308-export-byte-identity-cdp.mjs 8ee29344` reports **24/24 identical, 0 drifted**.
The mechanism is that `foreignTag` is written only for an out-of-allowlist element, so a
well-formed map produces node objects with exactly the fields they had before. Two
independent reasons it must hold: no corpus map has such a tag (census below), and the emit
expression falls through to `TYPE_TAG[n.type]` when the field is absent.

**Census backing the "no live population" claim** (static, all 47 `.bpmn` files in the tree):
direct children of `<bpmn:process>` are 14 distinct tags, every one either an allowlisted node
tag or `sequenceFlow` / `laneSet` / `extensionElements`. Zero artifacts, zero data objects,
zero out-of-vocabulary tags. That is why the defect is latent — and why a corpus-only
instrument could never have found it.

### 2026-08-03 — the exclusion set is the same shape as the bug, kept because its failure direction is safe

The complement branch skips a small `PROCESS_NON_FLOWNODE` set, which is *itself* an
allowlist — the very shape this task removes. Kept deliberately, because the two errors are
not symmetric: **misclassify a non-flow-node as a node and it is preserved** (re-emitted,
drawn, laned); **misclassify a flow node as structure and it is deleted.** Preservation is
the recoverable direction, so the set is deliberately small — only children BPMN defines as
non-flowElements, plus the flowElements that are not flow *nodes*.

**Scope boundaries, stated rather than implied:**
- Direct children of `<bpmn:process>` only. A foreign tag nested inside an accepted
  `subProcess` is not covered — the entire interior of an accepted element is dropped today,
  which is **T-347's** population, measured separately by the same instrument
  (`CONTENT-DROPPED` on 5 shapes, unchanged by this fix).
- Foreign-*namespace* children of `<bpmn:process>` are left alone. Typing a `camunda:*`
  element as a BPMN flow node would be a guess; root-level foreign content is **T-340's**
  class (`DI-DROPPED`, also unchanged).
- The drawn shape is a presentation-only two-way heuristic (`*Gateway` → diamond, else task
  rectangle) and moves no bytes, because export reads `foreignTag`, not `type`. Mapping a
  foreign `*Event` onto `intermediateCatchEvent` was rejected: `REVERSE_TYPE` maps that tag
  to `linkEventCatch`, so the node would silently inherit link-event semantics and jump UI —
  a worse lie than a rectangle.
- **A foreign node is visually indistinguishable from a service task.** No UI marker was
  built; that is a separate deliverable, not a silent omission. Filed as T-355.

### 2026-08-03 — verification pins a commit, not `HEAD`

`_t308-export-byte-identity-cdp.mjs` compares the working tree against a git ref. Writing
`HEAD` into `## Verification` would have been green forever the moment this change committed —
the tool would compare the tree to itself. That is the **G-015 shape** T-354 repaired three
instances of in T-178 a session ago. The block pins `8ee29344`, the commit before this work,
so the check keeps asking the question it was written to ask.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-08-02T09:33:03Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-337-import-silently-drops-flow-nodes-whose-b.md
- **Context:** Initial task creation

### 2026-08-03T11:16:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ac11f251
- **Timestamp:** 2026-08-03T11:50:09Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-03T11:48:32Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
