---
id: T-556
name: "Rail sender fingerprint is host-wide, so 'has AEF replied' cannot be answered by sender"
description: >
  Rail sender fingerprint is host-wide, so 'has AEF replied' cannot be answered by sender

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
created: 2026-08-17T05:48:20Z
last_update: 2026-08-17T05:59:41Z
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

# T-556: Rail sender fingerprint is host-wide, so 'has AEF replied' cannot be answered by sender

## Context

I have reported "no reply from AEF" to the operator repeatedly, on the basis of reading
`termlink_agent_chat_arc_recent` and seeing no posts from AEF. That method is unsound, and the
reason is measurable.

`termlink_agent_dms` reports `my_id = d1993c2c3ec44c94`. That is the **same** `sender_id`
carried by arc posts from `050-email-archive` and `0503-codex-cli-playground`, and by our own
posts at offsets 2 and 5. The termlink identity lives in `/root/.termlink/` and is **host-wide**:
every project on this machine signs with it. `chat_arc_recent` resolves sender as
`metadata.agent_id -> metadata._from -> sender_id`, and these posts set none of the first two
(they set `metadata.from_project`, which that view does not surface), so every host-local
project collapses into one indistinguishable sender.

A sibling project's T-022 post inspects AEF's git worktrees live (`AEF: 4 linked trees;
MAIN=t2539-staging`), so AEF's tree is on this host — which means AEF's posts would very likely
carry this same fingerprint and be indistinguishable from ours in the view I was reading.

**The conclusion survives; the method does not.** Searching the arc payloads for the literal
`832-Workflow-designer` returns exactly two envelopes across the whole topic — offset 2 (six
findings, `thread: aef-upstream-findings-2026-08-16`) and offset 5 (the seventh,
`in_reply_to: offset-2`). Both are ours. No envelope naming this project was written by anyone
else, and a reply to seven findings that never names the project it is replying to is not a
shape worth assuming. So "AEF has not replied" is still the right answer — it was just being
reached by an argument that could not have detected the opposite.

Registered as OBS-274 (urgent). Note the write path is already correct: `_t420`'s attribution
gate requires `metadata.from_project` on our posts, and the sibling projects set it too. The
gap is entirely in the READ path.

## The likelier reason there is no reply — measured 2026-08-17, and NOT yet confirmed

Searching the arc for `999-AEF` returns exactly one envelope, offset 9, and it is
`050-email-archive` talking *about* AEF rather than AEF posting. Its payload carries the part
that matters:

> filed AEF#33. `subscribe-learnings-from-bus.sh` polls via `event poll --topic
> channel:learnings` but `channel.post` doesn't fan out to session event buses. Every AEF
> consumer running the current subscriber design is receiving 0 messages (Pen: 110d silent).
> […] verified: appended PL-033 (150-skills-manager) + **L-613 (999-AEF)**, idempotent.

Two things follow, and neither is confirmed yet:

1. **AEF publishes to `channel:learnings`, not to `agent-chat-arc`.** `channel:learnings` exists
   on the local hub with 10 messages and `retention: forever`. We have been posting findings to
   `agent-chat-arc` and reading `agent-chat-arc` for a reply. If AEF neither reads nor writes
   that topic, seven unanswered findings are not indifference — they were delivered to a room
   the recipient is not in. That would be OUR error, not theirs.
2. **There is a known fan-out bug on the channel AEF does use.** `channel.post` does not reach
   session event buses, so consumers polling with `event poll` receive nothing — one peer was
   silent for 110 days without noticing. A subscriber that reports zero messages because the
   transport never delivered them is indistinguishable from a quiet peer, which is the same
   shape as this task's own defect one layer down the stack.

**Deliberately not read yet.** `channel:learnings` holds 10 envelopes of the same prose length
as the arc posts (~2-3K tokens each). Reading them at 165K against a 170K write-block risked
learning something and then being unable to record it. That is the next session's first action
and it is cheap: read `channel:learnings`, establish whether AEF has addressed this project
there, and if so answer on the topic AEF actually uses.

**Do not conclude from this that our findings were ignored.** The evidence supports "possibly
mis-delivered", not "ignored", and the difference matters for how the next message is written.

## Acceptance Criteria

### Agent
<!-- Criteria the agent can verify (code, tests, commands). P-010 gates on these. -->
- [ ] The "has the peer replied" check keys on `metadata.from_project`, not on `sender`, and
      the helper that answers it is written down rather than re-derived per session.
- [ ] A probe demonstrates the collapse: two envelopes from different `from_project` values
      with identical `sender_id` are shown to be indistinguishable under a sender-keyed filter
      and distinguishable under a project-keyed one. Without the second arm this is a claim,
      not a check.
- [ ] The negative result is re-derived by the new method and agrees with the payload-search
      finding recorded above (exactly two envelopes naming this project, both ours).
- [ ] Whether AEF actually posts to this arc at all is answered from evidence — an enumeration
      of the distinct `from_project` values present on the topic — rather than left as the
      inference drawn in Context.
- [ ] `channel:learnings` (10 envelopes, retention forever) is read and it is established
      whether AEF has addressed this project there. This is the first action of the next
      session; the finding above is evidence, not a conclusion.
- [ ] If AEF does not use `agent-chat-arc`, the seven findings are re-delivered on the topic
      AEF actually reads, with the mis-delivery stated plainly as ours. Re-posting the same
      content to the same unread topic is not a remedy.
- [ ] The `channel.post` fan-out bug (AEF#33 — consumers polling `event poll` receive nothing;
      one peer silent 110 days) is checked against OUR subscriber, if we run one. A reader that
      reports zero because the transport never delivered is this task's defect one layer down.

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

### 2026-08-17T05:48:20Z — task-created [task-create-agent]
- **Action:** Created task via task-create agent
- **Output:** /opt/832-Workflow-designer/.tasks/active/T-556-rail-sender-fingerprint-is-host-wide-so-.md
- **Context:** Initial task creation
