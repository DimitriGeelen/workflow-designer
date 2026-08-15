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
status: work-completed
workflow_type: build
owner: agent
horizon: null
tags: []
components: []
related_tasks: ["T-340", "T-486"]
created: 2026-08-13T07:55:00Z
last_update: 2026-08-14T20:24:40Z
date_finished: 2026-08-14T20:24:40Z
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
- [x] AC1 — **RECORDED.** `.context/project/decisions.yaml:1547` carries `PD-200`,
      `task: T-340`, `date: 2026-08-14`, `decision: "T-340 DI repair semantics: b"`. Read from
      the register, not inferred from this file, the handover or recall. See the 2026-08-14
      update below for the one thing that is *not* settled by it.
      Read T-340's `## Decision` section and report whether a GO is RECORDED. Do not
      infer it from this task file, from the handover, or from the fact that the ruling was
      given. If it is unrecorded, stop and put the copy-pasteable command in front of the
      operator; an agent must not record an inception decision, and Tier 0 approval does not
      clear the separate `--i-am-human` refusal.
- [x] AC2 — Done 2026-08-13 (update below) and the scoping proved out: the carried claim
      "scoped (b) is byte-neutral" was re-derived from the file (BOTH=0), and the shipped
      change at `fc7f7263` changed zero bytes for the 126 `aef:position`-only documents.
      Read T-340 in full and scope the successor from THAT, not from recall. Every
      claim carried into this session about the decision — notably "scoped option (b) is
      byte-neutral" — is recall from a compacted window. The agent's attempt to re-read
      T-340 was blocked by the task gate and the claim was never re-verified. A build task
      scoped from remembered prose is the pattern CLAUDE.md warns about under Pickup Message
      Handling.
- [x] AC3 — Build, not inception: two files edited, zero new. Confirmed by what actually
      shipped, not only by the estimate.
      If T-340's scope describes more than three new files, a new subsystem, a new CLI
      route or a new Watchtower page, file an INCEPTION rather than continuing to build
      under this task (G-020 / Pickup Message Handling).
- [x] AC4 — Satisfied by T-340's own pre-existing Agent ACs; nothing was reworded to fit the
      work. All three are now ticked with measurements attached.
      Real acceptance criteria for the actual build are written into the successor
      task (this one, or a new one if AC3 routes to inception) BEFORE any source file is
      edited. The G-020 gate enforces this and blocked six tasks this session; do not treat
      it as friction.
- [x] AC5 — Told at **rail offset 626** on `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`, posted via
      the MCP surface with `from_project` attribution. §1 is the blocker-cleared notice: ruling
      (b)/PD-200, shipped `fc7f7263`, import indexes `bpmndi:BPMNShape` → `dc:Bounds`, export
      re-emits conditionally, and the byte-neutrality stated as a measurement (145 files,
      BOTH=0) rather than a reassurance. This is the post that rail 604 recorded as still owed.
      **They have not acknowledged it** — their last genuine message on that topic is offset
      612 and eleven of mine are unanswered — but AC5 is "AEF is told", not "AEF replied".
      **CORRECTION 2026-08-14, after this task closed (T-507 and the exchange after it):
      "offset 612" is WRONG and so is the identification behind it.** AEF's last genuine
      content on that topic is **611**; 612/617/621/622 are byte-identical replays posted by
      `bdd184bd89f318e4`, a third principal that is neither of us. I had that fingerprint
      recorded as AEF, and six messages of mine rested on the misidentification. AC5's
      substance is unaffected — the post was made, at offset 626, and "told" does not depend
      on who was silent — but the sentence supporting it named the wrong subject, which is the
      class this whole window has been about, so it is corrected in place rather than left to
      read as measured. They have since confirmed the rail is unreadable from their side for a
      different reason again: both endpoints rotated onto one shared host key while the topic
      name froze.
      AEF is told the arc's blocker cleared. T-340 was named as the only thing
      blocking the arc in six consecutive rail messages (598-603) on
      `dm:0e7ee6cad65137fc:6a646ce8b1bc6560`. Post via the MCP surface with
      `metadata={'from_project': '832-Workflow-designer', ...}` — the T-420 attribution gate
      blocks posts without it. If the arc unblocked and they hear nothing, the last state on
      the shared record is still "blocked".

## Verification

# NOTE (OBS-043, live in our vendored pin): the P-011 gate strips HTML comment spans out of
# this block before executing it, with no quote or command-boundary awareness. No leg below
# carries those delimiters as data, deliberately.

# AC1 — T-340 carries a recorded decision, asserted against the REGISTER, which is where a
# ruling has to land to be visible to anything.
#
# REPLACED 2026-08-14, and the reason is the point of the leg. It used to read:
#     grep -qi "GO" .tasks/completed/T-340-*.md .tasks/active/T-340-*.md 2>/dev/null
# Case-insensitive "GO" matches "go", "gone", "going", "ago" and "algorithm". T-340's file
# contained all of those on 2026-08-13, the day this task's own verdict was NOT RECORDED —
# so the leg written to stop the task closing on a ruling that never landed would have
# passed on exactly that ruling. It was not a weak check, it was a check of nothing, and it
# was pointed at the task file rather than at the register the ruling has to reach.
grep -q "id: PD-200" .context/project/decisions.yaml
grep -A4 "id: PD-200" .context/project/decisions.yaml | grep -q "task: T-340"

# AC5 — the rail was told, asserted against the specific offset. The previous form grepped
# for the bare string "rail offset", which was already present from the 604 entry before 626
# existed: a leg that was green while the thing it certifies was still owed.
grep -q "rail offset 626" .tasks/active/T-487-t340-go-successor-verify-and-scope.md

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

### 2026-08-14 — AC1 re-answered: RECORDED. And the ruling landed in a task nobody can reach [agent]

**AC1 flips.** Yesterday's verdict was NOT RECORDED and it was correct on the day. It is now
recorded, by the mechanism this task identified as the right one after three sessions of
gate refusals sent everyone at `fw inception decide`:

    .context/project/decisions.yaml:1547   PD-200   task: T-340   date: 2026-08-14
                                           "T-340 DI repair semantics: b"

The build shipped at `fc7f7263`; T-340's three Agent ACs are ticked with measurements
(24/24 DI injected and survived, bridge 75/0). Read from the register, per AC1's own
instruction not to infer it from this file or from recall.

**What is NOT settled, and it is the reason this update exists rather than a tick alone.**
T-340 right now:

    status: started-work        owner: agent        Agent ACs 3/3 ticked
    Human AC  [REVIEW] Repair semantics for standard BPMN DI on import   — UNTICKED

Partial-complete is supposed to move a task to `owner: human` once the Agent ACs pass, so it
surfaces in the operator's queue. T-340 did not make that transition — it is agent-owned with
nothing left for an agent to do, and human-gated with no marker saying so. `fw task verify`
lists tasks by their Human ACs; a task the operator never sees is not a task they can close.

**And the AC's own Expected clause is already satisfied.** It reads *"one option recorded"*.
One option is recorded: PD-200, option (b), with the byte-neutrality rationale attached. So
the evidence for closing it exists and I am stating it here rather than acting on it — the
checkbox is the operator's mark and ticking it is not delegated, no matter how strong the
evidence is. This is a suggestion with evidence, which is the only shape the rule permits.

**Provenance limit, stated because I cannot close it.** PD-200's file write rides in commit
`f4adabc4`, which is agent-authored (T-500). That establishes when the line entered the tree,
not who ran `fw context add-decision`. The ruling itself was given in-session on 2026-08-14
and I reported it to AEF at rail 626 as the operator's. I am recording the ambiguity rather
than resolving it by assertion — the unticked `[REVIEW]` box is the operator's own mark and
it is the one piece of this that is unambiguous.

**Same class as the defer review run earlier today.** T-209 and T-353 carry DEFER rulings as
prose that no instrument can see; T-340 carries a recorded ruling in a task no queue lists.
Both are PL-145 — a ruling is only as good as the surface that shows it — and this one is the
inverted case: the ruling was filed correctly and the *task* went dark instead.

### 2026-08-13T08:20:00Z — AC1 answered: NOT RECORDED, and the command was wrong [agent]

**Verdict: the GO is NOT RECORDED.** Four independent checks, all negative:

    workflow_type                      build          <- NOT inception
    fw inception status                T-340 absent   <- 12 active / 24 completed, not among them
    ## Decision section (line 550)     empty template boilerplate only
    decisions.yaml entries for T-340   0
    Human AC [REVIEW] checkbox         unticked

**The finding that matters more than the verdict: `fw inception decide T-340 go` was never
the right command.** T-340 is a BUILD task. The ruling it carries is a Human AC
(`[REVIEW] Repair semantics for standard BPMN DI on import`), not an inception decision.
Had the command run it would have written an inception decision onto a task that is not an
inception.

**Why three sessions of gate refusals never revealed that.** Two gates refused in series —
the Tier 0 hook (destructive-command class) and the command's own `$CLAUDECODE=1` check
(T-679/T-1259). Both fire on the command NAME, before any validation of the task's type. So
both refused for reasons entirely unrelated to the actual defect in the request, and the
conclusion I drew from them — "this is sovereignty, hand it to the operator" — was the wrong
lesson from a correct block. The operator then ran the same wrong command themselves and got
the same uninformative refusal. Then I inferred a `/inception/T-340` URL from the error
text, which 404'd because there is no inception to review.

**This is the T-485 class one turn further on.** T-485: a probe returning the RIGHT answer
for a broken reason is the only kind nothing downstream can catch. Here: a gate producing the
RIGHT behaviour (block) for a reason unrelated to the fault. Two refusals in a row read as
strong confirmation that the route was sovereignty-blocked, when the route did not exist.
**Agreement between two instruments that share a blind spot is not corroboration.**

**The correct mechanism is stated in T-340's own AC, step 4** — and has been since the AC was
written:

    fw context add-decision "T-340 DI repair semantics: <a|a-prime|b|c>" --task T-340 --rationale "<why>"

Not agent-gated. Not Tier 0. Left to the operator anyway: the AC's Expected clause is *"one
option recorded"*, so recording it IS satisfying the Human AC, and an agent must not do that
on the human's behalf.

**AC2 — scoped from the file, not from recall.** The carried claim *"scoped option (b) is
byte-neutral"* is CONFIRMED by T-340's `## Recommendation`, re-measured 2026-08-12 over 144
tracked `.bpmn` files: 125 carry `aef:position`, 10 carry DI, **BOTH = 0**, 9 neither. The
disjointness is load-bearing (the precedence rule can never fire on our corpus) and has now
survived two intakes — 126 → 142 → 144 files. Scope:

    on import   aef:position  →  else DI  →  else auto-layout
    on export   emit DI only when the input carried it

**AC3 — build, not inception.** Two files edited, zero new: `src/aef-workflow-designer.html`
(`parseBpmnXml` src:9595, `buildBpmnXml` src:9439, position resolution src:9742) and
`tools/_t338-input-fidelity-cdp.mjs` (`EXPECTED_DI`). No new subsystem, CLI route or
Watchtower page. **The successor is T-340 itself** — its three Agent ACs are already written
and marked BLOCKED for exactly this ruling. No new task is needed and creating one would
orphan the ACs that already describe the work.

**AC4 note:** T-340's Agent ACs are real and pre-existing, so the G-020 requirement is
already met by the file; nothing is to be reworded.

### 2026-08-13T08:22:00Z — AEF told, at rail offset 604 [agent]

Posted to `dm:0e7ee6cad65137fc:6a646ce8b1bc6560` at **rail offset 604**.

**Deliberately NOT the post AC5 as written called for.** AC5 says "AEF is told the arc's
blocker cleared" — it has not cleared. Sending that would put a false state on the shared
record, which is the failure AC5 exists to prevent, inverted. What was sent instead:

1. **OBS-047 as an UPSTREAM finding.** `lib/inception.sh` and the `$CLAUDECODE=1` refusal are
   AEF code vendored into us at our pin, so their own agents hit this the same way. Not fixed
   in our tree — their file, and a gate behaviour change is design, not the defect class G-008
   covers.
2. **The precise arc state**: ruling GIVEN, NOT RECORDED, mechanism in front of the operator.
3. **The measurement they can act on**: BOTH = 0 over 144 files, so scoped (b) needs zero
   coordination from them — no re-pin, no seam event.
4. **Re-raised the one open question** (both-carriers precedence, first asked at 413/415,
   still unanswered), flagged non-blocking.

The "blocker cleared" post remains owed and is what closes AC5, once the ruling is recorded.

### 2026-08-13T07:55:00Z — created at wrap-up [agent]
- **Action:** Task file written directly during budget-critical wrap-up.
- **Context:** Operator ruled GO on T-340; recording status unverified; successor did not
  exist. AC1 is deliberately expected to fail until the decision is actually recorded.

## Reviewer Verdict (v1.5)

- **Scan ID:** R-0f32bd0e
- **Timestamp:** 2026-08-14T20:24:41Z
- **Catalogue:** v1.3-seed
- **Overall:** CONCERN
- **Needs Human:** no
- **Findings:** 1

**Verification-level findings:**

  1. **l387-sigpipe-risk** (partial, heuristic) @ Verification:line 16
     - evidence: `grep -A4 "id: PD-200" .context/project/decisions.yaml | grep -q "task: T-340"`

### 2026-08-14T20:24:40Z — status-update [task-update-agent]
- **Change:** status: started-work → work-completed
