---
id: T-423
name: "T-357 step 2: emit BPMN DI additively alongside aef:position"
description: >
  Second of the three nested increments under T-357's GO. Emit bpmndi (dc:Bounds for shapes, di:waypoint for edges, label bounds) on export while continuing to write aef:position. Additive: no T-225 silent-migration question because nothing the author wrote is rewritten or dropped, and the intent extensions (forceStraight, routingHint, loopDetour) stay, so the spike-3 intent gap does not bite. Costs: all 24 corpus maps change bytes. [CORRECTED 2026-08-12 by T-473 — the clause that stood here, "so AEF's pinned source_bpmn_sha fixtures need a COORDINATED re-pin — this is the first step in the arc that touches the seam", is FALSE. Measured on AEF's side at rail 584 Q1: source_bpmn_sha is a provenance field THEIR promote tool writes into THEIR corpus meta, keyed by our IW-2 contract; it pins nothing of ours. They hold no copy of examples/aef-processes/rendered at all. The 24 maps are a ZERO-cost change at the seam. See ## Seam cost, corrected.] Blocked on step 1 (T-340 option b) landing. NOT blocked on A-020 — that was answered NO at rail 417 (2026-08-03) and is recorded invalidated: AEF never parsed or emitted DI and holds no record of agreeing to. The consequence sharpens this task rather than gating it — with no downstream DI generator on either side of the seam, emitting DI is NET-NEW CAPABILITY on both sides, not the completion of a handoff someone else was already honouring. Nobody is waiting for these bytes, and [CORRECTED by T-473: "the re-pin is the whole cost" was the conclusion drawn from the false premise above — there is no re-pin, so the seam cost is zero and the remaining cost is entirely one-party: our own _t308-export-byte-identity goes 24/24 drifted] the benefit is portability to standard viewers (bpmn.io, Camunda), not AEF interop.

status: started-work
workflow_type: build
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: [T-357, T-340, T-424, T-425]
arc_id: designer-authoring-surface
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-10T20:23:27Z
last_update: 2026-08-14T15:26:58Z
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

# T-423: T-357 step 2: emit BPMN DI additively alongside aef:position

## Context

Step 2 of three under T-357's GO (operator, 2026-08-10). Research: `docs/reports/T-357-di-adoption.md`.

**Not started — this task is scoped, not built.** ACs written now because G-020 requires
real criteria before any source edit, and because writing them is what exposes whether the
step is actually ready. It is not: it sits behind T-340's ruling.

Why this is the first step that touches the seam: steps land in strict subset order, and
step 1 (T-340 scoped `b`) is byte-neutral because the two populations are disjoint —
121 of 126 files carry `aef:position` and none carry DI. Step 2 breaks that: **every**
export gains a `bpmndi` sub-tree, so all 24 corpus maps change bytes.

> **CORRECTED 2026-08-12 (T-473).** This paragraph ended *"and AEF's pinned
> `source_bpmn_sha` fixtures go red. That is a coordinated re-pin, not a unilateral
> change."* Both sentences are false, and with them the claim that step 2 is the first step
> that touches the seam. See **§ Seam cost, corrected** below.

What A-020's answer changed: there is no DI generator anywhere — not on AEF's side (rail
417: `bpmndi` occurs once in their source, a namespace declaration with no reader or
writer) and not on ours. So emitting DI is net-new capability, and the beneficiary is any
standard viewer (bpmn.io, Camunda), **not** AEF. Nobody is waiting for these bytes. That
removes the urgency and clarifies the trade: ~~pay a two-party re-pin~~ **pay a one-party
byte churn on our own `_t308` baseline**, buy portability.

## Seam cost, corrected (2026-08-12, T-473 — from AEF's measurement at rail 584)

**The seam cost of this task is zero.** Not "small" — the mechanism it was attributed to
does not exist:

- `source_bpmn_sha` is a **provenance field AEF's own `bpmn_promote.py` writes into AEF's
  corpus meta**, keyed `(uid, source_bpmn_sha)` per our IW-2 contract. It records the sha of
  the staged BPMN *they* are promoting — their file. It has never pinned our bytes.
- **AEF holds no copy of `examples/aef-processes/rendered/`.** Their own T-2522 report says
  *"there is no rendered corpus in AEF"*; the only occurrences of our paths in their tree are
  prose in two reports.

So all 24 maps can change bytes with no coordination required and nothing of theirs going
red. What survives is a **one-party** cost that was never AEF's: our own
`_t308-export-byte-identity` goes 24/24 drifted. That is a baseline we own and refresh.

### What AEF actually vendors — six artifacts, byte-digested, two of them ours

| their constant | file | export-path output here? |
|---|---|---|
| `SHA_832_TYPED` | `tests/fixtures/aef-bpmn/typed-events.bpmn` | **no** |
| `SHA_832_BOUNDARY` | `tests/fixtures/aef-bpmn/boundary-events.bpmn` | **no** |
| `CANONICAL_SHA256` | their `inception-gonogo-canonical.bpmn` | their file |
| `RESUME_STATUS_SHA256` | their `resume-status-canonical.bpmn` | their file |
| `832/pair-draft-3.sha256` | their vendored copy | their file |
| `832/s4-exemplar.sha256` | their vendored copy | their file |

**Read the last row carefully before it scares a later reader.** We do have an
`s4-exemplar.bpmn` and it *is* export-path output — but AEF's digest guards **their vendored
copy at their path**. Regenerating ours does not touch their file and cannot turn their guard
red. Only a **re-delivery** of new bytes would, and that is a deliberate act.

The two rows that are genuinely ours-and-theirs (`typed-events`, `boundary-events`) are both
**not** export-path output — the T-469 finding, now confirmed from the other end.

### Announcement protocol (AEF's stated preference, rail 584 Q4)

If any of the six ever moves: **a rail post, one line per changed artifact, `path + old →
new` digest, inline.** Not a manifest (the digests *are* the payload, and there are at most
six), not a version bump (it carries no per-file digests). Manifest only if a single change
ever moves more than ~10 at once.

**Lead time is wanted for notice, not for work.** Their cost is one constant edit plus one
test run — minutes. The reason to announce *before* is that their guard's failure message
tells the reader to conclude someone mutated a fixture locally; an unannounced change makes
a true event read as tampering.

## Ordering satisfied, and two obstacles the ACs did not anticipate (2026-08-14)

**The gate this task was waiting on is open.** Operator recorded ruling (b) as PD-200 and
step 1 landed at `fc7f7263`: the importer now reads DI behind `aef:position`, and the
emitter re-emits DI when the input carried it. So the first AC below is satisfied and the
two-contradictory-geometries risk it names is gone — DI written by step 2 is now readable.

Two things block the rest, neither of which is in the ACs:

**(1) The `DI_TRAILER` disposition is unowned, and step 2 forces it.**
Step 1 left the emitter as `if (sourceCarriedDi) { DI block } else { trailer }`. Step 2
makes DI unconditional, so the `else` never fires and `DI_TRAILER_PREFIX` stops being
emitted — permanently, on every export. That prefix is documented at `src:9430` as
load-bearing: *"documents exported by all 11 prior releases carry it, and both readers
match on it."*

- **Our reader is fine.** `src:9540` uses it only to decide that a comment consisting of
  nothing but the trailer is not an authored doc comment. Absent trailer → null doc
  comment, which is the same outcome. Checked, not assumed.
- **AEF's reader is not visible from here** and is the reason this is a rail question
  rather than a code question.

The task that would have owned this is **T-425, closed `work-completed` as a duplicate** —
correctly, because the defect it was filed against had already been fixed by T-361. But
withdrawing it retired the ticket and not the obligation, and step 2 is where that
surfaces. Same shape as this week's others: something closed for a good reason leaves an
adjacent question with no owner, and the next step walks into it.

**(2) The schema-validation AC cannot be satisfied in this environment.**
It requires validating an exported map against the BPMN 2.0 DI schema and explicitly rules
out the cheap substitute (*"not by grepping for the element names"* — which is the right
instruction and is exactly what this week says about mention-vs-instance). There is no
`xmllint` on this host and no `.xsd` anywhere in the tree. The AC is not wrong; it is
unbuildable until a validator exists. Left unticked and stated rather than downgraded into
a grep, which is the failure it was written to prevent.

**Status: `started-work` (set by `fw work-on` when I opened it to record this). No source
edited under this task, and none will be until §2's rail question is answered.** An earlier
draft of this paragraph said `captured`, which was true when I wrote the sentence and false
by the time it was committed — the same stale-claim shape as T-340's BLOCKED paragraph,
caught one commit later instead of twelve days.

## Acceptance Criteria

### Agent
- [x] **Ordering respected: this task does not start until T-340 is ruled and step 1 has
      landed.** Step 2's precedence rule (`aef:position` → else DI) is step 1's deliverable;
      building step 2 first means writing DI that the importer cannot yet read, which is
      the two-contradictory-geometries state PL-114 exists to prevent, self-inflicted.
      **Satisfied 2026-08-14: PD-200 ruled, step 1 landed at `fc7f7263`.**
- [ ] `bpmndi:BPMNDiagram` / `bpmndi:BPMNPlane` emitted on export with `dc:Bounds` for every
      shape, `di:waypoint` for every edge, and label bounds where a label position is
      persisted. Verified by validating one exported map against the BPMN 2.0 DI schema —
      not by grepping for the element names.
- [ ] `aef:position` is **still written**, unchanged, on every node. This is the property
      that keeps step 2 out of T-225's scope: it adds a representation and rewrites nothing.
      A diff of one round-tripped map shows DI added and no existing element removed or
      reordered.
- [ ] The intent extensions (`forceStraight` 12, `routingHint` 22, `loopDetour` 9,
      `anchors` 19, `aef:waypoint` 1) are untouched. Spike 3 established DI has no
      vocabulary for layout *intent*, only for computed results, so DI cannot carry these
      and must not be treated as having replaced them.
- [ ] Round-trip is lossless in both directions: export → re-import → export produces
      byte-identical output on all 24 corpus maps. A DI emitter that is not idempotent
      makes every save a spurious diff.
- [ ] ~~**Re-pin is coordinated, not announced.**~~ **VOID 2026-08-12 (T-473)** — this AC
      required agreement AEF has no stake in. It read: *"AEF's `source_bpmn_sha` fixtures are
      pinned over whole files; all 24 change. Agreed with AEF on the rail BEFORE the bytes
      change."* They pin none of the 24 and hold no copy of the corpus (rail 584 Q1/Q3).
      **Replacement obligation, which is weaker and different in kind:** none of AEF's six
      vendored digests is touched by this task, so nothing needs agreeing. *If* a future
      change moves one of the six, announce per § Seam cost → Announcement protocol — a
      rail post, one line per artifact, `path + old → new`, before the bytes change. Notice,
      not permission.
- [ ] A competing-carrier guard exists, in AEF's shape rather than ours: they pin
      `test_di_drop_has_a_competing_carrier`, which asserts the rival carrier *exists* —
      delete `aef:position` and the test goes red. Our equivalent must fail loudly the day
      step 3 removes `aef:position`, instead of silently permitting two geometries.
      (Adopting their instrument, not just their answer — T-340's Human AC records why.)

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

### 2026-08-10T20:23:27Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md
- **Context:** Initial task creation

### 2026-08-10T20:29:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-08-10T20:31:11Z — status-update [task-update-agent]
- **Change:** status: started-work → captured

### 2026-08-14T15:24:27Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
