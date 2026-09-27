You are ROUND 3 of a four-round sequence. Rounds 1 and 2 have completed; both handbacks are
reproduced verbatim below, oldest first. Read them before selecting work. Do not repeat what they
did and do not re-derive what they measured — but do not inherit any claim you intend to build on
without checking it. Both rounds caught themselves asserting something they had not measured, and
both recorded it rather than tidying it; that is the standard for this round too.

FOUR THINGS FROM ROUND 2 ARE LOAD-BEARING FOR YOU:

1. T-904 is the highest-value open item round 2 filed, and it undermines a guard that two tasks
   already rely on: the round-trip guard derives its key set by regexing the emitter's RAW TEXT,
   COMMENTS INCLUDED. Deleting `authority` from the emitter left the guard green because a prose
   comment mentioned it; removing only the comment turned the identical mutant red. False green for
   a deleted key, false red for a key only mentioned. T-886 and T-889 both stand on that guard.
2. OBS-410 is URGENT and affects how you must work: the MCP `fw` server is rooted at a DIFFERENT
   PROJECT (/005-Yellowtwig/...), and it exposes write verbs (work_on, task_update, note,
   context_focus, add_learning). Do NOT use the mcp__fw__* tools here — use the local
   .agentic-framework/bin/fw binary. A write through that surface silently mutates an unrelated
   project.
3. T-889 is parked at 5/6 with one open AC: the browser-driven proof that the editor writes
   element authority. It was left unticked deliberately rather than argued closed from its static
   halves. If you close it, close it on that proof.
4. QUADRANT SELECTION DOES NOT WORK on arc-001: no open task there has a cost_estimate, so
   `fw bvp` shows QUAD - for all of them. Both prior rounds selected on value plus gating status
   and said so. Do the same, or fix the cost axis, but do not pretend a quadrant decision was made.

Your own mandate follows the handbacks. Apply it in full, select your own work under it, and
produce a handback in the same shape.

==============================================================================
ROUND 1 HANDBACK (verbatim)
==============================================================================

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

==============================================================================
ROUND 2 HANDBACK (verbatim)
==============================================================================

# procAsFit Round 2 — Handback

**Context used:** 246k measured at the gate, against the mandate's ~300k stop. **Stop reason:** approaching the context bound with a task at a clean parking point. T-889 is parked at 5/6 ACs, not abandoned mid-edit.

**Structural note.** I am round 2 — `claude -p`, PID 3699510. The prior round-2 attempt was refused by a weekly limit and recorded as failed (`bc9d6ba3`), so this is a re-run, not a continuation of a partial.

## Selection

- **Objective:** G6 (idea↔implementation round-trips). Purpose doc §7 is the gate: G6→arc-001 is the *only* goal with an in-flight arc. arc-005 is draft-unratified; arc-002 and arc-003 trace to no goal and are therefore ineligible at level 1 however tractable — arc-003 holds 41 open tasks and would have absorbed the whole round.
- **Arc:** arc-001 `designer-authoring-surface`.
- **Task:** T-889 (T-888 ruling clause 2). Round 1 named it the obvious opener; I checked rather than inherited, and found it already `started-work` with real ACs and an estimator score from 13:01Z — round 1 *prepared* it and reported "not started" meaning no code. G-020 and scored-before-execution were therefore already satisfied.
- **Quadrant: none — and that is a finding.** T-889 has no `cost_estimate`, so `fw bvp` shows `QUAD -`. So do **all** of arc-001's open `now`-horizon tasks. 40/123 tasks corpus-wide (33%) have no cost. The mandate selects by quadrant; for the arc that carries the project's only live goal, the quadrant axis does not exist. I selected on value (0.42 norm, above several tasks the ranker labels `hv`) plus gating-dependency status, and am flagging rather than papering over that this was not a quadrant decision.

## Objectives advanced

| | at run start | now |
|---|---|---|
| **G6 / clause 2** | element authority emitted by nobody, validated by nothing | element carries it; validator reads it **directly**, both prohibitions proven separately |
| vocabulary integrity | element values ungated | `E-XML-META-AUTHORITY`, `AUTHORITIES` reused not re-listed, registered in both parity registries |
| **T-886's guard** | believed sound | **a hole found and filed (T-904)** — see below |

**5 of 6 ACs closed**, each with a re-runnable check. `fw task verify T-889`: **7/7 passed**.

## The finding worth the round

**T-904 — the round-trip guard's denominator reads comments as code.** `deriveProjectedKeys()` regexes the raw text of the emitter function, comments included. Measured: deleting `authority` from the emitter's `metaKeys` left the guard **green**, because a prose comment three lines above said `node.aef.authority`. Removing only that comment text — changing nothing executable — turned the identical mutant **red** with the correct message.

This is T-886's derivation, which exists precisely so the list cannot drift from the code, and it can be moved by text the engine never runs. Bidirectional: false green for a deleted key, false red for a key only ever mentioned. **My own explanatory comment silenced my own mutation leg**, which is how it surfaced. Learning recorded.

## Where I was wrong, three times

1. **I ran the corpus census under the wrong XML namespace** (`aef.dev/schema/1.0` vs the real `anchorpoint.framework/aef/extensions`) and reported 94 files / 2130 nodes. The conclusion — zero element-level authority — survived only because a namespace-agnostic text grep independently agreed. Re-measured: **201 files, 4892 nodes, 500 lane-level, 0 element-level.** Corrected in the task's Evolution section rather than quietly.
2. **My first document-order control was vacuous.** It passed while proving nothing: `process.find(laneSet)` locates the set regardless of position, so relocation changes no answer even under lane-reading. Replaced with a two-laneSet pair, and the teeth script now carries **C4, a control on the control** — it requires the pair to *differ* under a lane-reading mutant. Without C4 the green means nothing.
3. **I destroyed the task's `## Verification` section with my own edit** — sliced on `s.index('## Verification')`, which matched the *prose mention* in the Human-AC paragraph, not the heading. The symptom (`No verification commands found`) looked exactly like the commit path silently dropping the P-011 gate's only input — a vacuous-gate defect of the class this project hunts. **I checked before filing.** It was mine. PL-349 applied in the one case where getting it wrong would have cost round 3 an investigation into a healthy gate.

I also walked into the **L-387 pipefail trap** the task template warns about at length: `python3 … | grep -q` returns the validator's exit 2 under `pipefail`, so two controls read false while matching.

## Sovereign questions, priority order

1. **OBS-410 (new, URGENT) — the MCP `fw` server is rooted at a different project.** `mcp__fw__version` reports `/005-Yellowtwig/001-theSpiceFactory/002-Azure-DevOps`, fw v1.6.768; the local binary is `/opt/832-Workflow-designer`, v1.7.68. That toolset exposes **agent-authority write verbs** (`work_on`, `task_update`, `note`, `context_focus`, `add_learning`). An agent reaching for `mcp__fw__work_on` here mutates an unrelated project's task state, silently, with no gate objecting. Detected only because a *read* returned "T-889 not found" — the benign direction. A write is not.
2. **Quadrant blindness on the goal-bearing arc** (above). The mandate's own selection discipline cannot be executed as written on arc-001.
3. **OBS-408 confirmed independently, and refined.** `deps` prints 5 dependents; `impact` prints a bare header. New datum: `impact` **exits 1** — so it does signal failure, but its *output* reads as a successful empty result, which is the dangerous half.
4. **T-903 — `E-WORKFLOW-KIND` / `E-XML-WORKFLOW-KIND` have failed the dialect harness since T-875, unnoticed.** Concrete harm from the pre-flight gap: `run-bridge-tests.sh` is one of five dependents, takes ~15 minutes, and T-875 did not run it. I ran it, which is how these surfaced alongside my own.
5. Carried forward: OBS-407, OBS-396, OBS-398, OBS-397, arc-005 ratification. **T-885 still needs the operator's close** (six Agent ACs ticked, `owner: human`, G-027) — unchanged, not delegated.

## What remains in Q1/Q2

- **T-889 AC 1** — the only open criterion. Both *static* halves hold and are checked (`metaKeys` 20→21, panel writer via `AEF_FIELDS`). The AC's actual proof — driving the editor in a browser to set authority on a node from an authority-free document and observing the export — was not built: `SRC_HTML` is not overridable and the sidecar must be up. Left unticked rather than argued closed from the static halves.
- **T-901 / T-902 / T-903 / T-904** — filed this round with real descriptions, all unscored stubs. T-904 is the highest-value: it undermines a guard two tasks already rely on.
- **T-890 – T-895** — the rest of the ruled package, still placeholder ACs; G-020 will block each.
- **T-357 / T-309** (0.80, hv-hc) — untouched; Q1 first.

## Gates that refused me, and what I did instead

| gate | what I did |
|---|---|
| `check-active-task` blocked **pure reads** ×4 — a `VAR=…` prefix, a `for` loop, an `xargs` pipe, `fw task show` (while `fw arc list` passed) | rephrased each. **OBS-394 recurring**; the `fw task show`-vs-`fw arc list` asymmetry is a new instance of the same allowlist gap |
| selection itself gated — `fw bvp` needs an active task, but choosing the task needs the ranking | read frontmatter directly, then confirmed via `fw bvp` once focused. Round 1's ordering note stands |
| **P-011** ran 7/7 at `fw task verify` | the independent check on my own output — and the thing my bad edit had silently disabled |
| **parity/dialect harness** refused my new rule twice (no carrier, no parity class) | registered it properly, and classified it **GAP not PAIRED** — PAIRED would have asserted a YAML counterpart that does not exist. Filed as T-902. Correct gate; it caught a real T-317-class omission |
| `fw task create --arc` rejected | used `--tags "arc:…"` |

## Cost vs estimate

Round 1's calibration holds and extends: **the harness is fast, the suites are not.** Guard: 2s. Teeth (9 legs, 3 mutants, 2 full harness runs): ~90s. 201-file validator regression: ~60s. But `tests/run-bridge-tests.sh` ran **~15 minutes** — long enough that I serialised all `src/` and `tools/` edits behind it, which was the right call and cost real wall-clock. Anything pacing itself against "the harness is slow" is still wrong; anything assuming "therefore all the tests are quick" is wrong in the other direction.

T-889 cost ~245k against round 1's ~90k for T-886 — but produced 5 ACs, 4 filed tasks, a guard defect, and a 201-file regression. The dominant cost was not the code; it was **measuring rather than asserting**, three times over, including twice catching myself.

**TermLink:** used as the transport carrying this round. I spawned no sub-agents and did not dispatch BVP estimation — T-889 arrived already scored by round 1's estimator run, so dispatching again would have been decoration. Every unit touched the same three files and the same task corpus: shared state, serialised, as the mandate requires.

**Check before trusting this handback:** three commits (`a906f337`, `71d4943b`, `f0c84765`) are on `bleeding-edge`. I did **not** run `fw handover --commit`, so unlike round 1 these are **local, unpushed** — verify before assuming either state.

==============================================================================
YOUR MANDATE — ROUND 3
==============================================================================

procAsFit
Mandate

Proceed autonomously. Select your own work, execute it, and keep going until a stop condition fires. You are not waiting for instruction between units of work — you are waiting only for a Sovereign decision when one is genuinely required.

Framework governance applies to this run in full. AEF governs its own development; no exemption applies because the work is autonomous.

Selection — what to work on

Work is selected top-down. Each level is a gate on the level below it.

Project. Start from the project goals and objectives. Anything that does not advance them is not eligible, however tractable it looks.
Arc. Among eligible work, pick the arc whose completion moves a project objective furthest. Prefer an arc already in flight over opening a new one, unless the in-flight arc is blocked.
Task. Within the chosen arc, select by BVP quadrant:
Q1 — high value / low cost: work first, to exhaustion.
Q2 — high value / high cost: work second.
Low-value tasks are out of scope for this run regardless of how cheap they are. Leave them scored and parked.
Activity. Within a task, do only the activities its acceptance criteria require. An activity that does not close an acceptance criterion is not part of the task.

State the selection explicitly before starting each unit of work: which objective, which arc, which task, which quadrant, and why this one over the next candidate. Selection rationale precedes execution — never reconstructed afterwards.

If nothing in the current arc is Q1 or Q2, say so and re-enter at level 2 rather than descending into low-value work to stay busy.

Governance bindings
Verb gates only. All state changes go through fw verbs. No direct writes to focus.yaml, arc-focus.yaml, or .next-directive.yaml. A gate that refuses you is a finding to be recorded, not an obstacle to route around.
Producer-not-judge. You do not certify your own output. A task closes when its acceptance criteria are independently checkable and checked — not when you judge the work adequate. Do not adjust BVP calibration parameters or rescore your own completed work upward.
Research is not authorization. Discovery is read-only. Findings do not ratify anything.
Sovereign questions are surfaced, not resolved. Anything requiring an architectural, scope, or priority decision that is not already settled: write it as a Sovereign question, park the task, move to the next. Do not decide it to keep momentum.
One lock at a time. Do not open a second structural change while the first is ungated. Reliable-but-ungated is the dangerous state.
Scored before started. No task is executed before it has a BVP score. If an unscored task is the obvious next move, score it first through the scorer, not by estimate.
TermLink

Use TermLink where it is the right instrument, not decoratively:

Dispatch BVP estimation to the bvp-estimator worker rather than scoring inline.
Run independent tasks concurrently where they touch disjoint paths; serialize anything touching shared state.
Carry the run record on it so state survives a context reset.

If TermLink is unavailable, or using it would obscure the audit trail, work directly and record why.

Execution loop

Per unit of work:

State the selection (objective → arc → task → quadrant) and the rationale.
Execute the activities the acceptance criteria require.
Run the check that closes each criterion. Record result, pass or fail.
Close or park the task through the proper verb.
Log: what changed, what it cost against estimate, what it surfaced.

If a task fails its acceptance criteria twice, stop working it, record the failure mode, and move on. Three attempts at the same wall is context burned, not progress.

Stop conditions

Stop at the first of:

All Q1 and Q2 tasks in the active arc are complete, and no other arc has eligible Q1/Q2 work, or
context reaches ~300k, or
a Sovereign question blocks every remaining eligible path.

Do not stop mid-task. Close or park the current task, then write the handback.

Handback
Objectives advanced, and by how much — against the state at run start.
Arc state: tasks by status and quadrant.
What remains in Q1/Q2, per task, with the reason it was not done.
Sovereign questions raised, unresolved, in priority order.
Gates that refused you, and what you did instead.
Cost-vs-estimate deltas worth feeding back into calibration.
Auditability

This run will be reviewed against the bindings above. Every claim in the handback must be traceable to a recorded check or a verb-gated state change. An assertion that something works, without the check that demonstrates it, counts as an open task and not a closed one.
