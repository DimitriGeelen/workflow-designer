---
id: T-637
name: "What actually blocks each outstanding inception ruling, measured per task"
description: >
  What actually blocks each outstanding inception ruling, measured per task

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
created: 2026-08-29T22:59:46Z
last_update: 2026-08-29T23:08:57Z
date_finished: 2026-08-29T23:08:57Z
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

# T-637: What actually blocks each outstanding inception ruling, measured per task

## Context

The operator's read: "a number of diverse inceptions outstanding — maybe we have not
finished it." Every handover for weeks has quoted the same eight (T-184, T-185, T-186,
T-277, T-279, T-280, T-281, T-282) and the same route ("rule them on the Watchtower
page"). That set has been repeated, not re-measured, and repeating a number is not
knowing it.

The standing rule this task exists to apply: ENUMERATE WHAT IS AGENT-CLOSABLE BEFORE
CLAIMING EVERYTHING IS OPERATOR-GATED. "Awaiting a ruling" has been the blanket label on
this population. It is certainly true of some of them. Whether it is true of ALL of them
has never been checked one by one, and there are at least three ways it could be false:
the question may already have been answered by code that shipped since (T-617 found
exactly that — "most of the proposal is already built"); the blocker may be missing
evidence an agent can go and measure; or the inception may be stale enough that the
question no longer exists.

A queue nobody drains is not progress. This task does not rule anything — recording a
decision on the operator's behalf is forbidden and `fw inception decide` refuses under an
agent session by design. It produces the thing that makes ruling cheap: a measured,
per-inception statement of what specifically stands between each one and a decision, with
everything on the agent's side of that line already closed.

## Acceptance Criteria

### Agent
- [x] Every inception task in the tree is enumerated with its MEASURED decision state —
      not the eight carried forward in handovers. Count reconciled against
      `fw inception status` so the census and the framework's own view agree
      — 41 inception tasks, 14 active, **10 undecided**. Two independent methods (YAML
      frontmatter parse; the scan's own line logic) agree on the same 10
- [x] For each undecided inception the specific blocker is named and classified:
      OPERATOR-ONLY / AGENT-CLOSABLE / STALE — table in the report, one row each
- [x] Every blocker classified AGENT-CLOSABLE is closed in this task or filed as its own
      task carrying the evidence needed — none left as a note in a report
      — T-498's own precondition ("DEFER until the arc set here is enumerated") closed by
      measurement: exactly one arc here, no onboarding arcs. T-619's "blocked on AEF"
      tested rather than repeated: zero mentions of the retry vocabulary from AEF across
      all 107 rail posts since the question. All eight deferral triggers tested: none
      fired
- [x] The STALE classification is verified against the artifact, not the task text
      — `callActivity` DOES appear in the designer source, once, inside a comment. The
      node type is not built. Nothing in the set is stale, and the grep hit alone would
      have made "already shipped" an easy false claim
- [x] `docs/reports/T-307-inception-decision-briefs.md` is reconciled with the current
      set rather than assumed current — covers 8 of 10; both gaps postdate it, named
- [x] The operator route is ONE copy-pasteable single-line command per inception, and the
      /approvals link is printed
- [x] Nothing records a decision on the operator's behalf and `fw inception decide` is
      never invoked; a prober asserts the report contains no `**Decision**:` line
      — and a second leg asserts it offers no pre-filled `decide --rationale` either,
      because drafting the ruling is the same act one step removed

Added during the work, because widening the scan exposed a latent defect:
- [x] `tools/_t627-undecided-defer.py` selected the population on "carries a revisit
      date" while its name and output are about "was never ruled on". Two live tasks sat
      in that difference and had never reached a handover. Fixed; both now surface
- [x] Widening it turned a latent false positive live: the selector was a whole-file
      substring test, and two tasks whose BODY mentions `workflow_type: inception` (a
      table cell, a sentence) were reported as unruled inceptions. Their real types are
      `test` and `build`. Now anchored to the frontmatter block, with teeth for both
      directions

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

bash tools/_t637-inception-coverage.sh

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

### 2026-08-29T22:59:46Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-637-what-actually-blocks-each-outstanding-in.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a285e50c
- **Timestamp:** 2026-08-29T23:08:59Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Per-AC findings:**

- **AC#8 (Agent)** — `tools/_t627-undecided-defer.py` selected the population on "carries a revisit
  - **AC-verify-mismatch** (narrow, heuristic) — `path=tools/_t627-undecided-defer.py in: `tools/_t627-undecided-defer.py` selected the population on "carries a revisit`

### 2026-08-29T23:08:57Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
