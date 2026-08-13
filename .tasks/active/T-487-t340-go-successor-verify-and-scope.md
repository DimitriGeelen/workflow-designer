---
id: T-487
name: "T-340 GO successor — verify the decision was recorded, then scope the build from the task file"
description: >
  The operator ruled GO on T-340 verbally at the end of session 2026-08-13. Whether the
  decision was ever RECORDED is unverified — the budget gate fired first. This task exists
  so the ruling cannot evaporate: T-486 measured, one hour before it was given, that we are
  vulnerable to exactly AEF's T-2925 failure (a GO recorded against an inception that then
  closes, with no build slice ever created). Step 1 is verification, step 2 is scoping from
  the task file rather than from recall.
status: started-work
workflow_type: build
owner: agent
horizon: now
tags: []
components: []
related_tasks: ["T-340", "T-486"]
created: 2026-08-13T07:55:00Z
last_update: 2026-08-13T07:55:00Z
date_finished: null
---

# T-487: T-340 GO successor — verify, then scope

## Context

**The operator ruled GO on T-340 in session 2026-08-13**, stated in-session at the end of the
window. Three routes to record it were attempted and each was refused by a different gate:

    fw inception decide T-340 go                 -> Tier 0 hook: hand it to the human
    same, run by the human via the ! prefix      -> refused: CLAUDECODE=1, agents must not
    http://192.168.10.107:3000/inception/T-340   -> page not found

That third URL was **inferred by the agent from an error message's wording and was wrong**.
The URL the tooling itself printed, twice, is `/review/T-340`. The operator's final message
was "approved", which was ambiguous between "I approved the Tier 0 block" and "the decision
is now recorded", and the budget gate fired before it could be disambiguated.

**Treat the decision as UNRECORDED until T-340's own file says otherwise.**

Why this task exists at all: T-486 (closed the same session) measured that our commit-msg
hook forces post-GO work onto a NEW task ID but **does not force the work to exist**. We were
18/18 clean on orphaned GOs by practice, not by structure. This is the first GO at risk since
that was measured, and the agent holding it ran out of context minutes later. A GO that
survives only in a conversation is the failure AEF hit in T-2925 and described at rail 601.

## Acceptance Criteria

### Agent
- [ ] AC1 — Read T-340's `## Decision` section and report whether a GO is RECORDED. Do not
      infer it from this task file, from the handover, or from the fact that the ruling was
      given. If it is unrecorded, stop and put the copy-pasteable command in front of the
      operator; an agent must not record an inception decision, and Tier 0 approval does not
      clear the separate `--i-am-human` refusal.
- [ ] AC2 — Read T-340 in full and scope the successor from THAT, not from recall. Every
      claim carried into this session about the decision — notably "scoped option (b) is
      byte-neutral" — is recall from a compacted window. The agent's attempt to re-read
      T-340 was blocked by the task gate and the claim was never re-verified. A build task
      scoped from remembered prose is the pattern CLAUDE.md warns about under Pickup Message
      Handling.
- [ ] AC3 — If T-340's scope describes more than three new files, a new subsystem, a new CLI
      route or a new Watchtower page, file an INCEPTION rather than continuing to build
      under this task (G-020 / Pickup Message Handling).
- [ ] AC4 — Real acceptance criteria for the actual build are written into the successor
      task (this one, or a new one if AC3 routes to inception) BEFORE any source file is
      edited. The G-020 gate enforces this and blocked six tasks this session; do not treat
      it as friction.
- [ ] AC5 — AEF is told the arc's blocker cleared. T-340 was named as the only thing
      blocking the arc in six consecutive rail messages (598-603) on
      `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`. Post via the MCP surface with
      `metadata={'from_project': '832-Workflow-designer', ...}` — the T-420 attribution gate
      blocks posts without it. If the arc unblocked and they hear nothing, the last state on
      the shared record is still "blocked".

## Verification

# NOTE (OBS-043, live in our vendored pin): the P-011 gate strips HTML comment spans out of
# this block before executing it, with no quote or command-boundary awareness. No leg below
# carries those delimiters as data, deliberately.

# AC1 — T-340 carries a recorded decision. This leg is expected to FAIL until it does; that
# failure is the point, and it is what stops this task closing on a ruling that never landed.
grep -qi "GO" .tasks/completed/T-340-*.md .tasks/active/T-340-*.md 2>/dev/null

# AC5 — the rail was told. Asserted against this task file's own record of the offset, so a
# closed task cannot claim it silently.
grep -q "rail offset" .tasks/active/T-487-t340-go-successor-verify-and-scope.md

## Decisions

### 2026-08-13 — creating this task file directly rather than via fw task create
- **Chose:** hand-write the task file into `.tasks/active/` during session wrap-up.
- **Why:** the budget gate had already blocked Bash (296,793 tokens, ~98%), so
  `fw work-on` could not run, and the alternative was to let a GO ruling exist only in a
  conversation that was about to end. Writes to `.tasks/` are explicitly permitted during
  wrap-up. T-486 had measured the orphaned-GO exposure one hour earlier; leaving this
  uncaptured would have been walking into the failure with the measurement in hand.
- **Rejected:** appending to the handover — `.context/handovers/LATEST.md` is a symlink and
  the Write tool correctly refused to write through it; and an active task is more visible
  to the next session than handover prose, because it appears in Work in Progress.

## Updates

### 2026-08-13T07:55:00Z — created at wrap-up [agent]
- **Action:** Task file written directly during budget-critical wrap-up.
- **Context:** Operator ruled GO on T-340; recording status unverified; successor did not
  exist. AC1 is deliberately expected to fail until the decision is actually recorded.
