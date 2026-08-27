---
id: T-609
name: "Review cards drop Steps/Expected/If-not, so the operator sees the AC title and not the decision it asks for"
description: >
  Review cards drop Steps/Expected/If-not, so the operator sees the AC title and not the decision it asks for

status: work-completed
workflow_type: build
owner: human
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-08-27T07:01:04Z
last_update: 2026-08-27T19:39:24Z
date_finished: 2026-08-27T19:39:24Z
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

# T-609: Review cards drop Steps/Expected/If-not, so the operator sees the AC title and not the decision it asks for

## Context

Opened as a render defect and closed as a misdiagnosis. Worth keeping the trail.

Rail 588 (010-termlink) warned that an approval card can pass its own checker and still
show the operator an empty page, and that HTTP 200 does not discriminate — "verify against
RENDERED BYTES, never the checker". I applied that to our own cards because I had spent
three sessions printing `/review/T-597` links at the operator and getting no ruling.

The measurement was worse than expected: "Steps", "Expected" and "If not" appeared **0**
times on every card, including T-597, whose (a)/(b)/(c) options live inside `Expected`.
The decision I kept asking for was not on the page.

The cause was not the renderer. `_review_acs.html` renders those fields, and the parser
populates them; the guard `{% if not ac.checked ... %}` was hiding them because the ACs
read `- [x]` on disk — three `[REVIEW]` criteria, ticked without the operator, while
`fw task update` for the same file reported "Human: 0/1 checked".

Two lessons, both already in the register and both re-earned here. First: the framework's
own instruments disagreed, and the sovereignty-bearing reader was the wrong one — the same
two-definitions shape as T-1575/T-606. Second: my first four causal hypotheses were all
wrong (web POST, structural audit, hourly audit, bvp), and each was excluded by reverting
and re-running rather than by reasoning. A blocker assumed is not a blocker verified
(rail 587).

## Acceptance Criteria

**The premise this task opened with was wrong, and the ACs below record what was actually
established.** The original ACs claimed a renderer defect ("review cards drop
Steps/Expected/If-not"). The renderer is correct. The cards were blank because the Human
ACs had been ticked, and `_review_acs.html` deliberately suppresses the steps of a
decision it believes is already made. Rewriting the criteria to match the corrected
diagnosis rather than to match the fix I expected to write.

### Agent
- [x] Measured against RENDERED BYTES over HTTP, not the parser and not an HTTP 200:
      `/review/T-597` and `/review/T-608` returned 200 with ~23-25KB and a verdict, while
      "Steps", "Expected" and "If not" each appeared **0** times — a usable and an unusable
      card are indistinguishable by status code (rail 588)
- [x] Cause discriminated rather than assumed: the parser was probed directly and returns
      `steps`/`expected`/`if_not` fully populated, so the data was never lost — the
      template guard `{% if not ac.checked and (...) %}` was suppressing it, and
      `checked=True` was the actual finding
- [x] Established that the checkbox state on disk was `- [x]` on three Human ACs across
      T-597 and T-608 while `fw task update` itself reported "Human: 0/1 checked" — two
      readers, two answers, and the sovereignty-bearing one was wrong
- [x] Established the tick was NOT the operator acting through the review UI: exactly one
      POST exists in the whole Watchtower log (an inception decide, 26 Aug 10:55), none at
      the 00:29 mtime
- [x] Candidates ruled out by reproduction, each reverted-then-rerun: the 30-minute
      structural audit, the hourly `oe-hourly` audit, and `fw bvp --include-proposed`
      (which the help warns persists proposed scores into task files). None re-ticked.
- [x] Scope of the event bounded: only T-597 and T-608 were affected — not a sweep, and
      both are the tasks cross-referenced by T-608's recommendation
- [x] True state restored: the ticks existed only in the working tree, so reverting them
      restored the committed state exactly; the ticked copies are preserved in the session
      scratchpad so nothing is destroyed if the operator says the ticks were theirs
- [x] Re-measured after the revert: `/review/T-597` now renders Steps/Expected/If-not for
      both ACs, including "authorise a scoped send" and "hold, and accept" — the exact
      (a)/(b)/(c) options that were invisible for three sessions
- [x] Attribution **bounded and escalated, not parked**. Two more candidates excluded this
      session: (a) the "background session started 9h ago" hypothesis has no artifact behind
      it — only two transcripts exist for this project on this machine, this one and one from
      08-14; (b) this session's own Agent-AC tick script, which looked like the culprit and is
      not. Its full command was recovered from the transcript:
      `head,sep,tail=s.partition('### Human'); head=head.replace('- [ ] ','- [x] ')` — the
      boundary is correct, it writes only before the `### Human` header, and T-597's two
      `[REVIEW]` ACs sit at lines 93 and 111, after the needle at 91. Hypothesis formed,
      tested against the real bytes, **disproved**.
      Five candidates are now excluded and the writer is still unnamed. That question is
      about the integrity of task-file writes, not about how review cards render, so it moves
      to **T-622** under its own ID rather than holding this task open indefinitely
      (one bug = one task). Nothing is dropped: T-622 carries the full exclusion list and the
      preserved ticked copies.

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

- [ ] [REVIEW] Did you tick these three Human ACs? This is the one fact the agent cannot establish

  **Steps:**
  1. The agent found `- [x]` on three `[REVIEW]` acceptance criteria — two on T-597
     (ratify the clause definitions; authorise contact with AEF) and one on T-608
     (approve the draft) — and reverted them to `- [ ]`.
  2. The ticks were never committed, so the revert restored the committed state exactly.
     The ticked copies are kept in this session's scratchpad; nothing was destroyed.
  3. Answer one question: **did you tick them?**

  **Expected:** Either "no, I did not" — in which case something ticked the operator's
  decisions unattended, the revert was right, and the remaining work is to name the
  writer. Or "yes, I did" — in which case the revert erased three real decisions, please
  re-tick them and the agent will treat T-597's clause definitions as ratified and its
  option-(a)/(b)/(c) question as answered.

  **If not:** If you are not sure, leave them unticked. Unticked is the safe state: it
  asserts no decision was made, whereas a stray tick tells every downstream gate that the
  EWCR question is settled when it may not be.


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

## Recommendation

**Recommendation:** KEEP-OPEN — the state is restored and safe, but the writer is unnamed.

**Rationale:** The operator-facing symptom is fixed: `/review/T-597` again shows both
decisions with their (a)/(b)/(c) options, which had been invisible for three sessions. But
the fix was a revert, not a repair — nothing prevents a recurrence, and mitigation is not
prevention (G-019). A tick on a `[REVIEW]` acceptance criterion is a sovereignty-bearing
write: it tells every gate downstream that the human has ruled. Something performed three
of them unattended and four candidates have been excluded without finding it. Closing this
task on "the page renders again" would be exactly the false-green move the register
forbids elsewhere.

**Evidence:**
- `/review/T-597`: "Steps"/"Expected"/"If not" 0 -> 2 each; "authorise a scoped send" 0 -> 1
- `/review/T-608`: same fields 0 -> 1 each
- Parser probe: `steps`/`expected`/`if_not` populated all along; `checked` was the defect
- `fw task update` reported "Human: 0/1 checked" while the file on disk read `- [x]`
- Watchtower log: 1 POST total, 26 Aug 10:55, an inception decide — none at the 00:29 mtime
- Reverted-then-rerun, no re-tick: structural audit (exit 2), oe-hourly audit (exit 0),
  `fw bvp --quadrant hv-lc --include-proposed` (exit 0)
- Blast radius bounded to T-597 and T-608; no other task file carries a working-tree tick

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

### 2026-08-27T07:01:04Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-609-review-cards-drop-stepsexpectedif-not-so.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-2817f3d0
- **Timestamp:** 2026-08-27T19:39:25Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#3 (Human)** — [REVIEW] Did you tick these three Human ACs? This is the one fact the agent cannot establish
  - **human-ac-mechanical-signal** (partial, heuristic) — `matched='name the\n  w' in Expected: Either "no, I did not" — in which case something ticked the operator's   decisions unattended, the revert was right, and the remaining work `

### 2026-08-27T19:39:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
