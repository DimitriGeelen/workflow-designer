---
id: T-675
name: "budget-gate writes an UNMEASURED state into .budget-status as a measured 'ok' — the one file CLAUDE.md tells the agent to trust over its own arithmetic"
description: >
  A failed transcript scan in budget-gate.sh degrades to TOKENS=0 (deliberate fail-open, so a broken scan never blocks every tool call). But 0 then derives LEVEL=ok through the normal ladder and is written to .budget-status indistinguishably from a measured healthy session. CLAUDE.md 'Context Budget Management' says to read 'level' from that file and that 'level' wins over the agent's own arithmetic; the /resume skill reads it too. So the gate's failure mode writes MAXIMUM HEADROOM into the file that is authoritative by rule. Measured live this session: cache said {level: ok, tokens: 0} while checkpoint.sh status measured 82719. Benign at 27%, inverted at 95%. Second defect, same file: the gate rejects its own cache above BUDGET_STATUS_MAX_AGE (90s), but external readers (/resume, doctor, the agent) apply no freshness check, so a cache from a prior session reads as current. Third: the /resume skill mandates 'checkpoint.sh budget' as the safe read; that subcommand does not exist (Usage: post-tool|reset|status), so the hardening is inert here.

status: started-work
workflow_type: build
owner: claude-code
horizon: now
tags: []
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-09-03T21:31:36Z
last_update: 2026-09-03T21:31:43Z
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

# T-675: budget-gate writes an UNMEASURED state into .budget-status as a measured 'ok' — the one file CLAUDE.md tells the agent to trust over its own arithmetic

## Context

Found by `/resume` at the start of this session, not by a detector. The skill's own
step 6 mandates `checkpoint.sh budget` as a G-087-safe read; that subcommand did not
exist, so the fallback raw read returned `{"level": "ok", "tokens": 0}` while the
session held 82,719 tokens (117,630 by the time the fix landed).

**Three writers, two of which assert a state nobody measured:**

| writer | when | wrote | measured? |
|---|---|---|---|
| `budget-gate.sh` scan | every 5th tool call | real level + tokens | yes |
| `budget-gate.sh` fail-open | scan fails | `{ok, 0}` | **no** |
| `post-compact-resume.sh` | every `/compact` (T-1087) | `{ok, 0}` | **no** |

Both unmeasured writes are individually CORRECT and stay. The fail-open exists so a
broken scan never blocks every tool call; the T-1087 seed exists to stop the slow path
reading pre-compact usage and blocking a fresh session. The defect is that neither
could SAY it was an assumption, so both rendered as the same `{ok, 0}` a measured
healthy session renders as — and CLAUDE.md instructed the agent to let that `level`
win over its own arithmetic. **The failure mode wrote maximum headroom into the file
that is authoritative by rule.**

Benign at 39%. At 95% it is the gate telling a session it has full headroom precisely
when it has none — and the fail-open guarantees the moment the scan breaks is the
moment the file becomes least trustworthy and most trusted.

Same shape as the `fw fabric scan` false green (T-671/T-673): an act that improves the
visible number by degrading the thing the number was standing in for. Here the file
gained *reassurance* by losing *provenance*.

Second, independent half: the gate rejects its own cache past 90s, but every external
reader (`/resume`, `fw doctor`, the agent under CLAUDE.md) applied **no freshness check
at all**. The value read this morning had been written hours earlier.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Every writer of `.budget-status` stamps whether the value was MEASURED. The two
      writers that currently emit `{level: ok, tokens: 0}` — `budget-gate.sh`'s
      scan-failure fail-open and `post-compact-resume.sh`'s T-1087 seed — mark it
      `"measured": false`; a real transcript scan marks it `"measured": true`.
- [x] The cache carries `session_id`, so a reader can tell a prior session's file
      from this session's.
- [x] **The fail-open is preserved.** A failed scan still never blocks a tool call:
      `LEVEL=unknown` matches no branch of either `case` in budget-gate.sh, so the
      gate exits 0. Proven by driving a scan failure, not by reading the code.
- [x] **The T-1087 seed still seeds `level: ok`.** It exists to stop a worse
      regression (the slow path reading pre-compact usage and blocking a fresh
      session). This task adds a flag to it and changes nothing else about it.
- [x] `checkpoint.sh budget` exists and is the safe read the `/resume` skill already
      mandates. It refuses a cache that is unmeasured, stale beyond
      `BUDGET_READ_MAX_AGE` (900s), or from another session — reporting
      `level: unknown` plus the reason, instead of a plausible `ok`. The reader gets
      its OWN threshold rather than reusing the gate's `BUDGET_STATUS_MAX_AGE` (90s):
      90s is right for a hook that re-measures every tool call, but a session-start
      reader would refuse almost every time, and a check that always fires is one
      that gets ignored.
- [x] Both arms driven (PL-308): a fence drives each refusal case against a throwaway
      cache and asserts `budget` REFUSES, and asserts it ACCEPTS a genuine fresh
      measured one. A guard that has only ever been green is a hand-maintained claim.
- [x] The live instance that prompted this no longer reads as a plausible `ok`.
      Demonstrated in both directions against the real file, not a fixture: the
      first safe read REFUSED it (`stale by 12s ... likely a previous session's`),
      and once the gate re-measured, the same command reported `level: ok /
      tokens: 117630 (~39%) / measured: true`. Before this task the same file said
      `{"level": "ok", "tokens": 0}` and CLAUDE.md said to trust it.

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
         1. Run `bin/fw reviewer T-675`
         **Expected:** Verdict: PASS; no findings on `block-message-completeness`
         **If not:** Inspect hook block-message string and add missing mechanism
       Conversion: this AC should be moved to ### Agent and
       `bin/fw reviewer T-675 2>&1 | grep -q "Overall:.*PASS"` added to ## Verification.
-->

## Verification

# Every arm of the safe read plus the gate's fail-open, against throwaway roots.
# This is the whole task in one command: 7 reader arms (6 refuse, 1 accept) and 3
# gate arms. Proven to DISCRIMINATE, not merely to be green — run against HEAD's
# pre-fix copies it fails 9 of 10, and the single arm that passes there is
# "gate fails OPEN", which is the property this task had to PRESERVE.
python3 tools/_t675-budget-read-fence.py

# All three edited scripts still parse. budget-gate.sh runs on EVERY tool call:
# a syntax error here does not degrade, it takes the session down.
bash -n .agentic-framework/agents/context/budget-gate.sh
bash -n .agentic-framework/agents/context/checkpoint.sh
bash -n .agentic-framework/agents/context/post-compact-resume.sh

# The subcommand the /resume skill has been mandating all along now exists.
.agentic-framework/agents/context/checkpoint.sh budget >/dev/null 2>&1 || test $? -eq 3
bash .agentic-framework/agents/context/checkpoint.sh nosuchcmd 2>&1 | grep -q 'post-tool|reset|status|budget'

# Both unmeasured writers stamp themselves. Greps the SOURCE, so a future edit that
# drops the stamp while keeping the value is caught here rather than in production.
grep -q '"measured": false' .agentic-framework/agents/context/post-compact-resume.sh
grep -q 'MEASURED=false' .agentic-framework/agents/context/budget-gate.sh

# T-1087's seed is load-bearing (it prevents the slow path reading pre-compact usage
# and blocking a fresh session). This task added a flag to it and changed nothing
# else: the seeded level must still be ok.
grep -q '"level": "ok", "tokens": 0' .agentic-framework/agents/context/post-compact-resume.sh

# CLAUDE.md no longer tells the agent to cat the file this task proved unreliable.
grep -q 'checkpoint.sh budget' CLAUDE.md

# The new tool is carded (fabric coverage was brought to 100% by T-673; a new
# tools/*.py that nobody cards regresses it silently).
test -f .fabric/components/tools-_t675-budget-read-fence.yaml

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
     fw inception decide T-675 go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-09-03T21:31:36Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-675-budget-gate-writes-an-unmeasured-state-i.md
- **Context:** Initial task creation

### 2026-09-03T21:31:43Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
