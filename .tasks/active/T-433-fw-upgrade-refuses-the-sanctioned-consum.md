---
id: T-433
name: "The vendor bump is available and its version relation is formally undecidable — an operator decision, measured"
description: >
  AEF named fw upgrade against the public GitHub mirror as the sanctioned consumer pull point (DM 536 section 1). This task exists to put a MEASURED blast radius in front of the operator, because the bump is their call and mine to describe accurately. NOTE - THIS TASK WAS FILED ON A PREDICTION THAT DRIVING IT FALSIFIED, and the wrong prediction is kept in the RCA rather than deleted, because it is the second time in one session that reading a code path beat running it and then lost. Predicted: the T-1912 precheck at lib/upgrade.sh:849 compares with sort -V, this tree says 1.6.354, upstream says 1.6.9, sort -V puts 1.6.354 last, therefore the upgrade refuses as a downgrade. Every one of those facts is true and the conclusion is false. Running the upstream fw in --dry-run from inside the clone shows a newer guard, T-2713, which recognises that AEF's VERSION is a RESETTING COUNTER and that string order therefore cannot decide direction at all - it reports 'direction undecidable', warns, and PROCEEDS by default (FW_UNDECIDABLE_VERSION_PROCEED=0 to refuse). So the upgrade is available, not blocked. What is true and unchanged: no version_sha is recorded and no tag v1.6.354 exists in the framework repo, so nothing verifies this bump moves forward rather than backward; this tree's 1.6.354 label was written by ebf0c721, whose own commit message says it vendored v1.6.763; and the upstream tree labelled 1.6.9 contains T-2919/T-2923/T-2924, work from this week. Blast radius measured against a read-only clone: 285 files differ, 502 exist only upstream, 14 only here, and the vendor step would replace bin, lib, agents, web, docs, policy, templates and status-transitions.yaml wholesale (~29MB). Unblocks the T-402 close path once the bytes land.

status: captured
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
created: 2026-08-11T20:13:47Z
last_update: 2026-08-11T20:13:47Z
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

# T-433: The vendor bump is available and its version relation is formally undecidable — an operator decision, measured

## Context

The T-402 fix (`f1b1023f0`) and its follow-up (`31d72fb01`) are upstream and not here.
AEF named the pull point at DM 536 §1 and was explicit that **the bump is the operator's
call, not theirs and not mine** — a vendor bump changes governance behaviour in this tree,
which is the fork boundary both projects withdrew work over.

So this task does not upgrade anything. It measures what an upgrade would do, so the
decision is made against evidence instead of a version string nobody can interpret.

## Acceptance Criteria

### Agent
- [x] **The upgrade's behaviour is DRIVEN, not read off the code path.** A prediction
      derived from reading `lib/upgrade.sh` is not evidence; the T-402 lesson is that the
      instrument must run the thing it describes.
      **DONE** — `fw upgrade --dry-run` from inside a read-only clone. It falsified the
      prediction this task was filed on. See `## RCA`.
- [x] **The blast radius is counted, not characterised.** "Large" is not a number the
      operator can weigh.
      **DONE** — 285 files differ, 502 upstream-only, 14 here-only; the vendor step
      replaces `bin lib agents web docs policy .tasks/templates metrics.sh
      status-transitions.yaml` wholesale (~29MB), excluding `.git .context
      .tasks/{active,completed} .fabric install.sh`.
- [x] **AEF's three factual claims are verified against the upstream bytes**, not accepted
      on assertion, since the mirror is readable from here and checking is cheap.
      **DONE** — `lib/cmd_classify.py` exists with `strip_heredocs` (T-2919 + T-2923);
      `is_valid_owner` is called at `create-task.sh:203` **and** `update-task.sh:1705`
      (their T-2924). All three hold.
- [x] **My own "zero call sites" finding is re-checked against the correction**, and the
      verdict stated for THIS tree rather than in general.
      **DONE** — zero is correct here: neither `create-task.sh` nor `update-task.sh` in
      this vendored copy references `is_valid_owner`. The disagreement was never about
      the measurement; it was that a vendored copy shows the predicate and not its
      callers, and this copy predates both call sites.
- [ ] **No upgrade is executed under agent initiative** — not `fw upgrade`, not
      `--force-downgrade`, not `FW_UNDECIDABLE_VERSION_PROCEED`. Dry-run and read-only
      clone only. This AC is satisfied by the absence of the action and is checked at
      completion, not before.

### Human
- [ ] [REVIEW] Whether to take the vendor bump now
      **Steps:**
      1. Read `## Findings` — blast radius, what arrives, and what the version labels
         actually mean
      2. Note that the version relation is **undecidable by design**: AEF's `VERSION` is a
         resetting counter, no `version_sha` is recorded, and no tag `v1.6.354` exists
         upstream. Nothing verifies this moves forward rather than backward. The upgrade
         records a `version_sha`, so the *next* comparison becomes decidable — this is the
         one bump that cannot be checked
      3. Decide: (a) take it now — unblocks T-402 and lands T-2919/T-2923/T-2924;
         (b) defer until AEF tags a release this tree can name; (c) take it in a branch
         and diff the governance surface before merging
      **Command if (a):** `cd /opt/832-Workflow-designer && .agentic-framework/bin/fw upgrade`
      **Expected:** one of a/b/c recorded here with a one-line reason
      **If not:** T-402 stays open indefinitely — its close condition is bytes that only
      this decision can deliver

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

## Findings

### What the version labels actually mean

    this tree  .agentic-framework/VERSION   1.6.354
    upstream   VERSION                      1.6.9

Neither describes its tree. This tree's `1.6.354` was written by `ebf0c721`, whose own
commit message says it vendored **v1.6.763** (`VERSION` went `dev` → `1.6.354` in that
commit). The upstream tree labelled `1.6.9` contains T-2919, T-2923 and T-2924 — work
from this week. `sort -V` puts `1.6.354` after `1.6.9`, which is why the naive reading
says "downgrade".

The tool does not make that mistake. **T-2713 recognises that `VERSION` is a resetting
counter and that string order therefore cannot decide direction at all**, so it reports
the relation as *undecidable*, warns, and proceeds. There is no `version_sha` recorded and
no tag `v1.6.354` in the framework repo, so there is no second channel to fall back on.

The consequence for the operator is not "the upgrade is blocked". It is that **this
particular bump is unverifiable in the forward/backward sense, and it is the last one that
will be** — the upgrade records a `version_sha`, so every comparison after it is decidable.

### Blast radius (measured against a read-only clone)

    285   files differ
    502   exist only upstream (arriving)
     14   exist only here
    ~29MB replaced wholesale: bin lib agents web docs policy .tasks/templates
          metrics.sh status-transitions.yaml .secret-scan-*
    excluded: .git .context .tasks/{active,completed} .fabric install.sh

### What arrives that this tree is waiting on

- `lib/cmd_classify.py` — T-2919, the T-402 fix (segment-splitting classifier)
- `strip_heredocs` in the same file — T-2923, the follow-up after the fix stranded
  wrap-up by reading commit-message lines as commands
- `is_valid_owner` enforced on both the create and update paths — T-2924

## RCA

**Symptom:** This task was filed asserting `fw upgrade` would refuse as a downgrade.

**Root cause:** The prediction was assembled from four individually true facts — the guard
at `lib/upgrade.sh:849` exists, it compares with `sort -V`, the two labels are 1.6.354 and
1.6.9, and `sort -V` puts 1.6.354 last — and the conclusion drawn from them was false,
because a *newer* guard (T-2713) intercepts the comparison before the one I read. I found
the guard that matched my hypothesis and stopped looking.

**Why structurally allowed:** Nothing distinguishes "I read the code path" from "I ran the
thing" in a task description. Both render as flat assertions, and this one even carried
the words *"Measured, not predicted"* while being neither — the empirical step I actually
performed (`printf | sort -V`) measured the *comparison*, not the *tool*, and I let its
green tick stand in for the tool's behaviour. That is mention-vs-instance again: the third
time this session, and the second time it was mine.

**Prevention:** The first Agent AC now requires the behaviour to be **driven**, and the
falsified prediction stays in this section rather than being edited out. A task history
that silently repairs its own wrong turns teaches nothing to the next reader — and the
next reader is me.

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

### 2026-08-11T20:13:47Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-433-fw-upgrade-refuses-the-sanctioned-consum.md
- **Context:** Initial task creation
