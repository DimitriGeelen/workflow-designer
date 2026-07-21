---
id: T-222
name: "Investigate: Tier-0 approvals not surfacing in Watchtower /approvals page"
description: >
  Investigate: Tier-0 approvals not surfacing in Watchtower /approvals page

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
created: 2026-07-21T12:33:59Z
last_update: 2026-07-21T12:40:14Z
date_finished: 2026-07-21T12:40:14Z
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

# T-222: Investigate: Tier-0 approvals not surfacing in Watchtower /approvals page

## Context

Operator reports Tier-0 approval requests are NOT surfacing in the Watchtower `/approvals` page.
During this session, agent Tier-0 commands (`fw inception decide …`) were BLOCKED by check-tier0,
and a `.context/working/.tier0-approval` grant file (`<hash> <expiry>`) appeared, yet the operator
sees nothing to approve. Investigate the Tier-0 request→surface→approve→grant flow end-to-end to
find where a blocked command's approval request fails to reach the approvals page.

## Findings

**Tier-0 flow (traced, `check-tier0.sh`):** on block (exit 2) the hook writes a pending request to
BOTH `.context/working/.tier0-approval.pending` (lines 420-421) and a human-readable
`.context/approvals/pending-<hash12>.yaml` (lines 423-439) — the latter is what the Watchtower
`/approvals` page reads (T-611). Human approval (Watchtower or `fw tier0 approve`) writes a grant
`.tier0-approval` (`<hash> <epoch>`) + a `resolved-<hash12>.yaml`; the hook consumes the grant on the
next matching attempt (lines 216-267, 300s TTL) or a Watchtower `resolved-…approved` (lines 269-362).

**Finding 1 — reported symptom is NOT a framework bug (expected behavior + operator confusion):**
The page works — `resolved-97cb4290241c.yaml` shows `status: approved, mechanism: watchtower,
responded_at 2026-07-21T12:18:40Z`. But hash `97cb4290` was the agent's `fw inception decide **--help**`
DIAGNOSTIC (see its `command_preview`), a no-op — the operator approved that, not the GO. Nothing
surfaces now because no GO request was ever submitted (the agent asked the human to run GO directly,
so never triggered a block that would write a `pending-<GO>.yaml`). Root cause of confusion: (a) agent
ran `fw inception decide --help` which trips check-tier0 (regex `fw\s+inception\s+decide` matches ANY
subcommand incl. --help, line 156) → polluted the queue with a no-op request; (b) truncated
`command_preview` made the `--help` hard to distinguish from a real GO.

**Finding 2 — real bug (fixed):** `.context/working/.gitignore` pattern was `tier0-approval` (no leading
dot) → never matched the actual `.tier0-approval` token → transient Tier-0 grants leaked into git
(agent's `git add -A .context/` committed one). Fixed to `.tier0-approval*` (globs `.pending`/`.consumed`).

## Acceptance Criteria

### Agent
- [x] Traced the Tier-0 flow: check-tier0.sh writes `.tier0-approval.pending` + `.context/approvals/pending-<hash>.yaml`; `/approvals` reads the latter; grants land in `.tier0-approval` + `resolved-<hash>.yaml`
- [x] Root cause identified: symptom is expected (page works — proven by resolved-97cb4290 approved via watchtower); nothing pending because the only request was the agent's `--help` no-op (already resolved) and no GO request was ever submitted
- [x] Classified: reported symptom = expected-behavior/operator-confusion (not a bug); incidental real bug found = gitignore pattern typo (`.context/working/.gitignore:6`)
- [x] Bug fixed (gitignore `.tier0-approval*`); correct operator path to record T-218 GO documented (run directly, or agent surfaces the real GO request for Watchtower approval)

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

# PL-043: each line is its own shell under set -u — self-contained
grep -q '.tier0-approval\*' .context/working/.gitignore
git check-ignore -q .context/working/.tier0-approval

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

### 2026-07-21T12:33:59Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-222-investigate-tier-0-approvals-not-surfaci.md
- **Context:** Initial task creation

### 2026-07-21T12:40:14Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
