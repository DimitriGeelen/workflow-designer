# procAsFit Round 1 — Handback

**Context used:** 276k, against the mandate's ~300k stop condition. **Stop reason:** context bound reached; no task parked mid-flight.

**First, a structural fact about this round.** I am round 1 of T-897's four-round chain — a print-mode worker (`claude -p`, PID 3730125, child of the dispatch shell that wrote `WORKER_STARTED 11:24:55Z`), with stdout appended to `.context/working/procasfit/round1.out`. I established that from the process tree rather than assuming it, which resolved what would otherwise have been a blocking ambiguity: the same mandate could have meant "orchestrate four rounds" (T-897's job) or "be a round". The operator's recorded instruction *"do not execute the prompts yourself outside this sequence"* made getting this right a governance question, not a convenience. T-897 is the orchestrator's; I did not touch it.

## Selection

**Objective → arc → task, stated before execution:**

- **Objective:** G6 (idea↔implementation round-trips with AEF) and G2 (a class is distinguishable from an instance) — both blocked by one missing instrument.
- **Arc:** arc-001 `designer-authoring-surface`. The *focused* arc (arc-004) is blocked: T-866 needs an operator-only live check the agent is Tier 0 on, T-869 needs a confirmed hypothesis plus weeks of elapsed time. arc-003 and arc-002 trace to **no project goal** (purpose doc §7). arc-005 is draft pending ratification.
- **Task:** T-886. **Why over the next candidate:** T-889 was the higher-profile move, and it was the wrong one. The T-888 ruling says the authority migration "is sequenced behind a guard that does not yet exist"; T-889 would have written a *new governance attribute* into precisely that unguarded seam.

One correction to my own framing: T-886 carries `tags: [arc:process-instances]` (arc-005, via the deprecated tag form), not an arc-001 `arc_id`. It is the gating dependency **for** arc-001's T-889/T-890/T-895 and **within** arc-005 for T-875. I selected it as a blocker for both, and that is the accurate description.

## Objectives advanced

| | at run start | now |
|---|---|---|
| **G2** (T-875, arc-005 S1) | parked at `issues` — the guard didn't cover the marker | unblocked; `kind` is now guarded and mutation-killed |
| **G6** (T-889/T-890/T-895) | blocked by the ruling's own sequencing clause | unblocked; the guard exists |
| `uuid` seam integrity | droppable in silence — and AEF byte-pins two files that carry it | drop it and the harness fails **on `s4-exemplar.bpmn`**, one of those two files |

The emitter writes **10** `aef:workflowMeta` attributes; the round-trip projection compared **4**. Now: derived denominator, 0 unclassified, 8 LIVE / 0 BLIND / 1 NEVER-PRESENT / 1 EXCLUDED.

**The fix is not three attributes added to a list.** `checkWmDenominator()` derives the set *from the emitter*, so the next attribute cannot enter unclassified. Proved against the real next case: injecting `authority=` — T-889's own attribute — turns the guard red naming it, statically, in 2 seconds.

## Cost vs estimate — the calibration feedback worth having

The handover's calibration note ("a cost-3.2 task consumed ~100k") **overestimated this one by ~4×**. T-886 cost ~90k *including* two follow-on tasks and three observations; the code change itself was ~40k. More usefully: **every runtime estimate I carried into this round was wrong by one to two orders of magnitude.** The harness runs in **2s**, not the 60–90s I assumed; the 5-run mutation script in **10s**, not 5 minutes. Anything in this corpus pacing itself against "the browser harness is slow" is pacing against a fiction.

## Where I was wrong, twice

These are the load-bearing parts of the handback.

1. **I filed an URGENT defect against the P-011 gate, and the defect was mine.** OBS-406 claimed the gate closed T-886 having run zero of six verification commands, inferred from a 22-second close against "twelve minutes" of work. I had wrapped my runs in `timeout 400`/`timeout 2000` and then read **my own ceilings back as observed durations**. Measured: ~15s total. The gate ran everything. Withdrawn and dismissed in the register with the measurements; **PL-349** recorded — *a timeout value is not a measurement*. The irony is the transferable part: an observation whose whole subject was a gate asserting a pass it had not measured was itself an assertion I had not measured. Left visible rather than tidied, because the URGENT flag would have sent round 2 to investigate a healthy gate.

2. **I committed a change to a shared harness having run one of its five dependents**, judging the other two safe by reading them — one hour after recording PL-349. Measured under T-900: nothing was broken (`_t591` 4/4; the bridge leg green *and* provably able to go red). But the reason the pre-flight missed it is a real finding, below.

I also caught two errors inside T-899's own writing and left both visible: I ticked an AC citing a witness timestamp *before the witness existed*, and wrote a verification line that grepped `fw note list --all` for a dismissed note — a route structurally incapable of seeing it (measured: 0 matches).

## Sovereign questions, priority order

1. **OBS-408 (new, mine) — `fw fabric deps` and `fw fabric impact` disagree, and `impact` is the wrong one.** `deps` prints five dependents for the harness; `impact` prints an **empty chain**. CLAUDE.md sends the agent to `impact` *before* modifying a file. An empty impact chain doesn't read as "examined nothing" — it reads as "nothing depends on this, change it freely". G-034's zero-population blindness in its *reassuring* direction. This is why my unverified commit happened, and it will do it to the next agent.
2. **OBS-407 (new) — 3 of 5 sampled review-queue tasks have failing verification.** T-308, T-310, T-325 are presented as agent-verified and awaiting only a human AC, while their own recorded blocks are red. A GO recommendation resting on a red block rests on nothing. 7% sample of a 72-task queue; the true count is **unmeasured**.
3. **OBS-396 — fabric subsystem taxonomy.** Refused me live: `fw fabric register` created the card and refused the subsystem. Unchanged, not worked around.
4. Carried forward unresolved: **OBS-398** (inceptions outrank builds by construction), **OBS-397** (remediation vs product bandwidth), **arc-005 ratification** (§6 of the purpose doc).
5. **T-885 needs your close** — six Agent ACs ticked, `owner: human` because `fw note promote` created it that way. G-027 exactly. I did not change ownership; that is not delegated.

## Gates that refused me, and what I did instead

| gate | what I did |
|---|---|
| **G-020** (placeholder ACs) blocked all execution on T-886 and T-899 | wrote real ACs first. Correct gate, correct order — it is the reason this round has checkable criteria |
| **P-011** ran 4/4 and 6/6 at the closes | the independent check on my own output |
| `check-active-task` blocked pure **reads** starting `for`, and a `grep` pattern containing `-->` read as a shell redirect | rephrased. **OBS-394 confirmed live ×3**; the `-->` false positive is new |
| Focus cleared on every close, blocking the next read (**G-047**) | hit 3×; each time re-focused or rephrased |
| **Inception recommendation gate** refused T-898 without a recommendation | supplied DEFER + rationale + revisit trigger. Right gate |
| `fw fabric register` refused a subsystem (**OBS-396**) | left refused, filed nothing over it |

**Scored before started:** T-886 scored through the estimator (D1=4 D2=4 D3=3 D4=2), with its rationale honestly declaring "no hypothesis, so this score has no claim to be wrong about" — arc-004's S3 citation working as designed. One ordering note for calibration: **"scored before started" is not achievable as written** — the estimator is itself gated behind an active task and real ACs, so the real invariant is *scored before execution*.

## What remains in Q1/Q2, and why I didn't do it

- **T-889** (`aef:meta` authority on the element) — now genuinely unblocked and is the obvious round-2 opener. Not started: ~23k of budget left, and it changes the emitter.
- **T-890, T-891, T-892, T-893, T-894** — the rest of the ruled package, all unscored stubs with placeholder ACs. G-020 will block each until real ACs exist; budget for that.
- **T-357 / T-309** (0.80, top of the ranking) — Q2, untouched: the mandate says Q1 to exhaustion first.
- **T-875** — unblocked and one step from resolvable, but it sits at `issues`; needs a healing-resolve pass, not a fresh build.

**TermLink:** used as the transport that carries this round (I am the dispatched worker); I did not spawn sub-agents. Every task touched the same harness and the same task corpus — shared state, which the mandate says to serialize. Recorded rather than decorated.

**One thing to check before trusting this handback:** `fw handover --commit` **pushed to `origin/bleeding-edge`** (`de3a367f`) as part of its designed flow. Four commits are now public: `5583a51f`, `d43b09a0`, `aeeaf0c4`, `0b27047c`. If round 2 expected an unpushed branch, that assumption is already broken.