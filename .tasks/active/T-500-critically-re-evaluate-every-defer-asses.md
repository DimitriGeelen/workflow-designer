---
id: T-500
name: "critically re-evaluate every DEFER assessment"
description: >
  critically re-evaluate every DEFER assessment

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
created: 2026-08-14T12:11:01Z
last_update: 2026-08-14T15:28:08Z
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

# T-500: critically re-evaluate every DEFER assessment

## Context

Operator asked for a critical re-evaluation of all DEFER assessments.

## Findings

### 0. The population is far smaller than it looks, and two searches were wrong first

- Grepping `DEFER` in `decisions.yaml` returned 3 — one of which (T-121) matched the
  **node name** `n_end_defer`. Mention-vs-instance.
- Scanning `## Decision` blocks for "defer" returned **~300 tasks** — because the task
  TEMPLATE's boilerplate comment reads `fw inception decide T-XXX go|no-go|defer`. The
  scan matched the template, not any decision. Eighth broken instrument this week, same
  class. Fixed by stripping `<!-- -->` before matching.

**Derived population:** exactly **1** recorded DEFER decision (T-155), plus **20**
tasks parked at `horizon: later`.

**Stated blind spot:** a defer recorded only in prose, in Context or Updates rather than
in `## Decision`, is invisible to this scan (PL-145). Not claimed absent — unmeasured.

### 1. The single formal DEFER is not a defer

T-155's `## Decision` reads `**Decision**: DEFER` with rationale *"pending operator
input on IW-1/IW-2"*. That is not a decision to wait; it is **blocked on an unanswered
question**. And the same rationale then states a full positive recommendation —
A1 + B1 + C1, with A4+B2+C2 explicitly rejected.

So the agent HAS a position, and the DEFER label conceals it. Re-evaluated: this should
read as a **GO recommendation awaiting operator ratification**, not a defer. Parked
16 days.

### 2. Zero of 21 carry a revisit trigger

`revisit_at` is uncommented in **0** files across the whole tree. T-1451 built G-053 as
a daily revisit scan; it has nothing to fire on for any deferred or parked item. So
every one of these is, mechanically, indistinguishable from an abandonment — the
exclusion-vs-hole distinction (AEF rail 617 §2) applied to time. The handover surfaces
exactly one of them ("T-155 deferred with no revisit date"), which understates it 21×.

### 3. `horizon: later` is being used as a defer and is not one

`later` is a scheduling field; DEFER is a decision with a rationale. Operationally they
are the same here — parked, no trigger, no stated re-entry condition. The 20 carry no
recorded justification that a re-evaluation could test, which makes "has the evidence
changed?" unanswerable at scale. That is the finding, not a side note.

### 4. Age distribution — three arc children are the oldest

    34 d   T-184, T-185, T-186   arc children 3/4/5, owner human
    23 d   T-233, T-241
    22 d   T-246                 consumer-facing release metadata
    17 d   T-277..T-294          eleven tasks, mostly owner human
    16 d   T-155, T-301
    11 d   T-355
     4 d   T-424                 downstream of T-340's ruling — trigger EXISTS, unrecorded
     3 d   T-443

~~T-424 is the one defer whose re-entry condition is genuinely known (T-340's ruling) and
it still carries no `revisit_at`. That is the cheapest correction available and it is
one field.~~

**FALSE — see §8.** Left struck through rather than deleted, because this sentence is the
one I acted on. The line above it in the age table (`4 d T-424 downstream of T-340's
ruling — trigger EXISTS, unrecorded`) is wrong for the same reason.

### 5. CORRECTION to §0 and §2 — I double-counted the population

T-155 is in BOTH buckets: it is the one formal DEFER *and* it carries `horizon: later`.
The union is **20 distinct tasks, not 21**. §2's "understates it 21×" is therefore **20×**,
and "zero of 21" is **zero of 20**. Same double-count shape as the rest of this class —
two views of one register, summed as if disjoint, without checking the overlap.

### 6. Per-item verdicts — all 20

Verdict per AC-4. A fourth bucket was required and its existence is itself a finding:
four items cannot be settled by static evidence at all, because the deferred claim is a
RUNTIME property (a render, a click) or its subject is not in this tree.

    STALE (justification no longer holds) — 2

    T-443  Rename fixtures/aef-bpmn        TRIGGER ALREADY FIRED, 2 days unnoticed.
           AEF ruled "keep the path" at DM 549 §5 on 2026-08-12; corroborated
           independently by episodic T-446 ("AEF ruled keep-the-path on T-365").
           The task's own TITLE still reads "PENDING AEF ruling". It is parked on
           operator ratification now, not on AEF.
    T-155  Tree grouping for Open-project  Label wrong, not stale content. Rationale
           reads "pending operator input on IW-1/IW-2" — blocked on a question, not a
           decision to wait — and states a full positive recommendation (A1+B1+C1).
           Should read GO-awaiting-ratification. Parked 16 days.

    PARTLY DISSOLVED — 1

    T-246  Changelog + structured capabilities. The capabilities HALF shipped under
           T-258: dist/MANIFEST.yaml carries `capabilities: annotation_seam: 1` under
           the comment `# T-258/T-246`, released 0.9.0 on 2026-08-08. The changelog
           half is still absent (no CHANGELOG in dist/, docs/ or root). The park never
           noticed half its deliverable arrived. Re-scope to changelog-only.

    STILL VALID (subject confirmed to exist, evidence unchanged) — 13

    T-424  retire aef:position          [CORRECTED — see §8. The trigger I named for
                                        this one was WRONG, and I acted on it before
                                        checking.]
    T-184/185/186  arc children 3/4/5   owner human, 34 d, oldest in the register.
    T-277  conformance key ratification blocked on AEF's T-2652 landing. NOTE: T-443
                                        proves rulings arrive without our parks
                                        noticing, so this one needs an explicit rail
                                        check, not passive waiting.
    T-279/280/281/282  revive-or-retire inceptions, owner human, no evidence moved.
    T-289  mapping-v1 vocab alignment   cannot be resolved by editing the standard —
                                        Part I is frozen under agent control.
    T-291/292  ghost workflows          subject CONFIRMED PRESENT: both 'review-map'
                                        and 'future-map' are still live rows in
                                        .context/designer/registry.yaml. Not dissolved.
    T-355  foreign-tag nodes unmarked   symptom CONFIRMED PRESENT: `foreignTag` occurs
                                        in src/aef-workflow-designer.html only on the
                                        parse/emit paths (:9629, :9631, :9872, :9891);
                                        no occurrence on any render/class path.

    UNVERIFIABLE BY STATIC EVIDENCE — 4  (this bucket is the finding, not a gap)

    T-233  ghost cards visually distinct   render property. The ghost modal exists
                                           (:8943) but "visually distinct" is not a
                                           grep result — CLAUDE.md's own rule: DOM
                                           math is not rendered output.
    T-294  port-indicator pin click        interaction property. .port-indicator
                                           exists (:675, :3729); whether mousedown
                                           bubbles needs a real click.
    T-301  Versions panel empty            runtime property.
    T-241  api/thumb fallback              SUBJECT NOT IN THIS TREE. `api/thumb`
                                           appears in no source file here — only in
                                           .context prose. The gallery server is
                                           elsewhere. Verdict withheld pending
                                           locating it; may be DISSOLVED-HERE.

**Method note against myself (ninth this week).** My first probe for these searched
`web/` and `lib/` — neither directory exists in this repo. It returned nothing, which
reads exactly like "not implemented". Caught by checking the search population before
the finding, not after.

### 8. CORRECTION — T-424's trigger had not fired, and I promoted it before reading it

Sections 4 and 6 both called T-424 *"the one defer whose re-entry condition is genuinely
known — T-340's ruling"* and *"the cheapest correction on the board"*. When the operator
recorded PD-200 I promoted it `later` → `now` on that basis, told them the trigger had
fired, and only then opened the task.

**T-424's own description names three preconditions and T-340's ruling is none of them:**

1. a **T-225 scope ruling** on whether the never-silently-migrated principle covers
   *presentational* content — T-225's four invocation sites in src are all semantic, so
   the principle's reach over presentation is stated and never tested;
2. a **v1.1 revision of the FROZEN two-party standard** `docs/standards/aef-bpmn-mapping-v1.md`,
   which names `aef:position` — so this is AEF's decision as much as ours;
3. **spike 3's unresolved intent gap** — DI has no vocabulary for `forceStraight`,
   `routingHint`, `loopDetour`, and `anchors`/`aef:waypoint` are still unclassified.

Plus the ordering constraint: step 3 lands after step 2, and step 2 is itself now parked
on a rail question.

Reverted to `horizon: later`, with `revisit_evidence_needed` recording the real
preconditions so the next reader does not have to re-derive them.

**How the error was made, because it is the week's class turned on myself.** T-424 sits
adjacent to T-340 in T-357's decomposition, so I read *adjacency in a sequence* as
*dependency on the previous step*. That is mention-vs-instance one more time: "T-340 is
named near T-424" is not "T-424 waits on T-340". The whole point of this task was that
a park's justification must be READ rather than inferred, and the one park I singled out
as exemplary is the one whose justification I never opened. It was also the cheapest
possible check — the answer was in the `description:` field.

### 7. What I did NOT do

No defer was flipped. Re-evaluation produces a recommendation; converting a DEFER to
GO/NO-GO is an operator ruling, and T-155's case is precisely one where the agent
already has a position — which is the situation where flipping it myself would be
worst.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The DEFER population is enumerated STRUCTURALLY, not by grepping the word —
      a word-search already produced a false positive (T-121's `n_end_defer` is a
      node name). Population derived from: `## Decision` blocks recording defer,
      `horizon: later`, and `revisit_at` fields
- [x] The denominator is stated, and the search's own blind spots named — a defer
      recorded only in prose is invisible to a structural scan (PL-145) and that
      must be said, not implied absent
- [x] Each defer is re-evaluated against the question that actually matters: has the
      evidence that justified deferring CHANGED? Not "is it still deferred"
- [ ] Every defer gets one of: STILL VALID (with what would change it), STALE (the
      justification no longer holds), or DISSOLVED (the thing deferred no longer exists)
- [x] Defers with no revisit date are named individually — a defer with no trigger is
      indistinguishable from an abandonment, which is the exclusion-vs-hole distinction
      applied to time
- [x] No defer is flipped under agent initiative. Re-evaluation produces a
      recommendation; changing a DEFER to GO/NO-GO is an operator ruling

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

### 2026-08-14T12:11:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-500-critically-re-evaluate-every-defer-asses.md
- **Context:** Initial task creation
