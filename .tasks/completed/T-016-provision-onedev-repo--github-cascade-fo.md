---
id: T-016
name: "Provision OneDev repo + GitHub cascade for Workflow Designer via ring20-management"
description: >
  Provision OneDev repo + GitHub cascade for Workflow Designer via ring20-management

status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: [infra, onedev, coordination]
components: []
related_tasks: []
# arc_id:                         # T-1849: optional — slug (e.g. "arc-grooming") OR arc-NNN (e.g. "arc-005")
#                                 # When set, must resolve to .context/arcs/<id>.yaml; PreToolUse hook
#                                 # (check-arc-id) blocks save under agent control if it doesn't resolve.
#                                 # Empty/missing → unassigned (allowed). See CLAUDE.md §Task System.
created: 2026-07-02T17:00:16Z
last_update: 2026-07-10T09:54:24Z
date_finished: 2026-07-10T09:54:24Z
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

# T-016: Provision OneDev repo + GitHub cascade for Workflow Designer via ring20-management

## Context

Get this repo onto OneDev with the OneDev→GitHub cascade mirror, matching the
termlink and agentic-engineering-framework setup. Requires ring20-management-agent
(`9219671e28054458`, OneDev admin reach — same party as the T-1695 OneDev→GitHub
mirror and T-209 deploy-key threads). Reference pattern (from sibling
`.git/config`):
- origin: `https://<token>@onedev.docker.ring20.geelenandcompany.com/<repo>`
- github: `https://github.com/DimitriGeelen/<repo>.git`
- cascade = server-side OneDev→GitHub mirror job (ring20-managed).

**Security:** never paste the push token into termlink or any tracked file;
credentials arrive via ring20's secure channel (deploy-key-install style).

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] Provisioning request sent to ring20-management-agent (`9219671e28054458`) — sent (DM T-016 offset 102); GRANTED at offset 103 (OneDev project `workflow-designer` id 45, LIVE)
- [x] `origin` (OneDev, SSH `ssh://git@192.168.10.201:6611/workflow-designer`) + `github` remotes added; no token in origin URL (SSH key auth), no token committed
- [x] `fw audit` run before push (Pass 78 / Warn 2 / Fail 0; a pre-push hook audit also passed 12/0/0). Working tree note: push publishes committed history only — the 1171 in-flight uncommitted files (T-014/T-015 session) are excluded and untouched
- [x] `master` pushed to OneDev origin (HEAD c958686, full history); `.onedev-buildspec.yml` mirror job committed + pushed (BranchUpdateTrigger fired)
- [x] **DONE — cascade LIVE + verified (2026-07-10):** ring20 set the `github-push-token` job-secret on OneDev project 45 and fired "Push to GitHub Mirror" #184 = SUCCESSFUL (DM thread T-016, offset 114). Independently verified from .201: `git ls-remote` returns the SAME HEAD on both remotes — origin (OneDev `ssh://git@192.168.10.201:6611/workflow-designer`) `refs/heads/master` = `00e9cb3` AND `github.com/DimitriGeelen/workflow-designer` `refs/heads/master` = `00e9cb3`. Auto-mirror proven: the cascade advanced `ccda05b`→`00e9cb3` with zero manual steps (BranchUpdateTrigger fires per push). Backed by estate-wide GITHUB_TOKEN for now; swap to fine-grained WD_GITHUB_PUSH_TOKEN is a future no-op re-verify. Confirmation posted to ring20 at offset 120.

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

# T-016 cascade proof: OneDev origin HEAD must equal GitHub mirror HEAD (auto-mirror live).
# Capture-then-compare (no grep -q SIGPIPE); timeout guards a slow/unreachable GitHub.
onedev=$(git ls-remote origin -h refs/heads/master 2>/dev/null | awk '{print $1}'); github=$(timeout 30 git ls-remote https://github.com/DimitriGeelen/workflow-designer.git -h refs/heads/master 2>/dev/null | awk '{print $1}'); test -n "$onedev" && test "$onedev" = "$github"

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

### 2026-07-09 — GitHub cascade: light it up (reverse the 2026-07-02 deferral)
- **Chose:** OneDev is the primary remote; wire the OneDev→GitHub PushRepository mirror so pushes cascade to `github.com/DimitriGeelen/workflow-designer`. Keep the committed `.onedev-buildspec.yml` mirror job as-is; request ring20/operator set the `github-push-token` secret on OneDev project 45.
- **Why:** Operator directive 2026-07-09 ("I want OneDev to be the primary remote that cascades to GitHub"). Matches the termlink / agentic-engineering-framework sibling posture.
- **Rejected:** (a) Leave deferred / OneDev-only (card-redirect posture) — was ring20's 2026-07-02 recommendation, now overridden by operator. (b) Disable the mirror job to keep OneDev builds green — no longer wanted; the job SHOULD run and go green once the secret is set.

## Decision

<!-- Filled at completion of inception tasks via:
     fw inception decide T-XXX go|no-go|defer --rationale "..."

     For non-inception tasks this section is ignored. Kept in template
     so `fw inception decide` (lib/inception.sh) finds the anchor heading
     without auto-creating; T-1832 added auto-create as fallback for
     legacy tasks lacking this section. -->

## Updates

### 2026-07-02T17:00:16Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-016-provision-onedev-repo--github-cascade-fo.md
- **Context:** Initial task creation

### 2026-07-10T09:54:24Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
