---
id: T-169
name: "G-020 gate circularly blocks its own type-inception remediation"
description: >
  check-active-task.sh build-readiness gate blocks fw task update --type inception, the very command it prints as the unblock, because the task is still a placeholder build task. Fix: exempt type-conversion commands from the gate.

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
created: 2026-07-10T04:36:54Z
last_update: 2026-07-10T04:37:38Z
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

# T-169: G-020 gate circularly blocks its own type-inception remediation

## Context

Discovered while trying to advance T-155 (convert a parked build task to an inception).
`agents/context/check-active-task.sh` has a **build-readiness gate (G-020)** at ~:535 that blocks
source edits when the focused task is `build|refactor|test|decommission` with placeholder/missing
ACs. But the gate does not inspect the command — so `fw task update <T> --type inception`
(a metadata change, and the *exact* remediation the gate prints at :556-557) is itself blocked
when run against the still-placeholder build task. The remediation is circular.

Root cause: the bootstrap allowlist at :77 exempts `fw work-on|task create|context focus|inception`
but NOT `fw task update … --type …`. A `--type` conversion is metadata, not a source edit, and
must not be gated by the build-readiness (source-edit) gate.

Fix: exempt a Bash `fw task update <focused-task> … --type …` command from the build-readiness
gate (narrowly — only the type-conversion of the focused task; general edits stay gated).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] `check-active-task.sh` exempts a Bash `fw task update <CURRENT_TASK> … --type …` command from the G-020 build-readiness gate, so converting a placeholder build task to inception (the gate's own printed remediation) is no longer circularly blocked. Exemption is scoped to the type-conversion of the *focused* task only.
- [x] Regression: a Write/Edit to a real source file (outside `.tasks/.context/.claude`) under a placeholder build task is STILL blocked (exit 2) — the exemption does not widen to general edits.
- [x] Regression: a `fw task update <CURRENT_TASK> --status …` (no `--type`) still passes through the existing gates unchanged (not newly exempted).
- [x] Verified live via the hook harness: piping the conversion command's JSON with focus on a placeholder build task → exit 0; piping a source-file Edit JSON with the same focus → exit 2. Evidence pasted in Updates.
- [x] `bash -n agents/context/check-active-task.sh` parses clean; `.claude/settings.json` untouched (no enforcement-baseline refresh needed).

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

bash -n .agentic-framework/agents/context/check-active-task.sh
grep -q "TYPE_CONVERT_EXEMPT" .agentic-framework/agents/context/check-active-task.sh

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

## RCA

**Symptom:** `fw task update T-155 --type inception` was blocked by the G-020 build-readiness
gate — the *exact* command the gate prints as its "Or change to inception" remediation.

**Root cause:** the build-readiness gate (check-active-task.sh :535) blocks when the FOCUSED
task is a placeholder build/refactor/test/decommission task, and it runs for every tool call
(Bash included, FILE_PATH empty) without inspecting the command. A `--type` conversion is a
metadata change, not a source edit, so it should never have been subject to a source-edit gate.
The bootstrap allowlist at :77 exempts `work-on|task create|context focus|inception` but omits
`task update … --type …`.

**Why structurally allowed:** the gate was written to guard SOURCE edits (Write/Edit FILE_PATH)
but also fires on Bash mutation commands; no test covered the "convert a placeholder build task
to inception" path, so the circularity (gate blocks its own remediation) went unnoticed.

**Prevention:** the exemption is scoped to the focused task's `--type` conversion only, and this
task's ACs include a hook-harness regression matrix (conversion→0, source-edit→2, status-update→2,
other-task-conversion→2) documented in Updates. A future gate change that breaks this will fail
the harness. Also captured as a learning.

**Related fragility (NOT fixed here — see T-170):** `has_bash_write_pattern` (:71) mis-flags
otherwise-safe bootstrap commands (`fw context focus`, `fw task create`) as writes when they
contain a benign redirect (`>/dev/null`) or angle-bracket text (`<T>`) in arguments, skipping the
:77 allowlist and blocking them under a placeholder-build focus. Worked around by dropping the
redirect/brackets; filed separately (one bug = one task).

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

### 2026-07-10T04:36:54Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-169-g-020-gate-circularly-blocks-its-own-typ.md
- **Context:** Initial task creation

### 2026-07-10T04:37:38Z — status-update [task-update-agent]
- **Change:** status: captured → started-work

### 2026-07-10 — hook harness verification [agent]
- **Fix:** added `TYPE_CONVERT_EXEMPT` guard to the build-readiness gate in
  `.agentic-framework/agents/context/check-active-task.sh` (exempts `fw task update <focused> … --type …`).
- **Harness (focus=T-155, a placeholder build task):**
  - case1 `fw task update T-155 --type inception` → exit 0 (exempt) ✓
  - case2 Edit to `src/aef-workflow-designer.html` → exit 2 (still blocked) ✓
  - case3 `fw task update T-155 --status issues` (no --type) → exit 2 (unchanged) ✓
  - case4 `fw task update T-999 --type inception` (different id) → exit 2 (scoped to focus) ✓
- **Gates:** `bash -n` SYNTAX-OK; `.claude/settings.json` untouched.

