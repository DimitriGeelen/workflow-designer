---
id: T-589
name: "designer properties panel: add a clickable component-fabric link and a URL field for code/tests"
description: >
  designer properties panel: add a clickable component-fabric link and a URL field for code/tests

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
created: 2026-08-25T22:39:21Z
last_update: 2026-08-25T22:39:21Z
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

# T-589: designer properties panel: add a clickable component-fabric link and a URL field for code/tests

## Context

Operator ask: the properties panel on the right of the designer — the box carrying
`Endpoint`, `Agent type`, `Tier` — needs two more fields:

1. a **link to the component fabric**, clickable through to the card
2. a **place for URLs** (code, tests)

### The design question, answered before building

The obvious risk was that new fields mean a **dialect change**: a new `aef:` element or a
new `metaKeys` entry, which breaks ratified parity with `tools/yaml-to-bpmn.py META_KEYS`
(`tests/test_editor_bridge_meta_parity.py`) and puts the frozen standard —
`docs/standards/aef-bpmn-mapping-v1.md`, not editable under agent control — in scope. That
would make this a coordination with 999-AEF rather than a build, exactly like CashWeb's
parked `<aef:pseudo>` ask.

**It is not.** T-570 already removed the blocker: import reads EVERY `<aef:meta>` attribute
into `node.aef` unconditionally, and export stopped filtering the bag on the way out
(`aefExtensionXml`, the `scalarHandled` skip set at :9605). `<aef:meta>` is already a bag of
scalar attributes. So two new **scalar** fields ride the existing carriage with no new
element, no `metaKeys` change (stays at 20), and nothing for AEF to ratify.

The constraint this imposes on the design: both fields must be **scalars**. A structured
value would need its own emitter and would then be a contract change. `links` therefore
holds newline-separated URLs in one string, not an array.

Before T-570 this same change would have silently DESTROYED both fields on the next save —
loaded, rendered nowhere, dropped on re-export. Worth stating because "add a field to the
panel" reads as trivial and was, until recently, a data-loss bug.

### Consumer evidence — arrived independently, twenty minutes after filing

001-CashWeb-Lightspeed-Ecwid-integration reported hitting exactly this ceiling in
production on `designer-v0.11.0`. Their operator's ask is *"click a node, GO TO the API test
and the code"* — the same sentence as this task, reached from the other side.

**Their measurement, re-run here against `src/aef-workflow-designer.html` rather than
taken on trust — every figure confirmed:**

| probe | theirs | ours |
|---|---|---|
| `linkify` | 0 | 0 |
| `window.open` | 0 | 0 |
| `location.href` | 0 | 0 |
| `<a ` literal | 0 | 0 |
| `createElement('a')` | 1 (download button) | 1, at `:8409` |

So the designer today **cannot navigate anywhere**. That is not a gap in this task's design,
it is the reason the task exists, and it means the anchor-rendering path is genuinely new
code rather than a variant of something already present.

They also confirmed T-566 and T-570 with numbers that reframe both:

- **T-566** — `note` is on all 14 node types in 0.11.0 and was on **zero** in 0.8.0. Their
  phase-1 map already carried **ten authored notes no operator had ever been able to see.**
  We described that fix as "46% unreadable"; on their side it was ten invisible facts.
- **T-570** — their `code-links.yaml` recorded three reasons the node→code binding was
  deliberately kept OUT of the `.bpmn`, one being *"an editor Save destroys prose the pinned
  build does not know about"*. T-570 retired that reason. They now write each node's
  implementing file and its API-test call id into `aef:meta note`. **Our carriage fix is
  load-bearing for a consumer's data model**, which is a stronger claim than the round-trip
  test makes.

### Their option (a) — NOT this task, and not authorised by their asking

They propose two shapes and prefer the one this task does not cover:

- **(b)** render a URL-shaped value in a known field as an anchor — **this task.**
- **(a)** emit an outbound `aef:select {uid}` on the annotation seam when a node is
  selected, so an embedding parent can render links beside the canvas and keep all policy
  consumer-side.

(a) is smaller than (b) and serves embedders rather than our own panel; they are
complementary, not alternatives. It is deliberately **not** folded in here — one task, one
deliverable — and a peer proposal is a PROPOSAL, not a build instruction (G-020). It also
adds an outbound message to the T-258 seam that other consumers parse, so whether to extend
that seam is the operator's call. Filed as evidence, not as scope.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] `fabricRef` and `links` exist in `FIELD_META` and appear in the `AEF_FIELDS` lists for
      the task-like node types that can carry an implementation (`serviceTask`,
      `scriptTask`, `subProcess`, `userTask`), ordered ABOVE `note` so they do not push the
      structured fields down (the ordering rule stated at :1844).
- [ ] `fabricRef` renders as a **clickable link** to Watchtower's existing
      `/fabric/component/<name>` route when non-empty, and renders as a plain field with no
      dead link when empty. The href is built from the live watchtower URL
      (`.context/working/watchtower.url`), never a hard-coded `:3000` port.
- [ ] `links` accepts multiple URLs (newline-separated) and renders each as a separate
      clickable anchor; a line that is not a URL is shown as text rather than a broken link.
- [ ] **Both fields survive a round trip**, proven by an actual parse -> build -> parse in
      the page rather than by reading the two lists — that is the T-570 lesson, where
      inspecting the whitelists said the keys were fine and the round trip said they were
      destroyed.
- [ ] `metaKeys` is still 20 entries and bridge parity still passes
      (`tests/test_editor_bridge_meta_parity.py`), proving this was carried by the existing
      `<aef:meta>` bag and is NOT a contract change.
- [ ] Exporting a document that carries NEITHER field is **byte-identical** to before the
      change. Adding an authorable field must not perturb documents that do not use it.
- [ ] Visual verification per CLAUDE.md: element-level screenshots of the panel with each
      field empty and populated, READ back, with the results recorded under
      `## Visual Verification`.

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

### 2026-08-25T22:39:21Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-589-designer-properties-panel-add-a-clickabl.md
- **Context:** Initial task creation
