---
id: T-237
name: "eventDef/linkEventCatch vocabulary collision: typed catch events misclassified as workflow handoffs (AEF rail 153, 0.3.1)"
description: >
  Peer-reported (AEF rail offset 153, operator-escalated twice their side): 0.3.0 editor classifies EVERY bpmn:intermediateCatchEvent as linkEventCatch (handoff-from-another-workflow), even when the node carries aef:eventDef (T-204 typed-event vocabulary, e.g. kind=message binding=bus:...). Repro on AEF corpus map aef-dispatch-loop node agt_msg_result: typed message-catch, zero aef:link -> properties panel shows type linkEventCatch, Target workflow none, permanently-inert Open-target-workflow affordance. Ask for 0.3.1 (rides with T-234): eventDef-bearing catches classify/render as the typed event (distinct type label, NO jump affordance); linkEventCatch reserved for aef:link carriers (bare catches: our call, record in Decisions). Check throw side for the same ambiguity (intermediateThrowEvent + eventDef vs + link).

status: started-work
workflow_type: build
owner: agent
horizon: now
tags: [bug, designer, aef-integration]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-22T10:41:18Z
last_update: 2026-07-22T10:52:06Z
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

# T-237: eventDef/linkEventCatch vocabulary collision: typed catch events misclassified as workflow handoffs (AEF rail 153, 0.3.1)

## Context

Peer-reported field bug (AEF rail offset 153, sibling of T-234, targeted at the same 0.3.1
tag). AEF live-verified on the vendored 0.3.0 bundle: a `bpmn:intermediateCatchEvent`
carrying `<aef:eventDef kind="message" binding="bus:..."/>` (our own T-204 vocabulary,
zero `aef:link`) shows in the properties panel as type **linkEventCatch** ("← Handoff from
another workflow") with "Target workflow: — none —" and a permanently-inert "Open target
workflow" affordance; their operator escalated twice reading it as a broken handoff.
**Initial code read (this session):** `parseBpmnXml` DOES have an eventDef override
(src :8718-8727 — `EVENT_KIND_TYPE[kind]` remaps the type after the
`REVERSE_TYPE['intermediateCatchEvent'] = 'linkEventCatch'` default at :8649), and the
shared fixture `tests/fixtures/aef-bpmn/typed-events.bpmn` uses the exact same namespace
URI as the editor's `AEF_NS` (:8599) — so the defect is NOT the obvious missing-override
and must be pinned by BEHAVIOR repro (PL-046) before fixing: possibly a second
classification site (render/properties/palette), a nesting/namespace variant in
AEF-generated corpus maps, or an eventDef+link precedence hole. Direction agreed on rail
(my ack offset 154): eventDef present ⇒ typed event, distinct type label, NO jump
affordance; `linkEventCatch` reserved for `aef:link` carriers; bare-catch default is
832's call (record in Decisions); throw side (`intermediateThrowEvent` + eventDef vs
+ link) gets the same disambiguation.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The misclassification is REPRODUCED first on the running :8834 served editor (PL-046 behavior repro, not source grep) with an eventDef-bearing catch node (typed-events.bpmn fixture or a byte-faithful copy of AEF's failing node shape), and the actual divergence point is identified and named in the RCA — no fix lands before the repro is understood (finding: master classifies CORRECTLY; AEF's repro is the 0.3.0 release-lineage gap — dist artifact has 0 eventDef hits; two secondary master defects found + fixed, see RCA)
- [x] After the fix: an `intermediateCatchEvent` carrying `aef:eventDef` imports/classifies as the mapped typed event (eventError/eventTimer/eventMessage) — properties panel shows the typed-event type and binding field, NO "Target workflow" / "Open target workflow" affordance, and the typed glyph renders (served :8834: typed-events.bpmn → 3/3 typed with bindings errorStatus/timerSpec/busTopic; typed types are field-keyed, not in HANDOFF_TYPES)
- [x] `linkEventCatch` classification is reserved for catches carrying `aef:link` (workflowRef/targetWorkflow); the bare-catch default (neither extension) is decided and recorded in Decisions (bare → linkEventCatch, status quo, rationale in Decisions)
- [x] Throw side disambiguated the same way: `intermediateThrowEvent` + `aef:eventDef` does not classify as a catch-typed event (was: eventMessage + silent throw→catch tag mutation on re-export — behavior-proven pre-fix, gone post-fix; + `aef:link` still classifies linkEventThrow)
- [x] Round-trip safety: importing then re-exporting typed-events.bpmn and boundary-events.bpmn keeps their sha-pinned byte contract green (tests/test_typed_event_fixture_contract.py) and the T-219 offpage-seam link legs still classify as link events (no over-correction) (contract OK + pins OK + offpage 3/3 link legs on served editor; boundary events keep hostRef/interrupting)
- [x] Playwright-verified on the RUNNING :8834 gallery: drive the fixture through the served editor, assert node type + panel affordances for BOTH a typed catch and a real link catch; redeploy (cp src → build/gallery/designer.html) byte-identical (4 fixture legs driven: typed-events, throw-repro, boundary-events, offpage-seam; cmp clean)
- [ ] Announce on the rail when landed (rides the 0.3.1 tag with T-234) — with the fix commit and what AEF should re-verify on their aef-dispatch-loop map

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

# T-237 guard present in src + deployed byte-identical + served
grep -q "_catchHost" src/aef-workflow-designer.html
cmp src/aef-workflow-designer.html build/gallery/designer.html
# PL-051: full-consume grep -c, NOT echo|grep -q (860KB payload SIGPIPEs the L-387 pattern)
test "$(curl -sf http://localhost:8834/designer.html | grep -c "_catchHost")" -ge 1
# Fixture byte contracts stay green (round-trip safety)
python3 tests/test_typed_event_fixture_contract.py
python3 tests/test_corpus_fixture_pins.py
# The 0.3.0 artifact provably lacks the vocabulary (root-cause evidence stays checkable)
test "$(grep -c "EVENT_KIND_TYPE" dist/aef-workflow-designer-0.3.0.html)" -eq 0

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

**Symptom:** On AEF's pinned 0.3.0 bundle, a typed message-catch (`intermediateCatchEvent`
+ `<aef:eventDef kind="message">`, zero `aef:link`) shows as linkEventCatch ("← Handoff
from another workflow") with an inert "Open target workflow" affordance; their operator
escalated twice reading it as a broken handoff.

**Root cause (primary, their repro):** RELEASE-LINEAGE GAP, not a live code defect —
`dist/aef-workflow-designer-0.3.0.html` was cut 2026-07-18 (af90f67); T-204 typed-event
vocabulary (incl. the eventDef import override, 34ec243) landed 2026-07-19 and is NOT an
ancestor of the release commit. The 0.3.0 artifact contains ZERO eventDef handling
(verified: 0 grep hits), so every catch decodes via `REVERSE_TYPE['intermediateCatchEvent']
= 'linkEventCatch'`. Meanwhile the typed-event FIXTURE CONTRACT (T-212) shipped to AEF
rail-inline independently of any bundle version — AEF authored corpus maps in vocabulary
their pinned editor artifact predates. Master already classifies correctly
(behavior-verified this session on served :8834: typed-events.bpmn → eventError/Timer/
Message with bindings).

**Secondary defects found in-build (master, both fixed here):** (1) the T-204 override
applied to ANY host tag — an `intermediateThrowEvent` + eventDef imported as a catch-side
typed event and silently re-exported as `intermediateCatchEvent` (throw→catch tag
mutation); (2) a node carrying BOTH a targeted `aef:link` and an `aef:eventDef` classified
as the typed event, hiding the jump/target UI on a node that has a real target. Fix scopes
the override: catch-side hosts only (`intermediateCatchEvent`/`linkEventCatch`/
`boundaryEvent`) and only when no aef:link target is present.

**Why structurally allowed:** the vocabulary contract and the release artifact version
independently — nothing ties "which aef:* vocabulary a tagged bundle understands" to the
fixture contract a peer authors against (no vocabulary-coverage note in the release, no
release-lineage check when a fixture contract ships). And the throw-side mutation is the
G-010 class again: no standing behavior suite exercises import→re-export tag stability.

**Prevention:** (1) Verification pins the root-cause evidence (`dist/...0.3.0.html` has 0
EVENT_KIND_TYPE hits) so the lineage claim stays checkable; (2) G-010 (registered under
T-234) already carries the standing-behavior-suite requirement — this task's import/
re-export legs are named there as a second instance; (3) 0.3.1 release notes (operator's
tag) must state the vocabulary delta: "adds T-204 typed-event + T-234/T-237 fixes" — noted
in the rail announce so AEF pins vocabulary and artifact together; (4) learning: a
fixture/vocabulary contract delivered to a peer must name the MINIMUM bundle version that
understands it.

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

### 2026-07-22 — Bare-catch default (AEF left it 832's call)
- **Chose:** A catch event with NEITHER `aef:link` nor `aef:eventDef` keeps classifying as
  linkEventCatch (status quo).
- **Why:** The editor has no neutral "plain intermediate event" type; linkEventCatch is the
  EDITABLE affordance — the operator can set a target and make it a real handoff. AEF
  explicitly sanctioned either way ("neither-extension bare catches, your call"). Their
  operator's confusion came from eventDef-bearing nodes, which now classify typed.
- **Rejected:** Minting a new neutral intermediate-event node type — schema/palette/glyph/
  bridge growth for a shape no producer emits; wrong size for a 0.3.1 patch.

### 2026-07-22 — Override scope: catch hosts only; link-with-target wins over eventDef
- **Chose:** The eventDef type-override fires only when the host tag is
  intermediateCatchEvent / linkEventCatch / boundaryEvent, AND the node's aef:link (if any)
  carries no workflowRef/targetWorkflow.
- **Why:** (1) All EVENT_KIND types export as intermediateCatchEvent — overriding a THROW
  host silently mutated intermediateThrowEvent → intermediateCatchEvent on round-trip
  (behavior-proven pre-fix). No typed-THROW vocabulary exists yet, so a throw+eventDef
  keeps its link/throw classification (its eventDef payload drops on re-export — accepted:
  the shape is outside the T-204 contract, and tag preservation beats payload preservation
  for an invalid hybrid). (2) A node with a real link target must keep the jump/target UI;
  boundaryEvent must stay in scope — it's HOW boundary events acquire their type on import.
- **Rejected:** Preserving throw+eventDef payload via a typed-throw node family (future
  vocabulary — needs a contract round with AEF first, offered in the rail announce);
  eventDef-wins-over-link (hides a working jump affordance on a targeted node).

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-22T10:41:18Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-237-eventdeflinkeventcatch-vocabulary-collis.md
- **Context:** Initial task creation

### 2026-07-22T10:52:06Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
