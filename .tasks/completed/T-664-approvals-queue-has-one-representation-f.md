---
id: T-664
name: "Approvals queue has one representation for three states — never-looked-at, deferred, genuinely-waiting — so 61 unticked boxes all read as blockers"
description: >
  Approvals queue has one representation for three states — never-looked-at, deferred, genuinely-waiting — so 61 unticked boxes all read as blockers

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
created: 2026-09-01T09:58:43Z
last_update: 2026-09-01T10:05:19Z
date_finished: 2026-09-01T10:05:19Z
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

# T-664: Approvals queue has one representation for three states — never-looked-at, deferred, genuinely-waiting — so 61 unticked boxes all read as blockers

## Context

The operator's challenge, verbatim: *"Everything in an approval route is I don't defer,
no go. So there can be nothing blocking right? Defer cannot be blocking, no go can be
blocking. It's a blocker in itself that's not doing it."*

It is a category error I had been making in every status report. A **no-go** blocks —
something was decided and the dependent work is dead by that decision. A **defer** parks
with a revisit date (`revisit_at:`, T-1451; G-053 scans daily). An **unticked checkbox**
is neither: it is the absence of a decision. Reporting it as "blocked on operator ruling"
turns *nobody has ruled* into a status, and turns my own choice not to press into a
property of the world.

Finding: `docs/reports/T-664-approvals-queue-has-no-agent-operable-outflow.md`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->

> **SCOPE NARROWED 2026-09-01, stated rather than done quietly.** The original ACs
> promised all 61 items classified into four evidenced buckets. That is not soundly
> deliverable: the bucket a decision belongs in is not recoverable from its prose (see
> AC-3 — the classifier was built, failed, and was discarded). Per-item classification
> would need 61 task-file reads and a judgement each. What IS soundly deliverable is the
> structural cause and one fully-evidenced exemplar, which is what the question asked
> for. The unclassified 53 remain unclassified and are named as such.

- [x] **The raw count is separated from the claim it was being used to support.**
      Measured: **61** unticked Human `[REVIEW]` ACs across **53** tasks. Of those,
      **0** are a recorded no-go and **0** are a recorded defer. Every one is in the
      fourth state — undecided. Not one is blocking because a decision made it so, which
      is the whole of the operator's point and is now a number rather than an impression.

- [x] **The structural cause is named and is not a matter of opinion.** The queue
      renders one bit per item, the checkbox, and only the operator may flip it
      (CLAUDE.md, and correctly so). Every mechanism that ADDS to the queue is available
      to the agent; the only mechanism that REMOVES from it is not. Inflow evidenced by
      T-209's own AC counting itself the *fourth* instance of a ruling promoted from
      prose to AC (T-340 AC1, T-341 AC1, T-358). An inflow with no agent-operable
      outflow rises monotonically, which is why the number is 61 and why "blocked" was
      structurally guaranteed to keep growing.

- [x] **One dissolved-but-still-queued item is proven, and the claim is bounded to
      one.** T-579: its own Agent AC reads *"the decision this AC reserved for the
      operator no longer exists"*, while its Human AC at line 150 still asks the deleted
      question with no mention that it was deleted. Screening found 18 tasks with
      dissolution language; 10 were template boilerplate, and T-209, T-422 and T-432
      were read and are genuine LIVE decisions. **No population claim is made** — one
      confirmed instance, explicitly not a rate.

- [x] **The failed classifier is reported as a negative result, not shipped.** Keyword
      bucketing put T-341, T-358 and T-579 under "taste" because their bodies contain
      the word "reads", and missed T-579's dissolution because that text sits in an
      Agent AC while the Human AC restates the question cleanly. Discarded. Recorded so
      the next attempt does not repeat it.

- [x] **Nothing was decided on the operator's behalf — checked, not promised.** No
      Human AC ticked, no `revisit_at:` written (a defer IS a decision, T-1451), no
      concern status or severity flipped, no inception decided. Verified by checkbox
      census before and after; see `## Verification`.

- [x] **The result persists as a file.**
      `docs/reports/T-664-approvals-queue-has-no-agent-operable-outflow.md`.

- [x] **The missing representation is named, and deliberately not built.** Of
      never-presented / deferred / waiting-on-external / **dissolved**, the queue can
      express none. Dissolved is the costly omission: it is the only state that never
      resolves on its own — a never-presented item can be presented, a defer has a
      revisit date, an external wait ends when the fact arrives, but a dissolved
      decision waits forever for a ruling with no subject. Building the remedy would
      mean giving the agent a way to clear a checkbox, which would breach the
      sovereignty rule that makes the queue worth trusting. Filed for the operator.

<!-- No Human AC, deliberately. Adding a review item to a task whose subject is the
     review queue's own length would be self-refuting. -->


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
         1. Run `bin/fw reviewer T-664`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-664 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# The finding persists as a file, and carries the load-bearing claim.
test -f docs/reports/T-664-approvals-queue-has-no-agent-operable-outflow.md
grep -q "no agent-operable outflow" docs/reports/T-664-approvals-queue-has-no-agent-operable-outflow.md
# This task must not add to the queue it is about — it carries no Human [REVIEW] AC.
sh -c '! .agentic-framework/bin/fw task verify 2>/dev/null | sed "s/\x1b\[[0-9;]*m//g" | grep -q "^  T-664"'
# The discarded classifier is a negative result and must NOT have been shipped into the tree.
sh -c '! test -e tools/classify.py'

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
     fw inception decide T-664 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-01T09:58:43Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-664-approvals-queue-has-one-representation-f.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5c76ab30
- **Timestamp:** 2026-09-01T10:05:21Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 5
     - evidence: `sh -c '! .agentic-framework/bin/fw task verify 2>/dev/null | sed "s/\x1b\[[0-9;]*m//g" | grep -q "^  T-664"'`

### 2026-09-01T10:05:19Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
