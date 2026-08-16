---
id: T-231
name: "Harden serve-gallery.sh: clean-stop-before-bind + fail-loud on port-in-use
  + behavior probe (committed!=serving prevention)"
description: >
  serve-gallery.sh line 57 execs python3 gallery-serve.py --bind without stopping
  an existing server on the port; if the port is held the new process fails to bind
  and dies silently, leaving the STALE process serving old code (committed!=serving,
  hit twice: rail offset 137 + S4a). Harden: stop any gallery-serve on the target
  PORT first (SIGINT, it ignores SIGTERM), confirm the port is free, then bind; fail
  loudly if the port stays held; emit the served process's start-time so verify-live
  can assert start-time>commit-time. Add a post-deploy behavior probe helper (not
  a source grep). Prevention for the verify-live learning.

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
created: 2026-07-21T23:28:52Z
last_update: '2026-08-16T14:33:22Z'
date_finished: 2026-07-22T05:38:51Z
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
  - ts: '2026-08-16T12:33:45Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 3
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=3 (body:fw-recall-or-memory-link);
      F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal); F2=0 
      (no-signal)
    rubric_sha: e4a00f38e801
  - ts: '2026-08-16T14:33:22Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 0
      D4: 2
      F-RECALL: 3
      F2: 0
      F4: 0
      F3: 0
      F1: 0
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=0 (no-signal); 
      D4=2 (body:env-class-handled); F-RECALL=3 (body:fw-recall-or-memory-link);
      F2=0 (no-signal); F4=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal)
    rubric_sha: e4a00f38e801
cost_estimate_proposed:
  - ts: '2026-08-16T13:57:19Z'
    estimator: bvp-estimator-v1-heuristic
    cost_estimate:
      tier: 2
      effort: 7
      blast_radius: 3
    rationale: blast_radius=3 
      (paths:tools/_serve-gallery-verify.py,tools/serve-gallery.sh); tier=2 
      (no-signal); effort=7 (no-signal)
    rubric_sha: e4a00f38e801
---

# T-231: Harden serve-gallery.sh: clean-stop-before-bind + fail-loud on port-in-use + behavior probe (committed!=serving prevention)

## Context

`serve-gallery.sh` `exec`s `gallery-serve.py` with no clean-stop-before-bind. Under the
canonical `nohup tools/serve-gallery.sh 8834 >/dev/null 2>&1 &` invocation, a stale process
already holding the port makes the new process **fail to bind and die silently**, while the
OLD process keeps serving stale code — the **committed!=serving** failure, hit twice (rail
offset 137 pre-S1 server; S4a claim, offset 142). This hardens the deploy: **clean-stop-before-bind**
(SIGINT — `gallery-serve.py`'s HTTPServer handles KeyboardInterrupt but ignores SIGTERM),
**fail-loud** if the port stays held (never leave a shadow), and a **post-deploy behavior probe**
that asserts the RUNNING process answers before reporting success + emits the served PID/start-time
(so verify-live can assert start-time>commit-time). Prevention layer for the verify-live learning
(assert running-process BEHAVIOR, not source/shape). See `[[aef-integration-rail]]`.

## Acceptance Criteria

### Agent
- [x] **Clean-stop-before-bind:** before binding, `serve-gallery.sh` detects any process listening on the target PORT (via `ss`) and stops it cleanly (SIGTERM then SIGINT, since `gallery-serve.py` ignores SIGTERM), waiting for the port to release
- [x] **Fail-loud on still-held:** if the port is still held after the stop attempt, the script prints a clear FATAL message naming the port + holder PID(s) and exits non-zero — it never binds a second, shadowed server (the committed!=serving root cause) and never escalates to SIGKILL silently
- [x] **Post-deploy behavior probe:** after starting the server the script probes the RUNNING process (`/api/health` for gallery-serve, `/` for the static fallback) and only reports "live" on success (emitting the served PID + start-time); if the server never answers, the script exits non-zero rather than claiming success
- [x] **Lifecycle regression test** (`tools/_serve-gallery-verify.py`) reproduces both failure modes: (A) start on port P, start AGAIN on P → exactly ONE listener answers `/api/health` afterward and it is a FRESH pid (old one cleanly stopped, no dual-process); (B) a SIGINT-deaf holder on P → serve-gallery.sh exits non-zero with a loud message and starts no shadow server. Passes
- [x] **No regression:** the normal single-start path still serves the gallery + `/api/*` (health OK, index lists the corpus maps); `bash -n tools/serve-gallery.sh` is clean

### Human
<!-- None — all criteria are deterministic infra checks, verified by the lifecycle
     test + bash -n in ## Verification. -->

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
# Pipefail/SIGPIPE hint (L-387): P-011 runs each command under `set -eo pipefail`.
# `cmd | grep -q PATTERN` exits 141 (SIGPIPE) when grep matches and closes stdin
# while the upstream is still writing — verification then "fails" even though
# the pattern was present. Safe pattern: capture first, grep the capture:
#     out=$(cmd 2>&1); echo "$out" | grep -q "PATTERN"
# Or:
#     cmd > /tmp/.out 2>&1 && grep -q "PATTERN" /tmp/.out
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
bash -n tools/serve-gallery.sh
python3 tools/_serve-gallery-verify.py

## RCA

**Symptom:** After committing server-side code (S1 pre-server offset 137; S4a claim offset 142)
and "redeploying", the running `:8834` kept serving the PRE-commit code — the claim did not fire,
`/api/list` served the old shape — even though the source + git were correct. Hit twice.

**Root cause:** `serve-gallery.sh` `exec`s `gallery-serve.py` with no clean-stop-before-bind.
A stale process still holds the port, so the "redeploy" process **fails to bind and dies**; under
`nohup ... &` that death is invisible, leaving TWO processes with the stale one still serving.

**Why structurally allowed:** the deploy script had zero port-conflict handling and no post-deploy
behavior probe — "redeploy" was assumed to replace the server but silently didn't. The verify step
compounded it by grepping the SOURCE file + checking response SHAPE (identical old/new) instead of
the RUNNING process's behavior (the PL-046 blind spot, hit a 2nd time).

**Prevention:** clean-stop-before-bind (stop the old listener first) + fail-loud (never bind a
shadow — if the port stays held, abort non-zero) + post-deploy behavior probe (assert the LIVE
process answers, emit its PID/start-time) + a lifecycle regression test that reproduces the race
and fails if a future edit reintroduces the silent-shadow path. Distinct from the fix: the test is
the standing guard.

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

### 2026-07-21T23:28:52Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-231-harden-serve-gallerysh-clean-stop-before.md
- **Context:** Initial task creation

### 2026-07-22T05:32:58Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-07-22T05:38:51Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
