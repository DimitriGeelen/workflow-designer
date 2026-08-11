---
id: T-436
name: "Observation inbox is effectively write-only: 24 pending, and its contents are being re-derived instead of read"
description: >
  OBS-009 (2026-08-09) already contained the finding T-432 spent a work unit re-deriving. The inbox accumulates but nothing routes from it into work, so a finding filed there is invisible to the next session that needs it. This task triages the pending backlog to disposition (promote / fold into an existing task or concern / dismiss with reason) and reports whether the write-only behaviour is a habit or a missing route.

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
created: 2026-08-11T21:36:14Z
last_update: 2026-08-11T21:55:42Z
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

# T-436: Observation inbox is effectively write-only: 24 pending, and its contents are being re-derived instead of read

## Context

The inbox accumulates and nothing routes from it into work. This task establishes WHY
before clearing anything, because a cleared backlog with the cause intact refills.

## Findings

### 1. The route is not missing — it is built, wired, and silently dead

Three layers were checked by driving them, not by reading them:

| Layer | Carries | Status |
|---|---|---|
| `fw context init` / handover stdout | the COUNT + "Run: `fw note triage`" | works |
| handover doc `## Observation Inbox` | the COUNT | works |
| handover doc, per-observation summaries (`handover.sh:921-935`) | **the CONTENT** | **emits nothing** |
| `fw audit --section observations` (cron 6h, `audit.sh:2668`) | count/urgent/stale | works (fixed upstream by T-2514) |

`handover.sh:925` splits the inbox with `re.split(r'\n  - ', content)`. The real inbox
writes observations as `- id:` at **column 0**, so the pattern matches nothing. Run
verbatim against the live file: **1 block, 0 summary lines** — for 24 pending
observations, every session, since the block was written.

The failure is silent by construction: the enclosing `if [ "$PENDING_OBS" -gt 0 ]` is
true, so the heading, the count and the blank lines all print. The section looks
well-formed and complete. Only the payload is absent.

**AEF already fixed this exact regex one file over.** `audit.sh:2681-2686` carries a
comment naming the defect precisely — "observations are `- id:` at column 0, not
`  - `" — as the rationale for their T-2514 repair. The repair was applied to the
call site that was being debugged, and the identical idiom in `handover.sh` was never
swept. Class: a fix scoped to the instance that hurt, not to the idiom.

**Census of the idiom (3 live sites), and a false alarm avoided:**
- `handover.sh:925` — content listing. **Broken, actively wrong** (24 → 0).
- `handover.sh:386` — urgent count. **Broken, latent.** Always returns 0; no pending
  observation currently carries `urgent: true` (none carries the key at all), so
  nothing is being missed *today* — but the "run triage BEFORE starting new work"
  escalation can never fire. Recorded as latent, not claimed as an active miss.
- `lib/harvest.sh:214` — **correct, not a defect.** It reads `patterns.yaml`, which
  genuinely uses `  - id:` at 2-space indent (verified). Same idiom, different subject.
  Filing this one would have been a false report upstream.

### 2. The re-derivation claim: measured, and it is a rate, not an instance

Denominator 24 pending. "Read" = the OBS id appears in a task/register/tool file
outside `inbox.yaml`, authored by a task **other than** the one that filed it
(self-citation proves authorship, not readership; T-436 excluded as it is this task).

- **7/24 (29%)** read by a later, different task
- **4/24** cited only by their own filing task
- **13/24** never read by anything: OBS-004, 005, 007, 008, 010, 013, 016, 020, 023,
  024, 026, 029, 030

The read rate alone would flatter the inbox. **Read latency falsifies it:**

| OBS | filed | first cited | latency |
|---|---|---|---|
| OBS-003 | 08-08 | 08-08 | 0d |
| OBS-014 | 08-10 | 08-10 | 0d |
| OBS-015 | 08-10 | 08-10 | 0d |
| OBS-017 | 08-10 | 08-11 | 1d |
| OBS-018 | 08-10 | 08-11 | 1d |
| OBS-021 | 08-11 | 08-11 | 0d |
| OBS-027 | 08-11 | 08-11 | 0d |

**No observation has ever been read more than 1 day after it was filed.** The inbox
holds items up to 4 days old, and the oldest entries (OBS-004/005/007/008/010) have
zero reads. So the 7 hits were delivered by session continuity and handover narrative
— the filing session was still running, or its immediate successor was. The inbox has
never once functioned as memory across the gap it exists to bridge, which is exactly
what a dead content-route predicts.

OBS-009 is the specimen: filed 08-09 from T-102, its finding re-derived by T-432 three
days later, and the only task that ever cites it is this one.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] Every pending observation reaches a disposition — promoted to a task, folded into
      an existing task or concern by ID, or dismissed with a reason. Count in equals
      count out; no observation is left pending without being named as deliberately
      deferred and why.
- [ ] The re-derivation claim is measured, not assumed. For each observation, check
      whether its content already exists as a task, concern, or learning. OBS-009 is the
      known instance (its finding was re-derived by T-432 three days later); the question
      is whether it is one instance or a rate, and the answer is a number with a
      denominator.
- [ ] The **route** is established before the backlog is cleared, or clearing it
      accomplishes nothing durable: identify what, if anything, causes a pending
      observation to be read by a session that would benefit from it — handover section,
      audit check, session-start step, or nothing. If the answer is nothing, that is the
      finding, and it is registered as a concern rather than fixed by this task's
      one-time cleanup.
- [ ] No observation is dismissed merely because it is old, nor promoted merely to empty
      the queue. Each disposition cites the specific reason. Batch-dismissal by age is
      the failure mode that produced the backlog's invisibility in the first place.
- [ ] `fw note list` afterwards shows only observations deliberately retained, and the
      before/after counts are both recorded.

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

### 2026-08-11T21:36:14Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-436-observation-inbox-is-effectively-write-o.md
- **Context:** Initial task creation

### 2026-08-11T21:37:04Z — status-update [task-update-agent]
- **Change:** status: started-work → captured
- **Change:** horizon: now → next

### 2026-08-11T21:37:29Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)

### 2026-08-11T21:37:31Z — status-update [task-update-agent]
- **Change:** status: started-work → captured
- **Change:** horizon: now → next

### 2026-08-11T21:55:42Z — status-update [task-update-agent]
- **Change:** status: captured → started-work
- **Change:** horizon: next → now (auto-sync)
