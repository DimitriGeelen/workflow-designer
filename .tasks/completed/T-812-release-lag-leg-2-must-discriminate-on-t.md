---
id: T-812
name: "Release-lag leg 2 must discriminate on the distance it already computes (F-02)"
description: >
  Value review T-742 F-02: verdict() in tools/_t382-release-lag.py escalates the adoption leg on adopt_days — the age of OUR OWN latest tag — while adopt_behind ('0.8.0 -> 0.12.0'), the only value carrying the actual distance, is interpolated into a message string and never enters a comparison. Driven on constructed inputs: peer 11 versions behind with our tag cut today grades ok. So any cut resets the gauge to green and the condition can be held green indefinitely by the ordinary act of releasing. This is the instrument that was supposed to catch F-01, the four-release delivery gap. Compounding: teeth() leg 5 sets adopt_behind only with adopt_days 99, so no self-test constructs the live shape. Make the leg discriminate on the distance, and add the missing teeth leg.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tools/_t382-release-lag.py, tools/_t812-adoption-predicate-controls.py]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T13:17:53Z
last_update: 2026-09-22T13:23:42Z
date_finished: 2026-09-22T13:23:42Z
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

# T-812: Release-lag leg 2 must discriminate on the distance it already computes (F-02)

## Context

Value review T-742 **F-02**, consequence 2. `verdict()` escalated the adoption leg on
`adopt_days` — **the age of our own latest tag** — while `adopt_behind` (`"0.8.0 -> 0.12.0"`),
the only value carrying the distance, was interpolated into a message string and **never
entered a comparison**.

Consequence, in the finding's words: *"any new cut restarts that window — so the condition can
be held green indefinitely by the ordinary act of releasing."* This is the instrument that was
supposed to catch **F-01**, the four-release delivery gap, and it graded it PASS.

Compounding: `teeth()` leg 5 set `adopt_behind` only alongside `adopt_days: 99`, so **no
self-test ever constructed the live shape** — behind, with a fresh tag. The probe kept a clean
teeth record over precisely the configuration production reports.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `measure()` computes the adoption distance as a NUMBER — how many released versions separate the peer's pin from ours — counted against the versions that actually shipped, not parsed out of a message string
- [x] `verdict()` escalates on that distance INDEPENDENTLY of `adopt_days`, so a fresh cut cannot reset the gauge to green
- [x] The three shapes the finding drove are asserted directly on constructed inputs: peer 4 behind + tag 0d, peer 3 behind + tag 28d, peer 11 behind + tag 0d — none of which may grade `ok`
- [x] A teeth leg constructs the LIVE shape (`adopt_behind` set, small `adopt_days`) — the configuration production actually reports and which `teeth()` leg 5 never built
- [x] CONTROL: reverting the predicate to the old days-only form makes the new teeth legs FAIL, proving they bind to the fix rather than passing regardless
- [x] The check is made truer, never weaker: no threshold is relaxed and no leg is removed
- [x] An unmeasurable distance is not a pass — if the version series cannot be read, the leg says so rather than reporting 0 behind


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-812 legs. Each line's exit code is its own verdict; no chaining. ---
python3 tools/_t382-release-lag.py --teeth
# The predicate must actually compare the distance — not merely define the constants.
grep -q 'adopt_versions_behind' tools/_t382-release-lag.py
grep -qE 'n >= FAIL_BEHIND' tools/_t382-release-lag.py
# Every adoption reason must carry the substring audit.sh greps for ('peer pin behind'),
# else a distance-only escalation reaches the audit record as "see probe" with no reason.
python3 tools/_t812-adoption-predicate-controls.py
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

### 2026-09-22 — distance AND age, both escalating independently

- **Chose:** count the distance as a number (`adopt_versions_behind`) against the versions
  actually present in `dist/`, and escalate on it independently of `adopt_days`.
- **Why the dist/ listing:** it is the same source `release-designer.sh` uses for
  `supersedes`, for the reason it states there — *"a curated chain drifts from what shipped,
  and the whole point of the field is to be countable against reality."*
- **Why keep age too:** they are different signals. A peer one release behind for thirty days
  is a real adoption problem that the distance rung alone would grade a mere warn.
- **Thresholds are a judgement and no ruling exists** — checked `concerns.yaml`; G-024 names
  the need for a standing visible delta and gives the adoption leg no numbers. Chosen so the
  motivating incident would have been caught: F-01 was **four** releases behind, so FAIL at 3;
  WARN at 1 makes the gap visible the day it opens, which is the property the old predicate
  lacked. Recorded in the source as a judgement the operator may re-set.
- **Unplaceable is FAIL, not 0:** returning "0 behind" for a pin nobody can locate is the same
  false-green shape being repaired here.

### 2026-09-22 — I broke the audit's grep, and fixed it on OUR side rather than in vendored code

- **What happened:** `audit.sh:2257` builds the adoption line with
  `grep -m1 'peer pin behind'`. My first wording — *"peer pin 4 releases behind"* — does not
  contain that substring, so a distance-only escalation would have reached the audit record as
  `"see probe"` with the reason discarded. A regression I introduced, caught by reading the
  consumer rather than by a test.
- **Chose:** reword every adoption reason to carry the anchor, verified by a control that
  drives all four shapes and asserts the substring.
- **Rejected — fixing `audit.sh`:** it is vendored, and **T-519 records that this exact file
  already carries five local divergences** plus a live risk that *"at the next re-vendor their
  audit.sh overwrites ours and the other four die."* Adding a sixth divergence for a display
  fix would raise that exposure for the smallest of the two defects. The `${_l1:-${_l2:-…}}`
  shadowing F-02 also names stays unfixed and is called out below rather than silently left.
- **Known and NOT fixed:** when a build lag and an adoption lag coexist, `audit.sh` shows only
  the build lag — `_l2` is shadowed by `_l1`. Reported upward, not patched here.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-812 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T13:17:53Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-812-release-lag-leg-2-must-discriminate-on-t.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a55ae0b9
- **Timestamp:** 2026-09-22T13:23:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T13:23:42Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
