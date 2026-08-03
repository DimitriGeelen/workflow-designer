---
id: T-337
name: "Import silently drops flow nodes whose BPMN tag is outside the parseBpmnXml allowlist"
description: >
  parseBpmnXml iterates a hard-coded nodeTags allowlist (src:9661) and selects elements by tag, so any flow node carrying a tag outside it is never enumerated - no error branch, no warning. Export writes only from state.nodes, so a load-save round trip deletes the node and the result validates CLEAN because E-XML-NODE-TYPE's evidence was destroyed with it. Measured T-309 spike 4: 15 of 24 corpus maps, 15 nodes lost.

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
created: 2026-08-02T09:33:03Z
last_update: 2026-08-03T11:16:58Z
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
- [ ] A round-trip fidelity guard exists that loads a BPMN document containing a flow node with an
      out-of-allowlist tag, exports it, and asserts **no flow node is lost** — failing on today's
      code, passing after the fix. Teeth: mutating the fix back must turn it red.
- [ ] The guard runs in `tests/run-bridge-tests.sh` (the gating runner), not only standalone —
      a suite nobody runs cannot report a failure.
- [ ] Its denominator is stated and checked: the guard must assert it actually exercised an
      out-of-allowlist tag, so it cannot pass by testing nothing.
- [ ] Repair semantics chosen from (a)/(b)/(c) above and recorded in `## Decisions` with rationale,
      including whether the choice changes exported bytes for any existing corpus map.
- [ ] `tools/_t308-export-byte-identity-cdp.mjs HEAD` still reports byte-identical across all 24
      corpus maps — the fix must not move bytes for well-formed input.
- [ ] `python3 tests/test_finding_anchorability.py` still passes (E-XML-NODE-TYPE's population may
      move from unwitnessed to witnessed; if the never-witnessed row moves, that is a real result to
      record, not a number to adjust).

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

### 2026-08-02T09:33:03Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-337-import-silently-drops-flow-nodes-whose-b.md
- **Context:** Initial task creation

### 2026-08-03T11:16:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
