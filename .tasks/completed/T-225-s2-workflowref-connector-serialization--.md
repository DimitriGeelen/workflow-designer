---
id: T-225
name: "S2 workflowRef connector serialization - pin uuid on aef:link, keep linkId
  orthogonal, targetWorkflow legacy alias (T-218 GO slice 2)"
description: >
  S2 workflowRef connector serialization - pin uuid on aef:link, keep linkId orthogonal,
  targetWorkflow legacy alias (T-218 GO slice 2)

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
created: 2026-07-21T19:52:54Z
last_update: '2026-08-16T13:57:19Z'
date_finished: 2026-07-21T20:47:42Z
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
  - ts: '2026-08-16T12:33:44Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=3 
      (body:fw-recall-or-memory-link); F-AUTONOMY=0 (no-signal); F3=0 
      (no-signal); F1=0 (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 8
      blast_radius: 5
    rationale: blast_radius=5 
      (paths:docs/plans/T-220-offpage-seam-editor-build-decomposition.md,src/aef-workflow-designer.html,tests/fixtures/aef-bpmn/offpage-seam.bpmn,tests/test_corpus_fixture_pins.py);
      tier=2 (no-signal); effort=8 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-225: S2 workflowRef connector serialization - pin uuid on aef:link, keep linkId orthogonal, targetWorkflow legacy alias (T-218 GO slice 2)

## WIP / DISCOVERY (2026-07-21)

**Attribute serialization DONE + verified (committed):** 4 editor edits — field lists (1685-6) +
field defs (workflowRef/name) + conditional export (buildBpmnXml) + import read (parseBpmnXml).
Playwright-verified: `<aef:link workflowRef="1f9b5f0c…" name="aef-task-lifecycle"/>` round-trips
byte-exact through parse→build in the editor's dialect; legacy bare `targetWorkflow`, ghost
workflowRef+name all correct; **no empty attrs emitted**; validator has zero complaints about the
link element. Pins + roundtrip fixed-point still green.

**DISCOVERY — RESOLVED (host-tag dialect gap):** the pinned fixture `offpage-seam.bpmn`, the 832
validator (`validate-workflow.py:54-55`), and AEF all use element tag `<bpmn:linkEventThrow>`/
`<bpmn:linkEventCatch>`; the editor emits `<bpmn:intermediateThrowEvent>`+`<aef:link>` and did NOT
recognize the fixture's tag on import (silently dropped those nodes). **Operator chose "ask AEF first";
AEF answered (rail offset 130, verified in their `bpmn_to_tasks.py` Pass-5):** their compiler detects
off-page refs by the `<aef:link>` CHILD — the host tag is never consulted; `<aef:link>` inside
`intermediateThrowEvent` compiles identically to `linkEventThrow`. **Fix = Option 1 (small, editor-only):**
teach the editor to IMPORT `<bpmn:linkEventThrow>`/`<bpmn:linkEventCatch>` (nodeTags + REVERSE_TYPE
identity entries at ~8470/8477); do NOT change the emit tag (our dialect is contract-conformant; fixture
stays byte-pinned as-is both sides — no re-pin). **DONE + verified:** the fixture's 3 legs now parse
(3 nodes, was 0) and round-trip to the ratified shape byte-exact — resolved+ghost keep workflowRef+name,
legacy keeps bare targetWorkflow, no empty attrs.

## Context

**S2 of the T-218 (GO 2026-07-21) off-page connector seam build; depends on S1/T-224 (uuid identity, DONE).**
Make link-event connectors pin the workflow **uuid** via `workflowRef`, keeping `linkId` orthogonal
(intra-diagram throw↔catch pairing) and `targetWorkflow` as a back-compat **legacy** leg. Ratified
serialization: `<aef:link workflowRef="<uuid>" name="<display>" linkId="<pairing>"/>`.

Spec: `docs/plans/T-220-offpage-seam-editor-build-decomposition.md` §S2. Arc: designer-authoring-surface.
See `[[aef-integration-rail]]`. **Conformance anchor:** the T-219 byte-fixture
`tests/fixtures/aef-bpmn/offpage-seam.bpmn` exercises all three legs —
resolved `<aef:link workflowRef="1f9b5f0c-…" name="aef-task-lifecycle"/>`,
ghost `<aef:link workflowRef="2222…" name="publish-map"/>`, legacy `<aef:link targetWorkflow="review-map"/>`.

**Live anchors:** fields 1685-6 (`linkEventThrow`/`linkEventCatch` lists) + defs 1721-2; export 8176-8179
(`buildBpmnXml` aef:link); import 8506-8511 (`parseBpmnXml` aef:link). **NB the crux:** the fixture emits
**no empty attributes** — the current export always writes `targetWorkflow="" linkId=""`, so S2 must emit
attributes **conditionally** (workflowRef+name for the ref legs, bare targetWorkflow for legacy, linkId only
when set) or the three legs will not round-trip. The legacy diagram XML is **never rewritten** to workflowRef
(ratified) — `targetWorkflow` and `workflowRef` stay as distinct in-memory fields; export prefers workflowRef
when present, else targetWorkflow.

## Acceptance Criteria

### Agent
- [x] `AEF_FIELDS.linkEventThrow` / `.linkEventCatch` include `workflowRef` and `name` alongside the existing `targetWorkflow`, `linkId`; field defs exist for the two new fields (picker/labels render) — done (1685-6 lists + 1721+ defs; workflowRef plain text, picker is S4)
- [x] Export (`buildBpmnXml`) emits `<aef:link>` with attributes **conditionally**: `workflowRef` (+ `name` when set) when a workflowRef is present; bare `targetWorkflow` only on the legacy leg (no workflowRef); `linkId` only when set — **no empty `targetWorkflow=""`/`linkId=""` attributes** are emitted — verified (linkAttrs join, no empty attrs in any leg)
- [x] Import (`parseBpmnXml`) reads `workflowRef` and `name` into `aef.*`; `targetWorkflow` is preserved as-is (legacy leg NOT silently rewritten to workflowRef); the two axes (`workflowRef` ⊥ `linkId`) stay independent — verified (parsed legs: resolved/ghost carry workflowRef+name & null targetWorkflow; legacy carries targetWorkflow & null workflowRef)
- [x] Round-trip conformance on `offpage-seam.bpmn`: parse → re-export yields the three `aef:link` lines **semantically identical** to the fixture — resolved leg keeps `workflowRef`+`name`, ghost leg keeps `workflowRef`+`name`, legacy leg keeps bare `targetWorkflow`; no leg gains a spurious empty attr and no leg is dropped — verified via Playwright: 3/3 link nodes parse (was 0 before the host-tag import fix), all 3 re-exported lines byte-match the fixture (`resolved_ok/ghost_ok/legacy_ok` all true, `no_empty_attrs` true)
- [x] `tools/validate-workflow.py` stays clean (exit 0) on a `workflowRef`-bearing exported map — verified: editor export of a workflowRef link node has zero validator complaints about the link element (residual errors in the toy doc were empty-id/dangling-flow artifacts of the minimal input, not the link)
- [x] The 3 byte-pinned corpus fixtures (`test_corpus_fixture_pins.py`) and `test_roundtrip_serialization.py` still pass (export change does not disturb the pinned bytes or the fixed-point) — 2/2 green after both the attribute edits and the host-tag import fix
- [x] Functional-verified in Playwright (:8834): draw/import a link event with a workflowRef → export shows the ratified shape; legacy targetWorkflow-only import re-exports bare — evidence read back — done (JSON evidence read back; data/serialization change, no CSS so element screenshots N/A per Visual Verification rule)

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

# workflowRef + name added to the link-event field lists
grep -q "workflowRef', 'name'" src/aef-workflow-designer.html
# export builds the workflowRef attr (dynamic linkAttrs.push, so grep the code not a literal tag)
grep -q 'workflowRef="\${escAttr(aef.workflowRef)' src/aef-workflow-designer.html
# import reads workflowRef
grep -q "getAttribute('workflowRef')" src/aef-workflow-designer.html
# host-tag import fix: editor recognizes the fixture's linkEventThrow/Catch element tags on import
grep -q "'linkEventThrow', 'linkEventCatch'" src/aef-workflow-designer.html
# editor still parses as one well-formed HTML document
python3 -c "import html.parser; p=html.parser.HTMLParser(); p.feed(open('src/aef-workflow-designer.html').read()); print('html-parse-ok')"
# byte-pins + roundtrip fixed-point hold
python3 -m pytest tests/test_corpus_fixture_pins.py tests/test_roundtrip_serialization.py -q

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

### 2026-07-21 — S2 was two problems: attributes (trivial) + a host-tag dialect gap (the real one)
- **What changed:** The decomposition framed S2 as "workflowRef serialization" — attribute-level. That half was straightforward (conditional `<aef:link>` emission, no empty attrs) and round-tripped in the editor's own dialect immediately. But the conformance anchor ("the fixture round-trips through export") exposed a deeper, pre-existing gap the plan didn't anticipate: the editor emits/imports `<bpmn:intermediateThrowEvent>` while the pinned fixture + validator + AEF use the explicit `<bpmn:linkEventThrow>` element tag. The editor silently dropped the fixture's link nodes on import — so the anchor was unreachable by attribute work alone.
- **Plan impact:** S2's true scope = attribute serialization **+** host-tag import reconciliation. Resolved cheaply: AEF confirmed (rail offset 130, verified in their code) their compiler keys off the `<aef:link>` child, host tag irrelevant → the editor only needs to IMPORT the extra tag (2 nodeTags entries + 2 REVERSE_TYPE identity mappings), keeping its own emit dialect. No re-pin, no emit change, no AEF-side change.
- **Triggered:** No new task. Confirmed the seam is `<aef:link>`-child-keyed (recorded on the rail + `[[aef-integration-rail]]`) — relevant to S3 (ghost rescan scans `<aef:link>` refs, also host-agnostic) and S4 (claim picker). yaml-to-bpmn.py left untouched (no workflowRef in yaml sources; deferred).

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

### 2026-07-21T19:52:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-225-s2-workflowref-connector-serialization--.md
- **Context:** Initial task creation

### 2026-07-21T20:47:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
