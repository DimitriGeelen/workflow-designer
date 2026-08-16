---
id: T-242
name: "dual-form aef:link contract: workflowRef authoritative, alias preserved on
  round-trip"
description: >
  AEF rail 168 (their T-2612) contract sanity-check on dual-form <aef:link targetWorkflow=slug
  workflowRef=uuid> found two hazards in our tree: (1) buildBpmnXml emits workflowRef
  ELSE targetWorkflow — dual-form loses the alias on re-export (silent migration;
  breaks the 0.3.1-pin compatibility the alias exists for); (2) T-240 binding precedence
  gives the slug priority, so a stale slug shadows a resolvable uuid — contract says
  workflowRef authoritative. Fix: emit BOTH attrs when both present; bind uuid-first-when-resolvable
  with slug fallback.

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
created: 2026-07-23T07:10:50Z
last_update: '2026-08-16T12:33:45Z'
date_finished: 2026-07-23T07:16:09Z
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
  - ts: '2026-08-16T12:33:45Z'
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
---

# T-242: dual-form aef:link contract: workflowRef authoritative, alias preserved on round-trip

## Context

AEF migrated their corpus to uuid workflowRef form ahead of the T-240 consumer capability —
their operators hit dead handoff jumps corpus-wide on pinned 0.3.1 (rail 168, their T-2612).
Their interim: `fw corpus emit` now writes dual-form `<aef:link targetWorkflow="slug"
workflowRef="uuid" …/>` so 0.3.1 binds via the slug while the uuid stays canonical. They asked
us to sanity-check dual-form against our tree AND the T-240 implementation before the hotfix
cut. Check found two hazards (both ours):

1. **Alias dropped on re-export** — `buildBpmnXml` emitted `workflowRef` ELSE `targetWorkflow`;
   a dual-form node re-saved through our editor silently lost the alias (silent migration,
   and it would re-break their 0.3.1 pin for that map).
2. **Slug shadows uuid** — T-240's `effectiveJumpTarget` gave the slug priority; a stale slug
   (target renamed) shadows a resolvable uuid → dead jump. Contract-v0: workflowRef is
   authoritative when both attrs are present.

## Acceptance Criteria

### Agent
- [x] Round-trip preservation: a dual-form link node re-exports with BOTH attributes
      (`workflowRef` + `name` + `targetWorkflow`) — no attr is dropped; legacy-only and
      uuid-only nodes serialize exactly as before (fixtures unaffected).
      *(suite emit asserts: n_dual line keeps both attrs, n_res exactly workflowRef+name,
      n_leg slug-only shape unchanged; corpus pins test green — fixture bytes untouched)*
- [x] Binding precedence per contract-v0: when both attrs are present, a RESOLVABLE
      workflowRef wins (readout + jump go to the uuid-resolved map even when the slug is
      stale/divergent); when the uuid does not resolve (ghost/API-down), the slug fallback
      binds exactly as 0.3.1 did.
      *(n_dual probe: stale slug "stale-old-name" + live uuid → panel shows t240-target with
      auto-resolved marker, effectiveJumpTarget = t240-target, alias untouched in state;
      n_fall probe: ghost uuid + live slug → binds t240-target via slug, unmarked)*
- [x] Legacy-only nodes (slug, no uuid) bind via the slug unchanged; uuid-only nodes keep
      the T-240 behavior.
      *(n_leg probe: readout t240-target, no marker, jump enabled; n_res/n_gh probes unchanged)*
- [x] The G-010 suite's t240 leg is extended with dual-form probes: stale-slug+live-uuid
      (uuid must win), and emit assertions that dual-form keeps both attrs while uuid-only
      keeps exactly one; full suite passes.
      *(5 probes: n_res, n_gh, n_dual, n_leg, n_fall; 4/4 legs green; pytest wrapper green)*
- [x] The T-240 "explicit targetWorkflow always wins" decision is superseded in writing
      (Decisions section) citing the rail-168 contract ask.
- [x] Python-side parse safety confirmed tree-wide: `_legacy_refs_from_text` skips any
      `<aef:link>` with a workflowRef, so dual-form contributes exactly one uuid-pinned
      ref and a stale alias can never mint a spurious name-only ghost; remaining
      `targetWorkflow` consumers are producers/fixture-verifiers (yaml-to-bpmn, seam
      verifiers) — no dual-form consumer hazard.

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

## Recommendation

**Recommendation:** GO
**Rationale:** Contract compliance verified with five in-suite probes covering every
attr combination (uuid-only, ghost, dual stale-slug, legacy-only, dual ghost-uuid);
serialization asserted per-line so no fixture or legacy shape changed; Python-side
safety confirmed by code (legacy extractor skips workflowRef-bearing links). This
unblocks AEF's ask 2 and clears the way for the 0.3.2 hotfix cut (ask 1, operator-gated).
**Evidence:**
- Suite 4/4 legs green with the extended t240 leg (n_dual: uuid wins over stale slug,
  marker shown, alias untouched; n_fall: slug fallback binds; n_leg unmarked slug bind)
- Emit asserts: dual keeps both attrs, uuid-only gains nothing, legacy-only unchanged
- tests/test_editor_behavior.py + tests/test_corpus_fixture_pins.py green

## Verification

out=$(node tools/_editor-behavior-verify-cdp.mjs 2>&1); python3 -c "import json,sys; v=json.loads(sys.argv[1]); assert v['pass'], 'suite failed'; legs={l['leg']: l['pass'] for l in v['legs']}; assert legs.get('t240-uuid-resolve'), 't240/t242 leg failed'" "$out"
python3 -m pytest tests/test_editor_behavior.py tests/test_corpus_fixture_pins.py -q
grep -q "T-242 (AEF rail 168, contract-v0 dual-form)" src/aef-workflow-designer.html
out2=$(grep -A1 "function effectiveJumpTarget" src/aef-workflow-designer.html); echo "$out2" | grep -q "return resolveWorkflowRef(n) ||"
grep -q "n_dual" tools/_editor-behavior-verify-cdp.mjs
grep -q "n_fall" tools/_editor-behavior-verify-cdp.mjs

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

**Symptom:** (latent, peer-caught) A dual-form `<aef:link>` re-saved through the editor
would lose its `targetWorkflow` alias; and post-T-240, a stale alias slug would shadow a
resolvable uuid into a dead jump.
**Root cause:** `buildBpmnXml`'s link emit was an either/or (`workflowRef` ELSE
`targetWorkflow`) written in the T-225 era when the two forms never co-existed on one
node; T-240's precedence was authored against the same single-form assumption.
**Why structurally allowed:** No fixture or suite probe carried BOTH attrs on one node —
the seam matrix (resolved/ghost/legacy) treated the forms as disjoint, so the dual cell
was never exercised.
**Prevention:** The G-010 suite now carries permanent dual-form probes (n_dual, n_fall)
asserting binding precedence AND per-line emit shape; any future either/or regression in
parse, bind, or emit fails the standing suite.

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

### 2026-07-23 — Binding precedence: workflowRef authoritative (supersedes T-240 AC wording)
- **Chose:** A RESOLVABLE workflowRef wins over an explicit targetWorkflow slug; the slug
  is the fallback when the uuid does not resolve. Supersedes T-240's "explicit
  targetWorkflow always wins" (my own design guess, ratified nowhere).
- **Why:** Contract-v0 per AEF's rail-168 ask: dual-form = "both attrs present, workflowRef
  authoritative". Slug-first re-creates the rename hazard the uuid exists to fix — a stale
  alias would shadow a resolvable uuid into a dead jump.
- **Rejected:** Keeping slug-first (breaks the peer contract and the rename case);
  dropping the alias on emit to avoid the question entirely (silent migration, and it
  re-breaks maps for any consumer still pinned pre-T-240).

### 2026-07-23 — Alias preservation on emit (no normalization)
- **Chose:** Dual-form emits BOTH attrs verbatim; the editor never adds, drops, or
  rewrites either attr. Normalization (folding to uuid-only) stays AEF-side in their
  canonical().
- **Why:** The ratified no-silent-migration rule; the alias is load-bearing for
  pre-T-240 pinned editors, and 832 stripping it on a casual re-save would silently
  re-dead their corpus jumps.
- **Rejected:** Emit-side folding to workflowRef-only (that IS the hazard AEF asked us
  to check for).

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

### 2026-07-23T07:10:50Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-242-dual-form-aeflink-contract-workflowref-a.md
- **Context:** Initial task creation

### 2026-07-23T07:16:09Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
