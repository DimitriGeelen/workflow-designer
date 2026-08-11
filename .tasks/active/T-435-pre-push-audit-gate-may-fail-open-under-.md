---
id: T-435
name: "Pre-push audit gate may fail open under lock contention: verify AEF OBS-221 against this tree"
description: >
  AEF reported at DM 538 s5 that their pre-push audit gate allows a push through when another audit holds the lock: the audit exits 0 on 'Another audit is already running', and the hook reads exit 0 as PASS. One exit code carrying two meanings, and the gate consumer cannot distinguish them. They state that a tree which vendored that hook has it. This task verifies the claim against THIS tree by driving the contention rather than reading the code, and either reproduces it, disproves it, or reports the vendored copy as a different version.

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
created: 2026-08-11T21:28:24Z
last_update: 2026-08-11T21:28:24Z
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

# T-435: Pre-push audit gate may fail open under lock contention: verify AEF OBS-221 against this tree

## Context

AEF reported this as a defect in *their* tree (DM 538 §5, their OBS-221) with the
addendum "if your tree vendored that hook, it has it". A peer's report about a peer's
tree is a hypothesis about mine. Driven here rather than agreed with.

## Verdict: REPRODUCED

**`tools/_t435-lock-contention-probe.sh` — 4/4, exit 0** (PASS means the defect is
present; the probe says so in its own output, since a probe whose healthy and broken
states print the same word is worth nothing).

### The two ends

| | file | line | behaviour |
|---|---|---|---|
| producer | `.agentic-framework/agents/audit/audit.sh` | 329 | `exit 0` when `flock -n` fails |
| producer | same, no-flock fallback | 353 | `exit 0` when the lock file exists |
| consumer | `.agentic-framework/agents/git/lib/hooks.sh` | 844 | generates `.git/hooks/pre-push`, which blocks **only** on `-eq 2` |

`0` therefore carries two meanings — *19 checks ran and none failed* and *no check ran at
all* — and the consumer has no channel by which to separate them.

### Driven, both directions

Real installed hook, real stdin, **no push performed**:

```
lock held  → HOOK EXIT 0   "=== Pre-Push Audit Check ===" / "Another audit is already running — exiting"
no lock    → HOOK EXIT 0   Pass: 19  Warn: 3  Fail: 0     "WARNING: Audit has warnings (push allowed)"
```

Same verdict, 19 checks apart. The reciprocal matters as much: driven against a stub
audit in a scratch repo, the **same hook** returns `1` / "Push blocked" on exit 2, and
`0` on exit 0 and exit 1. So the gate is live and capable of refusing — leg A is about
lock contention specifically, not about a gate that blocks nothing.

### What is NOT claimed

That any push here was actually let through with a real failure behind it. I did not look
and did not find one. The claim is that the gate **cannot tell**, which is smaller and
sufficient — the same bound AEF drew on their own version-decidability finding.

### The producer's `0` is not simply wrong

`audit.sh:324` documents it: cron mode (`QUIET=true`) exits 0 silently to preserve
zero-zombie behaviour. That is a deliberate choice for a caller that must not alarm. The
defect is that a *second* caller with the opposite need reads the same code. Any remedy
has to keep cron quiet, which rules out "just exit non-zero".

### Remedy — PROPOSED, not applied

Both files are vendored (`.agentic-framework/`), so G-008 applies and no fix is committed
here. Proposal handed to AEF: contention exits a distinct code (`75`/`EX_TEMPFAIL`
suggested) in *all* modes; cron call sites map `75 → 0` where silence is wanted; the
pre-push consumer treats `75` as *could-not-evaluate* and refuses rather than passes.
One meaning per code, and the decision about whether "could not evaluate" should block is
a sovereignty question for the operator, not a technical one.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] The claim is DRIVEN, not read. A second audit is started while the first holds the
      lock, and the contending run's exit code is captured from the process — not inferred
      from the branch that appears to produce it. AEF's report is a report about their
      tree; reading my hook and agreeing is the mention-vs-instance error this week has
      already cost three sessions.
- [x] The hook's own consumption of that exit code is established the same way: which
      exit values it treats as PASS, and whether the contention value is among them,
      extracted from the installed `.git/hooks/pre-push` rather than from memory of it.
- [x] The verdict is one of exactly three, stated with its evidence: REPRODUCED (this tree
      has it), NOT PRESENT (with the reason — different vendored version, different lock
      strategy, or the exit code is already distinguished), or CANNOT-ANSWER (with what
      blocked the measurement). "Probably fine" is not a verdict.
- [x] If reproduced, the fix is NOT applied to `.agentic-framework/` under agent
      initiative — that is vendored upstream code and G-008 applies. The finding is
      reported to AEF with the reproduction, and any local remedy is proposed rather
      than committed.
- [x] No push is performed to test this. The gate under examination is the push gate;
      driving it by pushing would put the repository's real remote in the test fixture.
      Contention is simulated against a scratch invocation instead.

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

# Drives the real installed hook under a real held lock, plus the reciprocal proving the
# same hook still blocks on audit exit 2. Its own exit code is the verdict (T-352).
# PASS = the defect is STILL PRESENT. When AEF's fix vendors in this flips to 1, and the
# flip is the close condition — not the green.
bash tools/_t435-lock-contention-probe.sh

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

### 2026-08-11T21:28:24Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-435-pre-push-audit-gate-may-fail-open-under-.md
- **Context:** Initial task creation
