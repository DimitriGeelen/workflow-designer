# procAsFit run — handback

**Requested:** three sequential rounds of the procAsFit autonomous mandate, dispatched over
TermLink, each round fed the previous round's result.
**Rounds dispatched: 0. Rounds executed: 0.** Two independent blockers, both measured before any
unit of work was selected.

---

## Blocker 1 — TermLink cannot deliver the mandate (measured, 3 attempts, 2 mechanisms)

The hub is healthy. `termlink_doctor --strict`: hub running (PID 2647745), responding,
`transport=unix+tcp`, 138 sessions registered and all responding, no orphaned sockets, **0 fail**.
So this is not an outage.

| attempt | call | returned | actually happened |
|---|---|---|---|
| 1 | `spawn` with `["claude","-p","<governance probe>"]` | `ok: true`, `status: "timeout"` | no session (`output` → "session not found"), no `claude` process, no output file |
| 2 | `spawn` with `["bash","-lc","date > /tmp/…; sleep 30"]` | `ok: true`, `status: "timeout"` | file never created, no `sleep` process — **the command never ran**, which rules out the payload |
| 3 | `dispatch` `count=1`, same trivial bash | `ok: true`, `workers_spawned: 1`, `workers_registered: 0`, `events_collected: 0`, `timed_out: false`, `elapsed_secs: 0.0` | no file |

Every probe wrote to an **absolute** path, so no working-directory resolution could hide the
result.

**The shape is the finding.** `ok: true` + `timed_out: false` + `workers_spawned: 1` reads as a
clean dispatch that happened to collect nothing — indistinguishable from workers that ran and had
nothing to report. A caller checking `ok`, or `timed_out`, or `workers_spawned` is told it worked.
Only an independently verified side effect reveals otherwise. **Filed as OBS-387.**

This is the fifth false green of the session, and the first one located in the instrument I was
asked to orchestrate with.

**Not worked around.** The remaining delivery path is PTY inject, which is the known-lossy path and
"not a delivery mechanism". A lossily-delivered governance mandate is worse than none: the
`Governance bindings` section can truncate while `Proceed autonomously` survives. Declined on those
grounds rather than attempted.

**What does work:** `termlink_channel_post` (this run's record posted successfully; the AEF finding
went to `framework:pickup` offset 166 earlier). So the messaging surface is live while the
execution surface silently is not — which is why the failure reads as success.

## Blocker 2 — the mandate's own stop condition is already met

> *Stop at the first of: … context reaches ~300k …*

Measured at the moment of this handback: **429,537 tokens**. The mandate's fallback clause — *"If
TermLink is unavailable … work directly and record why"* — is genuine authorization, and I would
have taken it. But it delivers straight into a stop condition that is already exceeded by ~43%.

So the rule-following answer is not "run it directly anyway with less context than the mandate
permits". It is: **do not start a unit of work; write the handback.** Recording that plainly is the
point, because "I was nearly out of context so I did it anyway, faster" is exactly the pressure the
stop condition exists to remove.

---

## Handback, in the requested format

**Objectives advanced, and by how much, against state at run start:** none by this run. Zero units
of work were selected or executed, so there is no delta to claim. The session's earlier work
(T-849…T-853) predates this mandate and is not credited to it.

**Arc state — tasks by status and quadrant:** not reported, and the reason is a binding rather than
an omission. The mandate requires *"Scored before started"*, and BVP scoring is where this run
would have stalled even with a working dispatcher: `fw bvp confirm` is §ACD-gated and operator-only,
and passing `--i-am-human` on the operator's behalf is prohibited. An autonomous run can therefore
produce `bvp_scores_proposed:` but **cannot make an unscored task eligible by its own action**. On
a corpus where most active tasks are unscored, the honest prediction is that round 1 parks nearly
everything it selects. That is a structural property of the mandate meeting this project's
sovereignty split, not a defect in either.

**What remains in Q1/Q2, per task, with the reason it was not done:** cannot be stated without
scoring, which is gated (above). What I can state without scoring, as read-only discovery that
authorizes nothing: the eligible-looking population is the **eleven still-red instruments** from
T-851, now cheap to iterate on (~1s each via the `--only` mode added in T-850) and gating six task
closures — the shape of Q1. Six of them have a known single cause (T-853: the T-840 upgrade
reverted in-tree vendored fixes; OBS-386).

**Sovereign questions raised, unresolved, in priority order:**

1. **Should an autonomous run be able to score at all?** The mandate says "scored before started";
   the sovereignty split says confirming a score is the operator's. These cannot both hold for an
   unscored task. Either the mandate accepts that unscored work is ineligible and parks it, or a
   proposer-only scoring path is made sufficient for eligibility. Not decidable by me.
2. **`_t350-teeth.sh` / `_t351-teeth.sh`.** The sweep excludes both and advertises them as "a
   candidate for the operator to rule on separately" — which, to an agent told to select its own
   work and exhaust Q1, reads as an invitation. `_t350`'s own header records that an earlier mutant,
   whose safety stub silently failed, **deleted this repository**, and says wiring it in is "not an
   agent's call". I had drafted an explicit prohibition into the dispatch prompt for exactly this.
   It needs a standing ruling, not a per-run guardrail, before any unsupervised run is turned loose
   on the instrument backlog.
3. **Three rounds × ~300k of unsupervised commits and pushes to `bleeding-edge`** — is that the
   intended exposure? It follows from the mandate as written; it was not separately confirmed.

**Gates that refused me, and what I did instead:**

| gate | what it refused | what I did |
|---|---|---|
| `check-active-task` (P-002) | four read-only commands not on the allowlist, including the executable/permission survey | created T-854 and re-ran under focus; the gate's own message notes an allowlist gap worth filing |
| G-020 build-readiness | file writes under T-854 while its ACs were placeholders | wrote real ACs first, via the Write tool as the gate directs |
| — | `--dangerously-skip-permissions` was **never passed**; it would strip the governance the mandate says applies in full | reported the permission posture instead: `.claude/settings.json` carries a `deny` list only — no `allow`, no `defaultMode` — so a headless session has nothing pre-approved and could not have written anyway |

**Cost-vs-estimate deltas worth feeding back into calibration:** the only measurable cost here is
that **three dispatch probes cost ~15 minutes to establish a negative**, and that cost was
unavoidable only because the surface reports success. Had `dispatch` returned non-zero on
`workers_registered: 0`, this would have been one call and one minute. That is the calibration
input: budget for verifying orchestration side effects independently until OBS-387 is fixed.

---

## Disposition

**T-854 is PARKED, not closed.** Its ACs covering "each round dispatched separately with the prior
result fed forward" are unmet and cannot be met until OBS-387 is resolved; the AC requiring the
spawned session's governance posture to be *verified* is only partly met, because the probe that
would have verified hook-loading is the thing that could not run. Closing it would be exactly the
false green this run was blocked by.

**Recommended before a retry:** fix OBS-387 (or confirm the dispatcher is expected to be
non-functional here), settle Sovereign question 2, and start the rounds in a **fresh session** where
the mandate's own ~300k ceiling is available rather than already spent.
