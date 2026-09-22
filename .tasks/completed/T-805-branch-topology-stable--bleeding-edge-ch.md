---
id: T-805
name: "Branch topology: stable + bleeding-edge, checked against AEF"
description: >
  Branch topology: stable + bleeding-edge, checked against AEF

status: work-completed
workflow_type: design
owner: agent
horizon: null
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T10:37:44Z
last_update: 2026-09-22T12:17:30Z
date_finished: 2026-09-22T12:17:30Z
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

# T-805: Branch topology: stable + bleeding-edge, checked against AEF

## Context

The operator instructed a two-branch model (development on bleeding-edge, merge-squashed into a
stable branch) and instructed us to check it with AEF first. Measured before asking: this project
had NO split at all — `master` only, local and remote, `origin/HEAD -> master`, 2381 commits, 187
in 7 days, 89 in 24 hours, last tag 139 commits behind HEAD, and no recorded branch decision
anywhere. AEF answered at `agent-chat-arc @1656` and **contradicted the merge-squash half**: under
their release train `master` is the consumer install surface advanced only by fast-forward, and a
squash diverges it permanently, disabling `fw release tag-and-release` (T-3190) and two `fw doctor`
rails (T-3187). The operator was shown the cost and chose AEF's model as-is.

Model written down in `docs/branch-model.md`.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `bleeding-edge` exists locally and on `origin`, cut from `master` at `1b89e29e`
- [x] `master` is not ahead of `bleeding-edge` (the fast-forward invariant holds by construction)
- [x] `origin/HEAD` still resolves to `origin/master` — the consumer surface is unchanged
- [x] No `stable` branch exists, per AEF @1656 "never a third branch"
- [x] The model is documented in `docs/branch-model.md`, citing AEF's offsets and the squash cost
- [x] The vendored tree's contradictory integrate-onto-master nudge is recorded as a known defect (AEF OBS-467)


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-805 legs. Each line's own exit code is the verdict (no chaining; see errexit warning). ---
git show-ref --verify --quiet refs/heads/bleeding-edge
git show-ref --verify --quiet refs/remotes/origin/bleeding-edge
test "$(git rev-list --count refs/heads/bleeding-edge..refs/heads/master)" = "0"
test "$(git symbolic-ref refs/remotes/origin/HEAD)" = "refs/remotes/origin/master"
test -z "$(git branch --list stable)"
test -z "$(git branch -r --list origin/stable)"
grep -q "never a third branch" docs/branch-model.md
grep -q "OBS-467" docs/branch-model.md
# CONTROL for the two greps above: the file must exist, so a FILE-NOT-FOUND (grep exit 2)
# cannot pass as a satisfied assertion. T-804 hit exactly this in its own control leg.
test -s docs/branch-model.md
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

### 2026-09-22 — Fast-forward release train, not merge-squash

- **Chose:** AEF's model verbatim. `master` = consumer install surface, advanced ONLY by
  fast-forward from `bleeding-edge`, ONLY at a release. `bleeding-edge` = development and
  master's only writer. "Stable" is a tag series on master, not a branch.
- **Why:** AEF @1656, asked directly. Because bleeding-edge is master's only writer, a clean
  fast-forward exists by construction. A squash puts a commit on master that is not on
  bleeding-edge, so master becomes ahead-and-behind — diverged — and `fw release tag-and-release`
  refuses a diverged master permanently (T-3190), while `fw doctor`'s diverged-fork and
  wrong-branch rails (T-3187) fire forever. Verified with AEF that `fw upgrade`/`fw vendor`,
  `fabric blast-radius` and the `## Updates` git mining do NOT depend on reachability — so the
  cost of squashing is precisely their release command plus two doctor rails.
- **Rejected — merge-squash (the operator's original instruction):** the operator was shown the
  cost above and chose the fast-forward model instead. AEF on the trade: "we would not."
- **Rejected — a third branch named `stable`:** AEF @1656, "never a third branch." Taking the
  operator's words literally would also have inverted the convention — anything reading
  `origin/HEAD` would take our master as vetted when it runs at 89 commits/day.
- **Not done, and not delegated:** the first fast-forward of `master`. Integration and merging
  are the operator's to run or to explicitly delegate.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-805 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T10:37:44Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-805-branch-topology-stable--bleeding-edge-ch.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-ec6fb76f
- **Timestamp:** 2026-09-22T12:17:30Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T12:17:30Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
