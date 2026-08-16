---
id: T-472
name: "I told AEF an answered question was still open"
description: >
  Rail 582 told AEF that DM 548 s6 (are the three pair-drafts co-authored on your
  side?) is still open and that PROVENANCE.md asserts co-authorship on our evidence
  alone. Both false: AEF answered from records at DM 556 and T-449 (work-completed)
  replaced the one-sided block. Source of the error was T-443's frontmatter description,
  written before DM 556 landed and never re-derived. Correct on the rail, re-measure
  whether T-443's OTHER premise (DM 548 s5, the rename ruling) is also stale, and
  make the staleness detectable rather than trusting the next reader to notice.

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
created: 2026-08-12T20:33:24Z
last_update: '2026-08-16T12:34:01Z'
date_finished: 2026-08-12T20:38:17Z
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
  - ts: '2026-08-16T12:34:01Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 2
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=2 
      (body:lightly-promoted); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 
      (no-signal); F2=0 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-472: I told AEF an answered question was still open

## Context

Rail correction at **offset 583**. Inventory correction in
`docs/reports/T-471-seam-repin-trigger-inventory.md` §5.

At rail 582 I told AEF two things, both false, both about questions they had answered:

| claim at 582 | reality | answered at |
|---|---|---|
| "DM 548 §6 still open — PROVENANCE.md asserts co-authorship on our evidence alone" | answered from their records; T-449 replaced the one-sided block and is `work-completed` | **DM 556** |
| "T-443 is a pending path-identity trigger, blocked on AEF's DM 548 §5" | **they ruled: keep the path.** Not pending, not blocked, nothing owed by them | **DM 549 §5** |

**I acknowledged the §5 ruling at the time.** At offset 550 I replied "keep the path —
agreed" and wrote that T-443 now records the ruling *in its own Context so nobody
re-derives it off the rail*. It does — in bold, as the first line of the body. I then
re-derived it off a stale field 32 rails later.

### The mechanism, which is narrower than "summaries decay"

T-443's frontmatter `description:` read `TRIGGER: AEF answers DM 548 section 5`. True when
written, never re-derived. Its `## Context`, four lines below, opens
`AEF HAS RULED: KEEP THE PATH (DM 549 §5)`. **The correct fact was in the same file,
immediately underneath the wrong one, and I read the wrong one.**

That is the difference from T-466 and T-209: there, a claim decayed and nothing contradicted
it. Here the contradiction was already written and adjacent. **A task's summary FIELD
outlives the body's corrections, because correcting the body is where the work feels
finished** — and the field is what every listing, handover and task view renders. Frontmatter
is a cache with no invalidation.

Third instance of the class in one session (T-466 five-blockers → one; T-209 option C,
discharged five hours after being recommended and restated as live for 24 days; this).
Registered as **PL-171** rather than filed as a fresh one-off, so the recurrence is visible.

### Prevention, not just mitigation (G-019)

Annotating T-443 fixes one file and leaves the trap set everywhere else, so
`tools/_t472-stale-trigger-field.py` sweeps all active tasks for the shape: a
pending-flavoured `description:` over a body that records the trigger as fired. It reports,
never gates; false positives are the expected cost of catching the one that costs a rail
message.

**Its first form scored 0 real findings out of 4 flags**, and each miss was instructive
rather than random:

| flagged | matched on | why it is noise |
|---|---|---|
| T-184, T-185, T-186 | `disposition: answered \| deferred \| dissolved` | template boilerplate inside an HTML comment — present in every task |
| T-184, T-185, T-186 | `**Expected:** Decision recorded, task completed` | a Human AC's Expected clause: a statement about the *future* |
| T-228 | "completing the note dialog **fired** the claim" | homonym — a UI claim firing, not a trigger |

Tightened by stripping HTML comments and requiring the past-tense ruling sense; the four
drop out and T-443 is correctly suppressed as already-marked. The first form of any
instrument is a draft, which this session keeps re-learning — this time on an instrument
built to catch exactly that.

**T-472 flags itself** (its description says "still open", its body says "was answered").
Left as-is: it is a true positive on shape, and it self-resolves — the scanner reads
`.tasks/active/`, and this task leaves on completion.

### Not done here

T-443's disposition, by its own stated rule — *"if the path stays, close this with that as
the reason"* — is **close**. It is `owner: human`; the evidence is cited for the operator
and the task is left exactly where it is.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The false claim is established from the record, not from memory.** DM 556 (AEF's
      records answer) and T-449's completed state are both cited, showing §6 was answered
      and that `PROVENANCE.md` no longer carries the one-sided block I told AEF it carries.
- [x] **T-443's OTHER premise is re-measured on the same rail, not assumed live.** Its
      stated trigger is "AEF answers DM 548 §5" (the rename ruling). The same staleness
      that killed §6 may have killed §5. Answered by reading the rail, with the offset
      cited either way — if §5 is also answered, T-443 is unblocked and mis-filed as
      waiting on a peer.
- [x] **The rail correction is posted before anything else is built.** Telling a
      cooperating peer that their answer is missing when they gave it is the error with
      the shortest useful half-life; PL-040 satisfied (latest inbound read first — no new
      inbound since 582).
- [x] **The carrier is fixed, not just the claim.** The error came from a frontmatter
      `description:` that was true when written and never re-derived. Correcting only the
      rail post leaves the same trap set for the next reader of T-443. The stale premise is
      annotated in T-443 itself, dated, with the superseding offset.
- [x] **The class is recorded as recurrence, not as a fresh mistake.** This is the third
      instance in one session of a claim restated from a record whose basis had dissolved
      (T-466 five-blockers, T-209 option C, this). It is registered against the existing
      learning rather than filed as a new one-off, so the count is visible.
- [x] **No ruling is made and no blocked task is started.** T-443 stays `captured`/`later`
      whatever the §5 measurement shows; if it is unblocked, that is reported to the
      operator, not acted on.

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

# Rail correction posted at offset 583 (retracting two claims from 582).
#
# Leg 3 is the regression leg for the detector's FIRST form, which scored 0/4: it matched
# template boilerplate inside HTML comments (`disposition: answered | deferred |
# dissolved`), a Human AC's forward-looking `**Expected:** Decision recorded`, and the
# homonym "completing the note dialog fired the claim". Without this leg, a future
# loosening of RESOLVED silently restores the noise that made the tool useless.
# Leg 2 is its positive control (PL-084): a pattern tightened until it matches nothing
# would pass leg 3 trivially.

python3 tools/_t472-stale-trigger-field.py
out=$(python3 tools/_t472-stale-trigger-field.py 2>&1); echo "$out" | grep -q 'T-443'
out=$(python3 tools/_t472-stale-trigger-field.py 2>&1); ! echo "$out" | grep -qE 'T-18[456]|T-228'
/usr/bin/grep -q 'STALE-FIELD MARKER 2026-08-12 (T-472)' .tasks/active/T-443-rename-fixturesaef-bpmn-as-a-v12-standar.md
/usr/bin/grep -q 'AEF HAS RULED: KEEP THE PATH' .tasks/active/T-443-rename-fixturesaef-bpmn-as-a-v12-standar.md
/usr/bin/grep -q '^## 5. Correction 2026-08-12 (T-472)' docs/reports/T-471-seam-repin-trigger-inventory.md
/usr/bin/grep -q '^status: work-completed' .tasks/active/T-449-provenance-pair-draft-rows-are-two-sided.md
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

### 2026-08-12T20:33:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-472-i-told-aef-an-answered-question-was-stil.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-c4f4898f
- **Timestamp:** 2026-08-12T20:38:18Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 13
     - evidence: `out=$(python3 tools/_t472-stale-trigger-field.py 2>&1); ! echo "$out" | grep -qE 'T-18[456]|T-228'`

### 2026-08-12T20:38:17Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
