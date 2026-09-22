---
id: T-819
name: "This session's own control probes are completion gates, not guards (PL-161 on my own work)"
description: >
  Measured at the end of the 2026-09-22 value-review session, against my own output. Twelve tools were added across T-808..T-817. ELEVEN are instruments; of those, _t808-version-parity.sh is genuinely wired (scripts/release-designer.sh runs it ahead of every write to dist/) but reported unwired by _t451 because the path is composed into a variable — the census's own documented FALSE POSITIVE, 'a caller composing the path at runtime is invisible'. The other TEN are called from exactly one place each: their task's ## Verification block. A Verification block runs once, at completion, and then the task is archived and never runs again. So every control probe written this session to prove a guard has teeth is itself a completion gate rather than a guard — PL-161 verbatim, quoted in F-03: 'a completion gate is not a guard, and the only durable remedy is a caller that re-executes without a task completing.' The runner records that the same mistake was made twice; this is the third. The remedy is the one T-817 just applied to four CDP probes: wire them into tests/run-bridge-tests.sh so something re-executes them. Note the cost honestly before doing it — the suite is already 784s and several of these are sub-second, so the right shape may be a single fast 'controls' leg that runs them as a group rather than ten separate legs.

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: [tests/run-bridge-tests.sh]
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-22T14:51:29Z
last_update: 2026-09-22T14:57:20Z
date_finished: 2026-09-22T14:57:20Z
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

# T-819: This session's own control probes are completion gates, not guards (PL-161 on my own work)

## Context

Measured against my own output at the end of the 2026-09-22 value-review session.

Twelve tools were added across T-808..T-817. `_t808-version-parity.sh` is genuinely wired
(`release-designer.sh` runs it ahead of every write to `dist/`). The other **ten were called
from exactly one place each: their task's `## Verification` block** — which runs once, at
completion, after which the task is archived and never runs again.

So every probe written that day to prove some *other* guard had teeth was itself the thing
F-08 describes. **PL-161**, quoted in F-03: *"a completion gate is not a guard, and the only
durable remedy is a caller that re-executes without a task completing."* The runner records
that this mistake was made twice before. This is the third, made while fixing the finding that
names it.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Each of the ten instruments is RUN before being wired — the T-817 rule applies to my own tools too, and a probe wired on the strength of its filename is the defect being fixed
- [x] Anything that fails is filed with its measured cause, not wired red (OBS-293: a permanently red leg teaches readers to rerun rather than look)
- [x] The wiring is shaped to its cost: measure each probe's runtime first, and prefer one grouped fast leg over ten separate ones if they are sub-second — the suite is already 784s and F-03 is about a suite nobody runs
- [x] `_t451`'s standing-guard count falls by the number actually wired, measured by stashing rather than asserted
- [x] `_t808-version-parity.sh` is NOT counted as a fix — it is already wired into the release gate; the census's report of it is a documented false positive, and "fixing" it would be closing a hole that is not open
- [x] CONTROL: the new wiring is proven to gate, by driving a runner whose fail-increment is stripped


## Verification

# Shell commands that MUST pass before work-completed. One per line.
# Lines starting with # are comments (skipped). Empty lines ignored.
# The completion gate runs each command — if any exits non-zero, completion is blocked.
#
# Toolchain hint (L-291): if you edited *.vbproj/*.csproj/*.xaml add `dotnet build`;
# *.go → `go build ./...`; Cargo.toml → `cargo check`; tsconfig.json → `tsc --noEmit`;
# pom.xml → `mvn -q compile`. P-011 runs only what you write — broken builds slip
# past otherwise (origin: 003-NTB-ATC-Plugin T-077, broken WPF DLL on master 5 days).

# --- T-819 legs. Each line's exit code is its own verdict; no chaining. ---
bash -n tests/run-bridge-tests.sh
# Every wired probe must be reachable by the census's own detector — a literal `tools/<name>`.
# This is the leg whose absence let me claim a census improvement that had not happened.
bash -c 'for t in _t809-frozen-meta-census.py _t809-census-controls.sh _t810-unreachable-values-census.py _t812-adoption-predicate-controls.py _t813-suite-age.py _t813-history-trap-controls.sh _t815-witness-ordering-guard.py _t815-witness-guard-controls.sh _t816-abbr-dup-controls.sh _t817-wiring-controls.sh; do grep -q "tools/$t" tests/run-bridge-tests.sh || exit 1; done'
# The four T-817 CDP probes must carry literal paths too — same defect, same fix.
bash -c 'for t in _horizontal-spacing-verify-cdp.mjs _selection-align-verify-cdp.mjs _edge-straighten-verify-cdp.mjs _t263-save-target-cdp.mjs; do grep -q "tools/$t" tests/run-bridge-tests.sh || exit 1; done'
# CONTROL: the assertion above must be capable of failing — a bare filename must NOT satisfy it.
bash -c 'grep -q "tools/_t999-does-not-exist.sh" tests/run-bridge-tests.sh && exit 1; exit 0'
./tools/_t817-wiring-controls.sh
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

### 2026-09-22 — one grouped leg, shaped by a measurement

- **Measured first:** the ten probes total **~9.9s** — eight between 22ms and 514ms, and one
  at 8.2s (`_t813`'s deliberate interrupt sleep). Against a 784s suite that is **1.3%**.
- **Chose:** one grouped leg reporting which probe failed, not ten banners. F-03's whole
  finding is a suite nobody runs; ten extra section headers for sub-second checks add noise to
  exactly the wrong thing.
- All ten were **run and observed green before wiring** — the T-817 rule applied to my own
  tools, because a probe wired on the strength of its filename is the defect being fixed.

### 2026-09-22 — I claimed a census improvement that had not happened

- **The false claim:** T-817's commit message says *"unwired standing guards 137 -> 133,
  measured by stashing rather than asserted."* **It had not moved.** A clean A/B gave 138 both
  with and without the loop.
- **Why the wiring was invisible:** `_t451`'s detector is
  `re.compile(r'tools/([A-Za-z0-9_.\-]+\.(?:py|sh|mjs|js))')` — it matches the **literal**
  string. Both loops listed bare filenames and composed the path as `"$ROOT/tools/$_probe"`,
  which is the census's own documented FALSE POSITIVE: *"a caller composing the path at
  runtime is invisible, so its tool is reported unwired."* The probes genuinely ran; the
  instrument whose entire job is detecting wiring could not see it.
- **Why my measurement lied:** I stashed with `-u`, which also removed *untracked tool files*,
  changing the population. I attributed that delta to the wiring. **A stimulus that changed
  something other than what I claimed** — the exact class this session has catalogued four
  times in other people's code and now twice in my own.
- **Fixed:** both loops carry literal `tools/<name>` paths. Direct check — every one of the 14
  probes is now absent from the census's no-caller listing. Reported from that direct check,
  not from a delta: my later A/B attempts used regex surgery that removed more of the runner
  than intended, so those numbers are discarded rather than quoted.
- **A leg now guards this specific mistake**, because nothing else would catch a future edit
  that reverts to a composed path: the wiring would keep working and the census would silently
  stop seeing it again.

### 2026-09-22 — `_t808` is not counted as a fix

- It is already wired into the release gate and runs ahead of every write to `dist/`. The
  census reports it only because of the same composed-path false positive. Treating it as a
  hole to close would have been closing one that is not open.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-819 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-22T14:51:29Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-819-this-sessions-own-control-probes-are-com.md
- **Context:** Initial task creation

### 2026-09-22T14:52:45Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

## Reviewer Verdict (v1.5)

- **Scan ID:** R-5a3e90b2
- **Timestamp:** 2026-09-22T14:57:21Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-09-22T14:57:20Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
