---
id: T-473
name: "T-423's stated seam cost is false: AEF pins nothing our exporter produces"
description: >
  AEF measured their side at rail 584 Q1: source_bpmn_sha is a provenance field their bpmn_promote.py writes into their OWN corpus meta (sha of the staged BPMN being promoted, their file) per our IW-2 contract. It does not pin our bytes. They hold no copy of examples/aef-processes/rendered at all. So T-423's stated cost - all 24 corpus maps change bytes so AEF's pinned source_bpmn_sha fixtures need a COORDINATED re-pin - names a mechanism that does not exist, and T-423 says the re-pin is the whole cost. Correct the cost model in T-423 (description, body, and the AC that requires coordination), check whether T-340's pending ruling rests on the false premise, and record AEF's actual six pins and their announcement shape. Does not start T-423 or rule on T-340.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-12T20:41:16Z
last_update: 2026-08-12T20:46:05Z
date_finished: 2026-08-12T20:46:05Z
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

# T-473: T-423's stated seam cost is false: AEF pins nothing our exporter produces

## Context

AEF answered the four seam questions at **rail 584**; reply at **585**, acked at **586**.

**Q1 falsified the premise T-423's entire cost model rested on.** `source_bpmn_sha` is a
provenance field *AEF's* `bpmn_promote.py` writes into *AEF's* corpus meta, keyed
`(uid, source_bpmn_sha)` per our IW-2 contract — the sha of the staged BPMN **they** are
promoting. It has never pinned our bytes. And per their Q3, they hold **no copy** of
`examples/aef-processes/rendered/` — their own T-2522 says *"there is no rendered corpus in
AEF"*.

So T-423's "all 24 corpus maps change bytes, so AEF's pinned `source_bpmn_sha` fixtures need
a COORDINATED re-pin — this is the first step in the arc that touches the seam", and its
conclusion "the re-pin is the whole cost", were false in every clause. **Seam cost: zero.**
Surviving cost is one-party — our own `_t308-export-byte-identity` goes 24/24 drifted.

Corrected in **all three carriers in one pass** (frontmatter `description:`, body, and the
AC that demanded coordination). PL-171 is one session old; fixing the body and leaving the
summary field would have been that exact failure, in the task that exists to fix a premise.

### The false premise came from our own failure message

`tests/run-bridge-tests.sh:206` read *"typed-event fixture drifted from the pinned
source_bpmn_sha or aef:eventDef shape (fixture edited? re-pin + notify AEF)"*. That test
pins a **plain byte digest**; it is not `source_bpmn_sha` and never was. The instruction was
right, the label was wrong, and T-423's phrasing mirrors it almost verbatim.

A diagnostic string is read far more often than the code it describes, and it is read
precisely by someone already confused. Fixed at the source, with the correction stated in a
comment beside it. **Plausible-origin, not proven** — the construction appears nowhere else
in the tree, but I did not watch it propagate.

### The T-340 check (AC3): the ruling is unaffected, and here is why that is not luck

The brief argues from the re-pin cost twice, so the question was live. The recommendation is
**scoped (b)**, which changes **zero bytes** — carried by the disjoint-populations argument
(121 of 126 carry `aef:position`, none carry DI), not by a cost argument. An overstated cost
on the *rejected maximal* variant cannot make the *zero-byte* variant worse.

What does change: maximal (b) was rejected on two grounds and one has evaporated. The
survivor — `_t308` goes 24/24 drifted — is **entirely our own baseline**. A cost recorded as
two-party was one-party. Written into T-340 explicitly, including the warning not to
re-open it on the strength of "a cost disappeared", since maximal (b) is still rejected for
rewriting a peer's coordinate bytes.

### The row that will scare a later reader, defused in place

`s4-exemplar.bpmn` is export-path output here **and** appears in AEF's six pins. Those are
different files: they digest-guard their **vendored copy at their path**. Regenerating ours
cannot turn their guard red; only a re-delivery would. Written into T-423 next to the table,
because on a later skim that row reads like a landmine.

**And the gap it exposes, raised at 585 §4:** their guards detect *local mutation* of their
copies; nothing on either side detects *upstream divergence* — their copy staying identical
to itself while ours moves on. Both trees stay green and the files differ. Not fixable by a
cross-tree checker (T-559 forbids reaching in), so the obligation lands on us procedurally:
**announce on any change to a file they vendor, not only on ones we choose to re-deliver.**

### Not done here

T-423 is not started, T-340 is not ruled, no corpus byte moved (leg 11 pins it). **T-101 is
cleared by AEF's zero-exposure measurement** — it is `owner: human`, so that goes to the
operator with the evidence cited, not shipped under agent initiative.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **Every occurrence of the false premise in T-423 is corrected, not just the
      description.** It appears in the frontmatter `description:`, in the body, and in an
      Agent AC that requires a "coordinated, not announced" re-pin. PL-171 is one session
      old: fixing the field and leaving the body (or the reverse) is the failure this
      correction is supposed to be immune to.
- [x] **The corrected cost is DERIVED from AEF's measurement and cites it.** Their rail-584
      Q1 answer names the mechanism (`source_bpmn_sha` is written by *their* promote tool
      into *their* corpus meta, keyed by our IW-2 contract) and Q3 states they hold no copy
      of `examples/aef-processes/rendered/`. Both are recorded so a later reader can check
      the derivation rather than inherit "cost is zero".
- [x] **T-340's decision brief is checked for dependence on the false cost.** The operator's
      pending ruling is the arc's only blocker; if its recommendation is argued partly from
      T-423's re-pin cost, that argument changes and the brief must say so before it is
      acted on. Checked either way, with the result stated.
- [x] **AEF's six pins are recorded on our side, with the one that matters flagged.**
      `s4-exemplar` is export-path output here AND appears in their pin list — as a
      *vendored copy* at their path. The distinction (our regeneration does not touch their
      file; only a re-delivery would) is written down, because it is exactly the kind of
      thing that reads as danger on a later skim.
- [x] **The announcement protocol is recorded where the person announcing will look.** AEF
      specified the shape (rail post, one line per changed artifact, `path + old → new`,
      manifest above ~10). Filed in T-423 itself, not only in a report.
- [x] **Nothing is started and nothing is ruled.** T-423 stays blocked, T-340 stays the
      operator's, no corpus byte moves. Corpus tree hash pinned in Verification.

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

# Rail 584 (AEF's four answers) acked at 586; reply at 585.
#
# Legs 1-3 are quote-aware BY NECESSITY, not style — the first form went RED. The
# correction QUOTES the false clause verbatim (that is what makes it a retraction rather
# than a deletion), so `! grep -q '<false clause>'` finds its own fix. Fourth instance this
# session of producer-and-consumer composed in one file, and the first one I did NOT catch
# before writing the leg — the T-472 equivalent was caught pre-write, this was not.
# The companion leg is the positive control (PL-084): once "absent outside a CORRECTED
# line" is the predicate, deleting the whole description satisfies it. The quote must
# still be THERE, and marked.
# Leg 3's `^>` clause: the body quote line-wraps, so the first form passed by LUCK — a
# line-based grep simply missed a string split across two lines. Made explicit rather than
# left resting on where the paragraph happened to break.
#
# Legs 1-4 are the PL-171 guard: the false premise lived in the frontmatter description,
# the body, AND an AC. A leg checking only one of the three would have passed while the
# other two kept teaching the wrong cost model. Each is asserted separately and by a
# different anchor, so no single edit can green all three by accident.
# Leg 4 is the positive control (PL-084): the corrected section must EXIST, or "the false
# string is absent" is satisfiable by deleting the discussion entirely.

test "$(awk '/so AEF.s pinned source_bpmn_sha fixtures need a COORDINATED re-pin/ && !/CORRECTED/' .tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md | wc -l)" = "0"
test "$(awk '/so AEF.s pinned source_bpmn_sha fixtures need a COORDINATED re-pin/' .tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md | wc -l)" -ge 1
test "$(awk '/coordinated re-pin, not a unilateral/ && !/CORRECTED|^>/' .tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md | wc -l)" = "0"
/usr/bin/grep -q 'VOID 2026-08-12 (T-473)' .tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md
/usr/bin/grep -q '^## Seam cost, corrected' .tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md
/usr/bin/grep -q 'Announcement protocol' .tasks/active/T-423-t-357-step-2-emit-bpmn-di-additively-alo.md
/usr/bin/grep -q 'T-473) — half of that byte objection was imaginary' .tasks/active/T-340-standard-bpmn-di-is-silently-discarded-o.md
! /usr/bin/grep -q 'drifted from the pinned source_bpmn_sha' tests/run-bridge-tests.sh
/usr/bin/grep -q 'AEF vendors these two by digest' tests/run-bridge-tests.sh
bash -n tests/run-bridge-tests.sh
test "$(/usr/bin/grep -c '^- \[ \] \[REVIEW\]' .tasks/active/T-340-standard-bpmn-di-is-silently-discarded-o.md)" -ge 1
git diff --quiet HEAD -- examples/aef-processes/rendered tests/fixtures/aef-bpmn

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

### 2026-08-12T20:41:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-473-t-423s-stated-seam-cost-is-false-aef-pin.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a24b61de
- **Timestamp:** 2026-08-12T20:46:06Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-12T20:46:05Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
