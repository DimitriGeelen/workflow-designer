---
id: T-324
name: "offpage-seam.bpmn carries <bpmn:linkEventThrow>, an element no emitter can produce: coordinated re-pin with AEF"
description: >
  T-321's vocabulary gate found 3 <bpmn:linkEventThrow> elements in tests/fixtures/aef-bpmn/offpage-seam.bpmn. That is not a BPMN element -- it is the canonical YAML type name sitting in the BPMN namespace. Neither emitter can produce it: the bridge (TYPE_MAP) and the designer (TYPE_TAG) both rename linkEventThrow to intermediateThrowEvent on export, so these bytes cannot have come from our toolchain. The file is byte-pinned in tests/test_corpus_fixture_pins.py FULL_SHA and cross-validated by AEF plus tools/_offpage-seam-parity-verify.py, so it must NOT be edited unilaterally -- repair is a coordinated re-pin in lockstep with the peer, exactly as T-314 handled the lane-geometry defect in the fixtures they hold. Until then a COUNTED tolerance in test_corpus_fixture_pins.py admits exactly 3 findings, prints a NOTE every run, and fails the build on a 4th. Before the fix was possible this defect was invisible except as an I-XML-LANE-CAPACITY-SKIP note from an unrelated rule that refuses to guess occupancy.

status: started-work
workflow_type: build
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-01T13:50:30Z
last_update: 2026-08-01T21:08:29Z
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

# T-324: offpage-seam.bpmn carries <bpmn:linkEventThrow>, an element no emitter can produce: coordinated re-pin with AEF

## Context

Three `<bpmn:linkEventThrow>` host elements in the AEF-held fixture are not BPMN at all — they are our canonical YAML type name sitting in the BPMN namespace, and neither emitter can produce them. **AEF signalled GO on the rail at offset 363 (2026-08-01); their reply is answered at 364.** Repair is a coordinated re-pin in lockstep with the peer, T-314 shape.

**What AEF stated at 363 (their side, taken as given, not re-verified by us):**
- Their copy is `tests/fixtures/832/pair-draft-3.bpmn` — believed to be the same bytes under a different name. sha256 `0bc15bfac81d80cc13df527a09056dda6170def304d5a43c038bb504b691449d`, pin green, 5 tests passing.
- Their Pass 5 (`tools/bpmn_to_tasks.py:650`) classifies off-page legs purely from `<aef:link>` attributes and finds the host by walking to the nearest ancestor carrying an id. **The element type is never inspected**, so the host tag may be rewritten freely.
- The only invariants they require preserved: the `<aef:link>` child with `workflowRef` / `targetWorkflow` / `name` intact, and the host element keeping its `id` and `name`.
- They re-pin on announcement of the new sha256 with the bytes, per their fixtures README.

**Scope discipline — same-artifact is NOT established.** Only the 12-char prefix `0bc15bfac81d` matches what we recorded. Twelve characters of agreement is not identity. AC1 verifies the full 64 before any bytes are sent; if they diverge, AEF hears that instead of bytes.

**Their safety argument is sound but narrower than they wrote it.** Element-type-blindness in Pass 5 entails both "this correction is safe" and "so would any other rename be" — one fact, two sentences. Safety therefore holds **for the forward compile and for nothing else not separately checked**. Any consumer that does read element type is untouched by it — our own node-type gate (T-321) is exactly such a consumer, which is why this surfaced our side and not theirs. So our own validator run (AC4) is a real check, not a formality.

## Acceptance Criteria

### Agent
- [ ] Full 64-char sha256 of our fixture is captured and compared against AEF's `0bc15bfac81d80cc13df527a09056dda6170def304d5a43c038bb504b691449d`. If they differ, STOP: post the divergence to the rail and do not send bytes — the artifacts are not the same file and the re-pin plan does not apply as written.
- [ ] Exactly 3 `<bpmn:linkEventThrow>` host elements are rewritten to `<bpmn:intermediateThrowEvent>` + a `<bpmn:linkEventDefinition>` child. No other element, attribute, or byte in the file is changed.
- [ ] AEF's two invariants hold in the corrected bytes: each rewritten host retains its `id` and `name`, and its `<aef:link>` child retains `workflowRef`, `targetWorkflow` and `name` unchanged. Verified by diffing the attribute sets, not by reading.
- [ ] The corrected fixture validates clean under `tools/validate-workflow.py` — zero `E-XML-NODE-TYPE` findings (this is the consumer AEF's element-type-blind argument does NOT cover).
- [ ] The counted tolerance in `tests/test_corpus_fixture_pins.py` that admits exactly 3 findings is DELETED, not decremented to zero — T-314 shape: when the reason for a tolerance is gone, the tolerance goes with it. A reintroduced malformed element must fail the build on the first instance, not the fourth.
- [ ] `FULL_SHA` for this fixture is updated to the new digest and `tools/_offpage-seam-parity-verify.py` passes against the corrected bytes.
- [ ] Gating suite green: `tests/run-bridge-tests.sh` and the validator suite, both 0 failed, counts recorded in this task.
- [ ] Teeth: reverting one of the three rewrites (real tree, restored byte-identical afterwards) makes the node-type gate fire. Assert the mutation LANDED (occurrence count before the verdict) — a null result renders identically to a clean pass (L-321), and landing is necessary but not sufficient (L-326): confirm the gate's finding count actually moved.
- [ ] New sha256 announced to AEF on the rail WITH the bytes, naming what changed and what did not.

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
# ── T-324 verification (drafted at filing under a wrap-up budget; UNRUN.
#    Re-check each one against the real tree before relying on it — the fixture
#    path below comes from this task's own description, not from a fresh read. ──
test -f tests/fixtures/aef-bpmn/offpage-seam.bpmn
# the malformed element is gone entirely (anchored on the structural literal, not the bare word)
test "$(grep -c '<bpmn:linkEventThrow' tests/fixtures/aef-bpmn/offpage-seam.bpmn)" = "0"
# and was replaced 3-for-3, not dropped
test "$(grep -c '<bpmn:linkEventDefinition' tests/fixtures/aef-bpmn/offpage-seam.bpmn)" = "3"
# AEF's invariant: every aef:link child survived with its three attributes
test "$(grep -c 'workflowRef=' tests/fixtures/aef-bpmn/offpage-seam.bpmn)" = "3"
# the consumer their element-type-blind argument does NOT cover
out=$(python3 tools/validate-workflow.py tests/fixtures/aef-bpmn/offpage-seam.bpmn 2>&1); echo "$out" | grep -qv 'E-XML-NODE-TYPE'
# the tolerance is DELETED, not decremented — anchored past its own explanatory comment (G-009)
test "$(grep -vE '^[[:space:]]*#' tests/test_corpus_fixture_pins.py | grep -c 'linkEventThrow')" = "0"
python3 tools/_offpage-seam-parity-verify.py
tests/run-bridge-tests.sh
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

### 2026-08-01T13:50:30Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-324-offpage-seambpmn-carries-bpmnlinkeventth.md
- **Context:** Initial task creation

### 2026-08-01T21:10Z — UNBLOCKED: AEF signalled GO on the rail
- **Action:** Read rail offset 363 (AEF), replied at 364. Wrote real ACs + Verification. Horizon next → now.
- **Blocker cleared:** This task was gated on AEF's signal. They gave it, plus the two facts that make the repair safe on their side (Pass 5 is element-type-blind; the invariants are the `<aef:link>` attributes and the host's id/name).
- **NOT done, and deliberately:** no bytes touched, no sha verified, no test run. The session hit the budget gate (307K, ~102%) while reading the rail — Bash and source Write/Edit are blocked. Everything above is a record of an inbound signal, not work claimed.
- **First action next session:** verify the full 64-char sha against AEF's before anything else. Same-artifact is an assumption, not a finding.

### 2026-08-01T21:08:29Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
