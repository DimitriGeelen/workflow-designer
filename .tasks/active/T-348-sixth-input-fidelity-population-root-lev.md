---
id: T-348
name: "Sixth input-fidelity population: root-level siblings of the process element"
description: >
  Populations 1-5 all ask about a single bpmn:process and what lives inside it (unknown tag, unknown branch, malformed doc, unresolvable ref, content of an accepted element). Nothing has ever asked what happens to definitions' OTHER children — bpmn:collaboration, participant/messageFlow, bpmn:message, bpmn:signal, bpmn:error, bpmn:dataStore, or a second bpmn:process. These are referenced BY nodes, so dropping them may emit a document with dangling references rather than merely a poorer one: a different consequence class from T-347.

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
created: 2026-08-02T12:44:22Z
last_update: 2026-08-02T12:44:22Z
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

# T-348: Sixth input-fidelity population: root-level siblings of the process element

## Context

Five input-fidelity populations exist on `tools/_t338-input-fidelity-cdp.mjs`. Every one
of them asks a question about **a single `bpmn:process` and what lives inside it**:

| # | task | question |
|---|---|---|
| 1 | T-337 | an unknown flow-node **tag** |
| 2 | T-340 | an unknown **branch** (the whole `bpmndi` sub-tree) |
| 3 | — | a **malformed** document |
| 4 | T-341 | an **unresolvable ref** (`flowNodeRef`) |
| 5 | T-347 | the **content** of an element already accepted |

Nothing has asked what happens to `bpmn:definitions`' **other children**:
`bpmn:collaboration` (with `participant` / `messageFlow` — what every mainstream
modeller emits for pools), root-level `bpmn:message`, `bpmn:signal`, `bpmn:error`,
`bpmn:dataStore`, and a **second `bpmn:process`**.

The reason to ask separately rather than assume T-347's answer: these root elements are
**referenced by nodes**. If the designer drops the referent but keeps the referencing
construct, the emitted document has a **dangling reference** — invalid BPMN, not merely
poorer BPMN. That is a different consequence class from every population so far, all of
which lose data while leaving the output well-formed. If instead it drops both ref and
referent, the output is self-consistent and this collapses into T-347's decision.

**Which of those two it is, is the whole point of the task.**

## Acceptance Criteria

### Agent
- [ ] A sixth population is added to `tools/_t338-input-fidelity-cdp.mjs` covering the
      root-level siblings of the process element: at minimum `collaboration`+`participant`,
      `messageFlow`, root `message`, root `signal`, root `error`, `dataStore`, and a
      second `process`.
- [ ] The population contains a **positive control that must survive** — the first
      `bpmn:process` itself is read and re-emitted, so if the control reads dropped the
      probe is broken and not the designer. A population of only-expected-to-drop rows
      cannot distinguish loss from a probe that injected nothing.
- [ ] Every row records whether injection actually reached the input (marker present
      before round-trip). A row that applied to 0 maps is a failure, not a zero.
- [ ] **The dangling-reference question is answered explicitly**, by a check that
      separates the two outcomes: for a referenced root element (e.g. `message` +
      a node carrying `messageEventDefinition messageRef`), the emitted document is
      classified as SELF-CONSISTENT (both ref and referent gone) or DANGLING (ref kept,
      referent gone). The verdict is derived from the output document, not predicted from
      reading `buildBpmnXml`.
- [ ] Teeth: at least one leg mutates the **designer** so a currently-dropped root shape
      comes back preserved, and one leg mutates it so a currently-preserved one is lost —
      both verdict buckets proven fillable in the subject, not just in the instrument.
      Every leg fails naming its own condition; a leg asserting only `rc != 0` is not
      accepted (T-338 leg (d)).
- [ ] Any verdict bucket that is never observed is recorded as **unwitnessed with its
      reason** (unreachable vs merely not exercised) rather than left to read as
      "this does not happen".
- [ ] The instrument stays green (`rc=0`) with the new population's expectations declared,
      and the expectations are re-measured every run so a gap that CLOSES also fails —
      no decay into a permission list.
- [ ] Findings filed as a task if the designer loses data; if the loss is
      repair-semantics-identical to T-347, say so and fold it into T-347 rather than
      opening a parallel decision for the operator.

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

### 2026-08-02T12:44:22Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-348-sixth-input-fidelity-population-root-lev.md
- **Context:** Initial task creation
