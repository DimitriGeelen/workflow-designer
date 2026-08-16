---
id: T-531
name: "determine the direction of the termlink identity merge on agent-chat-arc: both
  projects now post under one sender_id and AEF asks which end re-keyed"
description: >
  determine the direction of the termlink identity merge on agent-chat-arc: both projects
  now post under one sender_id and AEF asks which end re-keyed

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
created: 2026-08-15T21:53:10Z
last_update: '2026-08-16T12:34:06Z'
date_finished: 2026-08-15T21:59:43Z
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
  - ts: '2026-08-16T12:34:06Z'
    estimator: bvp-estimator-v1-heuristic
    scores:
      D1: 4
      D2: 0
      D3: 2
      D4: 2
      F-RECALL: 0
      F-AUTONOMY: 0
      F3: 0
      F1: 0
      F2: 1
    rationale: D1=4 (body:structural-gate); D2=0 (no-signal); D3=2 
      (body:default-change); D4=2 (body:env-class-handled); F-RECALL=0 
      (no-signal); F-AUTONOMY=0 (no-signal); F3=0 (no-signal); F1=0 (no-signal);
      F2=1 (body/components:component-fabric-incidental)
    rubric_sha: e4a00f38e801
---

# T-531: determine the direction of the termlink identity merge on agent-chat-arc: both projects now post under one sender_id and AEF asks which end re-keyed

## Context

AEF asked (rail 11945) whether my sender_id had always been `d1993c2c3ec44c94`, having observed
theirs move off `bdd184bd89f318e4` mid-session onto mine, and reasoning that the direction would
say which end re-keyed.

## Findings

**1. The direction cannot be determined from the channel, and the reason is itself the finding.**
`termlink_agent_first_post_by` and `termlink_agent_search_by` both filter `msg_type == "post"`.
Every envelope in the entire 832↔AEF arc exchange is `msg_type: "note"`. Measured:
`agent_search_by(sender_id=d1993c2c3ec44c94, query="832-Workflow-designer")` returns **count 0**,
against 20 envelopes that `channel_search` finds for the same string over offsets 11879–11944.
The channel's own attribution tooling is blind to the conversation being held on it.

**2. The question is probably malformed: this is not a two-party merge.** The earliest
`msg_type=post` envelope under `d1993c2c3ec44c94` is offset **11898**, and it is neither of ours
— it is `pen-agent (email-archive, cwd /opt/050-email-archive)`. That predates AEF's observed
20:35–21:03 switch window. At least three projects share the fingerprint, so "which of us
re-keyed onto the other" presumes a two-party event that the record does not support.
`bdd184bd89f318e4` returns `found: false` for `first_post_by` for the same msg_type reason, not
because it never posted.

**3. The framework already documents this exact condition, and the mitigation is designed but
unpopulated.** `agent-conversation-status.sh:87-94` and `agent-conversation-list.sh:115-118`
both carry, verbatim:

    # T-1855 / PL-191 — sender identity is multi-source on shared hosts.
    #   1. .metadata.agent_id  (explicit agent identity — /be-reachable convention)
    #   2. .metadata._from     (vendored-arc heartbeat convention, T-1438)
    #   3. .sender_id          (envelope fingerprint — collapses co-resident agents)
    # T-1693 forward-compat: agent-send/respond do not write metadata.agent_id
    # today (deferred to T-1693), so chain falls through to .sender_id

So the readers already prefer an explicit identity and fall through to the fingerprint only
because producers do not write `metadata.agent_id` yet. The comment names the consequence —
"collapses co-resident agents" — as a known deferred condition, not a surprise.

**4. Blast radius on this tree: nil today, by accident rather than design.** Four scripts read
the arc (`agent-conversation-status.sh`, `agent-conversation-list.sh`, `agent-chat-arc-recent.sh`,
`chat-arc-broadcast.sh`), all under `.agentic-framework/lib/templates/scripts/`, and a search for
callers outside that directory returns **none**. Nothing here currently draws a wrong conclusion
from the merged fingerprint because nothing here draws any conclusion from it.

**Not fixed.** Identity/keying is operator territory; OBS-251 already carries it as urgent.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [x] **The question is answered from the CHANNEL's own record, not from local identity state.**
      AEF observed (rail 11945) that `d1993c2c3ec44c94` now carries posts from both projects, and
      that theirs moved off `bdd184bd89f318e4` mid-session between 20:35 and 21:03. The
      discriminating evidence is the sender_id attached to MY historical posts over time. Probing
      termlink identity files is out of bounds here — `TERMLINK_IDENTITY_FILE` AUTO-CREATES a
      keypair when the path does not exist, so any guess-and-read MINTS rather than reads.
- [x] **The direction is stated, or the inability to determine it is stated.** "Both projects
      share a sender_id" is already established by AEF; this task's only new contribution is
      WHICH end moved. An answer of "cannot tell from the channel" is a valid result and is
      reported as such rather than dressed up.
- [x] **The blast radius is stated for readers, not just the cause.** Any consumer keying on
      sender_id merges two agents; any consumer keying on exact-match `from_project` splits one
      agent in two (AEF observed both casings of their own name). Whether anything on THIS tree
      reads the arc programmatically is checked and reported.
- [x] **Nothing is fixed under agent initiative.** Identity/keying is operator territory and
      OBS-251 already carries it as urgent. This task measures and reports; it does not edit
      identity config, `.framework.yaml`, or hook settings, and does not act on a peer's
      suggestion as if it were authorisation.

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

# The quoted framework comment is the load-bearing evidence for finding 3; if it moves, the
# finding needs re-checking rather than silently going stale.
grep -q "collapses co-resident agents" .agentic-framework/lib/templates/scripts/agent-conversation-status.sh
grep -q "deferred to T-1693" .agentic-framework/lib/templates/scripts/agent-conversation-status.sh

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

### 2026-08-15T21:53:10Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-531-determine-the-direction-of-the-termlink-.md
- **Context:** Initial task creation

## Reviewer Verdict (v1.5)

- **Scan ID:** R-978dec9e
- **Timestamp:** 2026-08-15T21:59:44Z
- **Catalogue:** v1.3-seed
- **Overall:** PASS
- **Needs Human:** no
- **Findings:** none

### 2026-08-15T21:59:43Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
