---
id: T-607
name: "Focus-drift gate cannot see the fw invocation form CLAUDE.md mandates: path-prefixed bin/fw escapes patterns 1 and 2"
description: >
  Focus-drift gate cannot see the fw invocation form CLAUDE.md mandates: path-prefixed bin/fw escapes patterns 1 and 2

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
created: 2026-08-26T21:19:01Z
last_update: 2026-08-26T21:22:39Z
date_finished: 2026-08-26T21:22:39Z
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

# T-607: Focus-drift gate cannot see the fw invocation form CLAUDE.md mandates: path-prefixed bin/fw escapes patterns 1 and 2

## Context

OBS-320. The focus-drift gate (T-1730) anchors every one of its target patterns on
`(^|[[:space:]])(bin/)?fw` — so the character before `fw` must be start-of-string,
whitespace, or the literal `bin/`. CLAUDE.md §Copy-Pasteable Commands *mandates*
`cd /opt/832-Workflow-designer && .agentic-framework/bin/fw ...`, where the character
before `bin/fw` is `/`. The alternation has no branch for a longer path prefix, so the
gate is blind to the exact invocation form the project requires everyone to use.

Measured against the real hook, four payloads on stdin, `CLAUDECODE=1`, focus `T-575`
(`scratchpad/probe-{a,b,c,d}.json`):

| command                                            | exit | drift |
|----------------------------------------------------|------|-------|
| `fw task update T-999 --status issues`             | 2    | fires |
| `.agentic-framework/bin/fw task update T-999 ...`  | 0    | SILENT|

The two differ only in the path prefix. Pattern 3 (`git commit ... T-NNN:`) is unaffected
because it anchors on the commit message rather than on `fw` — which is why the gate has
been *partially* live all along, and why nobody noticed: the drift blocks people actually
saw were all pattern 3. PL-182 names this exactly: reachability is not binary.

**Scope boundary.** This is NOT T-392. T-392 is a second, independent cause with an
identical symptom: the safe-command early-return at `check-active-task.sh:97` exits 0 long
before the drift block at :305, so `fw context add-*` is exempt from drift attribution no
matter how the regex is anchored. Fixing this task makes pattern 1 reachable in the
mandated form; pattern 2 stays shadowed until T-392 restructures that early return. Both
must land before the gate is honest, and conflating them would let one fix claim the other's
ground. Vendored under `.agentic-framework/` — G-008 permits in-tree fix and upstream.

## Acceptance Criteria

### Agent
- [x] The path anchor accepts any directory prefix: `fw`, `bin/fw`,
      `.agentic-framework/bin/fw` and an absolute `/opt/.../bin/fw` all reach the gate,
      applied to every pattern that anchors on `fw` (patterns 1 and 2), not only the one
      the probe happened to exercise.
- [x] It does NOT over-match: a token merely ENDING in `fw` (e.g. `myfw`, `xfw`) must not
      be treated as the framework CLI. A guard that fires on the wrong command is worse
      than one that misses, because it trains people to bypass.
- [x] `tools/_t607-drift-gate-reach.py` drives the REAL hook via stdin (not a
      reimplementation of its regex) and asserts exit codes for a matrix of
      pattern × invocation-form × drift/no-drift, including a NO-DRIFT control per
      pattern so a change that blocks everything cannot pass as a fix.
- [x] Poison arm: restoring the original `(bin/)?` anchor turns the path-form legs red
      while leaving the bare-form legs green — proving the legs discriminate the actual
      defect and not merely "the gate exists". Arm restores the file, sha256-verified.
- [x] Pattern 2's continued unreachability is REPORTED by the verifier as a named,
      expected condition citing T-392 — not silently omitted, and not asserted as if it
      were fixed here.
- [x] The gate still lets legitimate work through: after the change, a commit whose
      message targets the focused task, and `--switch-focus` / `FW_SWITCH_FOCUS=1`
      bypasses, all still behave as before.

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


# 14-leg matrix across 4 invocation forms + over-match guards + bypass legs, driving the
# REAL hook over stdin against a throwaway project root, plus a poison arm.
timeout 300 python3 tools/_t607-drift-gate-reach.py
# The hook must remain syntactically valid — a broken enforcement hook fails OPEN or
# blocks everything, and both look like "the gate changed".
bash -n /opt/832-Workflow-designer/.agentic-framework/agents/context/check-active-task.sh

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


**Symptom:** the focus-drift gate did not fire for `.agentic-framework/bin/fw task update
T-NNN` — the invocation form CLAUDE.md mandates — while firing normally for bare `fw`.
Measured: identical commands, differing only in the path prefix, exit 2 vs exit 0.

**Root cause:** the pattern anchored on `(^|[[:space:]])(bin/)?fw`. The alternation
enumerated the two path prefixes someone had in mind (none, and `bin/`) rather than
expressing the property that actually matters — that `fw` begins a word. The mandated
prefix ends in `/` and matched neither branch.

**Why structurally allowed:**
1. **The gate was partially live, which reads as fully live.** Pattern 3 anchors on the
   commit message, not on `fw`, so it kept firing on the mandated form. Every drift block
   anyone actually experienced — including mine earlier today — came from pattern 3. A
   gate that blocks you sometimes does not feel like a gate that is broken.
2. **Nothing tested reachability per invocation form.** The gate had been exercised only
   in whatever form its author typed. Reachability is not binary (PL-182): between "runs
   always" and "never runs" sits "runs for the shape you happened to test".
3. **CLAUDE.md's own mandate moved the target after the fact.** The §Copy-Pasteable
   Commands rule requires the path-prefixed form precisely because bare `fw` may resolve
   to a different install — so the project standardised on the one shape its gate could
   not see, and no check tied the two documents together.

**Prevention:** `tools/_t607-drift-gate-reach.py` drives the real hook over a matrix of
pattern × invocation form × drift/no-drift. It never re-implements the regex — a test that
restates the pattern it checks agrees with itself and would have passed on the broken code.
A no-drift control per form means a change that simply blocks everything cannot pass as a
fix; over-match guards mean widening the anchor cannot start catching `myfw`; and the
poison arm proves the legs discriminate by reddening ONLY the two path forms when the old
anchor is restored.

**Scope honesty:** the no-drift controls assert that the DRIFT gate did not fire, not that
the command would ultimately be allowed — the throwaway root has no task file, so those
legs exit 2 for an unrelated reason. That is the correct scope for a test of this gate, and
it is stated here rather than left for a reader to discover from the exit codes.

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

### 2026-08-26T21:19:01Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-607-focus-drift-gate-cannot-see-the-fw-invoc.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-a4cd16b9
- **Timestamp:** 2026-08-26T21:22:51Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-26T21:22:39Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
