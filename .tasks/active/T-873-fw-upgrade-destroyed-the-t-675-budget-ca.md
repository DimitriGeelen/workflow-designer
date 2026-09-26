---
id: T-873
name: "fw upgrade destroyed the T-675 budget-cache guidance and the G-055 warning that saw it go had nowhere durable to land"
description: >
  fw upgrade destroyed the T-675 budget-cache guidance and the G-055 warning that saw it go had nowhere durable to land

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
# demo_target: true               # T-2286: optional — marks task as reserved for an orchestrated demo
#                                 # worker (e.g. arc-010 HM-A dispatches via mcp__fw__work_on). When set,
#                                 # `fw work-on T-XXX` refuses unless --i-am-demo-orchestrator (CLI) or
#                                 # FW_I_AM_DEMO_ORCHESTRATOR=1 (env) is passed. Prevents the parent
#                                 # session from consuming the captured→started-work transition the demo
#                                 # worker expects to drive. Origin OBS-057.
created: 2026-09-26T21:28:54Z
last_update: 2026-09-26T21:28:54Z
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

# T-873: fw upgrade destroyed the T-675 budget-cache guidance and the G-055 warning that saw it go had nowhere durable to land

## Context

A real (non-dry-run) `fw upgrade` ran on 2026-09-25 at 09:32 and rewrote this project's
`CLAUDE.md` from the framework template. `upgrade.sh:1562` backed the old file up to
`CLAUDE.md.bak` first, and `upgrade.sh:1570-1591` (G-055 / PL-124) then did exactly what
it was built to do: it diffed the two and warned that lines had been lost.

**25 lines were lost.** Among them the entire T-675 passage — the one that says
`.budget-status` has two writers emitting a value nobody measured, that it read
`ok / 0` while the session held 117,630 tokens, and that **`unknown` is not `ok`**.
Committed by `4a83d62f` on 2026-09-03; destroyed 22 days later.

The warning fired into a terminal. The session ended. Nobody re-applied. A day later the
degraded file is still uncommitted and is what Claude Code loads as its instructions —
verified live this session: `checkpoint.sh budget` returned `unknown / tokens: 0`, the
exact shape T-675 documents, and the rule for handling it was no longer in CLAUDE.md.

**The defect is not the overwrite** — replacing governance from template is what the verb
is for, and it backed up first and it told the truth. The defect is that the telling had
nowhere to land. `CLAUDE.md.bak` is a durable artefact whose own remedy text says
"remove CLAUDE.md.bak to clear", making its presence a standing unreviewed-regression
signal — and **nothing reads it.** `grep -rn 'CLAUDE.md.bak'` across `agents/audit/` and
`lib/` returns only `upgrade.sh` itself, the writer.

This project also has **zero** `<!-- project-owned: begin -->` regions (T-3150 built the
protection; nothing here uses it), so every governance customisation is destroyed on
every upgrade, silently, by design, forever.

## Acceptance Criteria

### Agent
- [x] Every one of the 25 lost lines is classified re-applied or deliberately dropped, and each drop is named with its reason in `## Decisions` — a blanket `git checkout HEAD -- CLAUDE.md` is NOT the fix (see Decisions: one lost line was false and the template corrected it)
- [x] `CLAUDE.md` again carries the T-675 invariant verbatim — the string "`unknown` is not `ok`" is present
- [x] The env-var name in the restored text matches what the code reads: `budget-gate.sh` resolves `fw_config_int "CONTEXT_WINDOW"` with `FW_CONTEXT_WINDOW` as env override, and the prose says both rather than picking one
- [x] `CLAUDE.md.bak` is removed once reviewed — that removal IS the clear-signal `upgrade.sh` prescribes, and leaving it would leave the new check permanently red (OBS-293)
- [x] `fw audit` carries a check whose predicate is *`CLAUDE.md.bak` exists* — an upgrade rewrote governance and the review was never acknowledged — reporting the lost-line count as context, not as the predicate (see Decisions: gating on the count is permanently red by construction)
- [x] The check names a remedy the reader can actually run to completion (PL-337): review the diff, re-apply, `rm CLAUDE.md.bak`
- [x] That check distinguishes three states and says which: no `.bak` (nothing pending), `.bak` with differing lines (review outstanding, count named), `.bak` byte-identical (review done or no-op, just not cleared)
- [x] A teeth instrument proves the check bites, with a control set that goes red when the harness is broken rather than reading a broken harness as a clean kill
- [x] The framework-general half of the lost text is offered upstream to AEF, so the template stops destroying it on every consumer


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
# ── Mutable-corpus anchor (T-3326) ────────────────────────────────────────────
# Do NOT anchor a verification line (or a unit test it runs) to MUTABLE corpus
# state — an exact live count, or a grep of live `fw audit`/`fw doctor` output
# for a specific corpus entity (a named arc, a task count, a census number).
# The corpus moves under the check, and the line rots: it goes red (or vanishes
# its pattern) for reasons unrelated to the code under test, blocking closes.
# Pin the INVARIANT (categories sum, count > 0, property holds) or run the code
# against a COMMITTED FIXTURE — never the live count or a live-audit line.
# Origin: T-2969 line grepping live audit for one arc's status; T-2871's census
# test pinning exact live counts (56→74 files) — both blocked closes (OBS-377).
#
# ── Pipefail/SIGPIPE: grepping a command's output (L-387, T-2090, T-2743, T-2738) ──
#
# THE DEFAULT — redirect to a file, then grep the file:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
#     curl -sf "$(bin/fw watchtower url)/page" -o /tmp/.out && grep -q "PAT" /tmp/.out
# Correct at any output size, and `&&` keeps the PRODUCING command's exit code in
# the verdict. Reach for this first; the alternative below is the special case.
#
# Why not `cmd | grep -q PAT` (L-387): P-011 runs each line with PIPEFAIL LIVE
# (errexit is not — see below). When grep matches it exits and closes stdin while cmd is still
# writing, cmd takes SIGPIPE, the pipeline exits 141 — verification "fails" with
# the pattern present. Captured 4× (T-1716, T-1838, T-1862, T-1863).
#
# THE EXCEPTION — capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Valid ONLY while "$out" fits the 65536-byte pipe buffer, and it is on you to
# know that it does. Above that the form inverts and becomes the very failure
# L-387 describes: echo blocks on the full pipe, grep -q exits, echo takes
# SIGPIPE, rc=141 (T-2743 — measured on a 146,366-byte Watchtower page, 3/3 runs,
# deterministic not racy; rendered routes run 50-200KB, so anything that curls a
# page is over the line). It also discards cmd's exit code, so a 404 yields an
# empty capture that grep merely fails to match rather than a failed line.
# If you do use it: single pipe only, no intermediate tail/awk/sed stage between
# capture and grep (T-2090) — the middle stage is what `grep -q` slams its stdin
# on, and grep scans the whole captured string anyway, so the `tail -3` was
# cosmetic. `echo "$out" | grep -q PAT`, nothing between.
#
# TEST RUNNERS need a guard either way (T-2738). `set -e` is suppressed inside the
# `if` condition the gate runs each line in, so in `cmd1; cmd2` only cmd2 is the
# verdict — and the pass marker you grep for survives a partial failure: a suite
# printing "3 failed, 9 passed" satisfies `grep -q "9 passed"`, and generalising
# to `grep -qE "[0-9]+ passed"` matches the same output. Keep the exit code:
#     python3 -m pytest <file> -q > /tmp/.out 2>&1 && grep -q passed /tmp/.out
# or add the guard the exit code used to supply:
#     out=$(python3 -m pytest <file> -q 2>&1); echo "$out" | grep -q passed && ! echo "$out" | grep -q failed
#     out=$(bats <file> 2>&1); echo "$out" | grep -q '^ok 1 ' && ! echo "$out" | grep -q '^not ok'
# The close gate refuses the unguarded form. Bypass: FW_ALLOW_UNJUDGED_TEST_RUN=1.
#
# ── A SKIPPED BATS TEST REPORTS `ok` (T-3217) ─────────────────────────────────
#
# `! grep -q "^not ok"` does NOT mean the suite ran. Bats emits a skip as
#     ok 6 <name> # skip <reason>
# which is not a `not ok`, so the gate passes and the report says ok while the
# thing the test covers was measured NOWHERE. Origin: T-3213 guarded a test with
# `[ "$(id -u)" -eq 0 ] && skip` — the suite runs as root here and in CI, so it
# skipped on every run that mattered, for as long as it existed.
#
# Add a skip clause to any bats verification line. `# skip` is the marker bats
# writes; counting it is the whole check:
#     timeout 300 bats <file> > /tmp/.out 2>&1 && ! grep -q "^not ok" /tmp/.out
#     test "$(grep -c '# skip' /tmp/.out)" -eq 0
# Two lines, because they answer different questions — "did anything fail" and
# "did everything run". If some skips are legitimate on your host (an optional
# dependency is genuinely absent), assert the COUNT you expect rather than zero,
# and say in the task why that number is right.
#
# Corpus-wide, the same check runs from `bin/fw test lint`
# (tools/bats-silent-skip-lint.py): static mode flags guards that are fixed for
# a deployment rather than probing an optional dependency, and `--tap FILE`
# reports the skips a real run actually fired.
#
# REHEARSING A LINE BY HAND DOES NOT REHEARSE THE GATE (T-2743). Your interactive
# shell has no pipefail. A line has returned 0 by hand and 141 under P-011, from
# the same directory, the same second. To rehearse for real:
#     bash -c 'set -o pipefail; <your verification line>'
#
# NOTE THE MISSING `-e` — it is not a typo (T-3203). This file used to prescribe
# `set -eo pipefail` here, which is NOT the gate: it adds errexit the gate does
# not have, so it FAILS lines the gate PASSES. Measured, 10 lines, 3 diverged:
#     line                            gate    set -eo (old)   set -o (this)
#     false; true                     PASS    FAIL  wrong     PASS  ok
#     cd /nonexistent; echo ok        PASS    FAIL  wrong     PASS  ok
#     grep -q MISS file; true         PASS    FAIL  wrong     PASS  ok
# The divergence is one-directional and that is the trap: the old rehearsal only
# ever fails lines the gate accepts, so it produces false REDS, and an author
# who "fixes" a line to satisfy it is fixing something that was never broken —
# while the line that actually is broken (`cmd1; cmd2` where cmd1 fails) passes
# both. Re-derive rather than trust this table — it is pinned, not asserted:
#     bats tests/unit/t3203_p011_gate_semantics.bats
#
# ── `cmd1; cmd2` IS JUDGED ONLY ON cmd2 (T-3203) ──────────────────────────────
#
# The gate runs each line as the CONDITION of an `if` (update-task.sh:1215), and
# POSIX suppresses errexit for a compound command in an `if` condition — through
# the subshell. So pipefail applies and `set -e` does not, and in a sequence only
# the LAST command's status reaches the verdict. `cd /nonexistent; echo ok` passes.
# 2,644 of 10,997 verification lines in this corpus contain `;` (re-derive with
# the query in docs/reports/T-3203-p011-gate-semantics.md).
#
# SAFE SHAPES — both verified biting, each against a passing control:
#   A. one command whose own status is the verdict (prefer this):
#        out=$(cmd 2>&1); echo "$out" | grep -q PAT && ! echo "$out" | grep -q BAD
#      the leading assignments are setup; the trailing `&&` chain is the verdict.
#   B. an explicit sub-shell, whose errexit the outer `if` cannot reach into:
#        bash -c 'set -eo pipefail; cmd1; cmd2'
#      use when you genuinely need every command in the sequence to count.
#
# The rule of thumb: put the assertion LAST, and make sure it is an assertion.
#
# Enforcement-baseline hint (L-398, T-1886): if you edited `.claude/settings.json`
# (added/removed/reorganised hooks), add `bin/fw enforcement baseline` to your
# Verification block. Otherwise the canonical hash diverges and `fw doctor`
# reports a FAIL ("Enforcement baseline CHANGED") that accumulates silently.
# Origin: T-1849/T-1730/T-1731 each added a legitimate hook without refreshing
# the baseline — FAIL sat for multiple sessions until T-1886 cleaned up.

# ── T-873 legs ──────────────────────────────────────────────────────────────
# NOTE: no `fw audit` leg here — OBS-332 forbids calling it from P-011. The
# check is exercised through its extracted block instead, which is stricter:
# the teeth lift the real lines out of audit.sh rather than re-running it.
bash -n .agentic-framework/agents/audit/audit.sh
grep -qF 'T-873 claude-bak-signal: begin' .agentic-framework/agents/audit/audit.sh
grep -qF 'T-873 claude-bak-signal: end' .agentic-framework/agents/audit/audit.sh
bash tools/_t873-claude-bak-teeth.sh > /tmp/.t873-teeth 2>&1 && grep -q '0 failed' /tmp/.t873-teeth
bash tools/_t873-claude-bak-teeth.sh --mutation > /tmp/.t873-mut 2>&1 && grep -qE 'controls: [0-9]+/[0-9]+ green' /tmp/.t873-mut && ! grep -qE 'SURVIVED|MUTATION SETUP BROKEN|MUTATION NOT APPLIED' /tmp/.t873-mut
grep -qF '`unknown` is not `ok`' CLAUDE.md
grep -qF 'budget-gate.sh:107' CLAUDE.md
test ! -e CLAUDE.md.bak

## RCA

**Symptom:** `CLAUDE.md` silently lost 25 lines of hard-won governance — including the
T-675 budget-cache passage — and sat degraded and uncommitted for a day while being
loaded as the agent's live instructions.

**Root cause:** `fw upgrade` step [1/10] replaces the whole governance tail from the
framework template. Inline project customisations inside governance sections cannot
survive that by construction. `upgrade.sh` knows this and warns (G-055/PL-124), but the
warning is `echo` to stdout inside a long multi-step run.

**Why structurally allowed:** the warning has no durable reader. `CLAUDE.md.bak` persists
on disk as the evidence, and its own remedy text ("remove CLAUDE.md.bak to clear") makes
its presence a standing signal — but no audit check, doctor check, or hook ever looks at
it. Confirmed: the only reference to `CLAUDE.md.bak` anywhere under `agents/` and `lib/`
is the line in `upgrade.sh` that writes it. A one-shot terminal warning in a session that
then ends is indistinguishable from no warning at all.

**Prevention:** an audit check that reads the artefact the warning leaves behind, so the
signal survives the terminal that carried it. Distinct from the fix (re-applying the
lines): the fix restores this instance, the check catches the next one — and there will
be a next one, because the overwrite is the verb working as designed.

**Not prevention, and named so it is not mistaken for it:** `<!-- project-owned -->`
regions (T-3150) would protect content placed in them, but the lost text belongs *inline*
inside a governance section where it is read. Moving it to a trailing project-owned block
preserves the bytes and loses the placement. The durable answer for framework-general
text is upstreaming it, which is why that is an AC.

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

## Recommendation

<!-- T-2945: same shape as inception.md's block — the gate that reads it
     (audit_inception_recommendation, lib/task-audit.sh:117) is shared, so the
     shape is copied rather than reinvented.

     REQUIRED once this task reaches partial-complete: Agent ACs done, at least
     one `### Human` AC still unticked. `lib/review.sh:205-211` (T-2421) BLOCKS
     `fw task review` emission for build/refactor/test/decommission tasks in that
     state with no substantive block here — the operator would otherwise open
     /review/<id> to a blank Recommendation card and be asked to approve a form.

     Not required while every Human AC is ticked or the task has none: the gate
     only fires on the partial-complete transition. It is here from the start so
     you write it while you still have the evidence, not when the gate refuses.

     Format (the parser wants the `**Recommendation:**` line at the start of a
     line; a leading `-` or `*` bullet is also accepted):
     **Recommendation:** GO / NO-GO / DEFER
     **Rationale:** Why (cite evidence — what shipped, what was proven, what remains)
     **Evidence:**
     - Finding 1
     - Finding 2

     DEFER is for evidence gaps, not confidence gaps (CLAUDE.md §Presenting Work
     for Human Review). If the artefact is complete and you still don't want to
     commit, that is a calibration failure — recommend GO or NO-GO.
-->

## Decisions

### 2026-09-26 — the 25 lost lines, classified

- **Chose:** re-apply 24, deliberately drop 1, merge 2 facts from the template.
- **Why:** measured before restoring. The dropped line is
  `` 1. Check ... following `zzz-default.md` template `` — and `ls .tasks/templates/`
  holds `default.md`, `inception.md`, `path-c-deep-dive.md`. **There is no
  `zzz-default.md`.** HEAD's line was false and the framework template corrected it, so
  restoring it would reintroduce an instruction pointing at a file that does not exist.
- **Rejected:** `git checkout HEAD -- CLAUDE.md`. It was the obvious one-command fix, it
  would have restored all 25 lines, and it would have been wrong — a blanket revert cannot
  tell a regression from a correction, and this diff contained one of each.
- **Also merged in from the template, because both are true:** `budget-gate.sh:102-107`
  reads `fw_config_int "CONTEXT_WINDOW"` with `FW_CONTEXT_WINDOW` as the env override. The
  old text named only the config key, the template named only the env var. The restored
  text names both and cites the line.

### 2026-09-26 — the check asserts the review, not the content

- **Chose:** the audit predicate is *does `CLAUDE.md.bak` exist*, with the lost-line count
  reported as context. Not *were lines lost*.
- **Why:** after this restore, 6 lines still show as "absent" — and every one is a
  rewording whose substance is present, not a loss. A line-level diff cannot distinguish
  reworded from lost, so a check gated on the count would sit red forever with no action
  that clears it. That is OBS-293 (a permanently red check trains readers to ignore it),
  built in on purpose.
- **Rejected:** WARN on lost-line count > 0. Rejected precisely because it looks stricter.
  A signal nobody can clear is weaker than one they can, and the check would have been
  red on this very task after the fix was correct and complete.
- **Consequence, stated:** the check cannot tell whether the review was done *well*. It
  can only tell whether it was acknowledged. That is the honest limit of what a file's
  existence can witness, and it is still strictly more than the zero readers it has today.


## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-26T21:28:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-873-fw-upgrade-destroyed-the-t-675-budget-ca.md
- **Context:** Initial task creation
