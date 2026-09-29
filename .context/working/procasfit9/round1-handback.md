# procAsFit round 1 of 9 — handback

**Run:** 2026-09-29 (UTC 2026-09-28 22:5x → 23:5x), worker under T-922 orchestration. Branch `bleeding-edge`, start commit `670d67be`, end commit `31d453e6`. **13 commits, all local, none pushed.** Context at stop: ~455K of the 1M cap (stop line was ~800K).

**Stop condition met:** every Q1/Q2 task at horizon `now` in every goal-bearing arc is either closed, partial-complete awaiting the human, or blocked on a Sovereign / peer ruling. Nothing eligible remained that an agent may execute.

## Selection trail (stated before each unit, verbatim in the transcript)

| # | objective → arc → task | quadrant | why this over the next | outcome |
|---|---|---|---|---|
| 1 | G0 → arc-004 (focused) → T-866 S1 hypothesis gate | hv-lc Q1, confirmed 106 / 3.2 | only open now-horizon task in the focused arc; 10/10 Agent ACs already ticked, blocks empty (G-027 shape) | **partial-complete** (owner human, 1 [REVIEW] AC), `63c9de26` |
| 2 | G6 → arc-001 → T-906 components backfill | scored at close: 115 / 4.4 hv-hc | the instrument every later quadrant decision reads; G-027 shape | **closed**, `c3da49c8` |
| 3 | G3 → arc-005 → T-880 recorded current node | 160 / 4.4 hv-hc Q2 | T-878 GO made it buildable; smallest step that turns G3 from "does not exist" into "answerable" | **closed**, `d8ac0326` |
| 4 | G3 → arc-005 → T-881 resolution both ways | 151 / 3.2 hv-lc Q1 | depends on T-880, cheapest remaining G3 step | **closed**, `79b5e4e8` |
| 5 | G6/G0 → arc-001 → T-907 parity checker reads comments | 148 / 3.2 hv-lc Q1 | cheapest false-green fix; stubs → real ACs first | **closed**, `45cbef0e` |
| 6 | G6 → arc-001 → T-885 workflowMeta census | 160 (proposed) | 6/6 ACs ticked since 09-26, empty blocks | **parked** — gate: human-owned; blocks written and committed `d328aff6` |
| 7 | G6/G0 → arc-001 → T-890 laneMeta authoringDefault | 151 / 3.2 hv-lc Q1, highest in arc | at `issues`; its blocker (OBS-416) was removed by T-910 | **closed** (healing resolved), `a1cca795` |
| 8 | G6/G0 → arc-001 → T-905 COMPUTED_SOURCES misdeclaration | 130 / 3.2 hv-lc Q1 | same false-green class as T-907, no browser needed | **closed**, `78a25279` |
| 9 | G6/G0 → arc-001 → T-902 YAML element-authority gate | 130 / 4.4 hv-hc | pairs the rule T-889 refused to fake; carrier live on 6 corpus maps | **closed**, `5a0e1b46` |
| 10 | G6 → arc-001 → T-893 render authority on the element | 133 / 4.4 (was 2.0 before real cost) | last now-horizon Q1; abandoned by round 4 of T-897 on verification cost, not on a blocker | **partial-complete** (1 [REVIEW] AC), `cef20dac` |
| 11 | G6 → arc-001 → T-892 lane authoring-default selector | 148 / 3.2 hv-lc Q1 | the UI half of the clause T-893 rendered; makes `differs` authorable | **closed**, `31d453e6` |

Every unit: scored through `fw bvp estimate`/`confirm`/`estimate-cost` before execution (T-866/T-906 were confirmed scores already; the rest scored at `fw work-on`, which is where the gate lets the estimator write — see Gates §), verification run through `fw task verify`, state change through `fw task update`, commit bare `git commit` with the task id.

## Objectives advanced, against run start

- **G3 "an instance knows its class" — from "does not exist" (purpose doc §3, 09-27) to answerable from the system.** `tools/instance-node.py bind|nodes|get|set|resolve|instances|roundtrip`; binding derived from `workflow_type` via `examples/aef-processes/template-binding.yaml`; position recorded as `current_node:`; no new identifier. Measured on the live corpus at close: task-lifecycle 178 live instances, inception-lifecycle 15, all NO-POSITION (T-878 IW-5's prediction, confirmed). arc-005 S2 (T-880, T-881) closed; the dead hint in `update-task.sh` that had never fired here now guards on the pinned artefact and names `frw_7_all`.
- **G6 / arc-001 — the T-888 authority ruling is now visible and authorable end-to-end:** element marker in three non-collapsing states (T-893), lane authoring default in the panel with a byte-level "never re-stamps" proof (T-892), YAML-form element gate pairing the XML one (T-902, gap count 13 → 12 re-derived), laneMeta round-trip guard demonstrated red (T-890).
- **G0 — three false-green instruments fixed with mutation-proved teeth:** parity checker comment handling (T-907), COMPUTED_SOURCES verified declarations (T-905), laneMeta guard demonstration (T-890). Denominator unchanged at 37, as each task predicted.
- **arc-004 (focused) — S1 reaches partial-complete** with live evidence: the gate refused the operator twice on T-878/T-879 (commit `39e5158d`), which is Human-AC steps 1–2 observed by the human. Step 3 (an acceptance end-to-end) is still unevidenced and is stated as such.
- **Selection discipline itself:** T-906 closed, so arc-001 now ranks on a real cost axis.

## Arc state (tasks by status, quadrant where scored)

- **arc-004 hypothesis-first-inceptions (focused):** S1 partial-complete (Q1) · S2, S3, backfill, T-912 completed · **S4 T-869 captured, horizon later (parked, Q1 by score)**. Nothing at `now`.
- **arc-005 process-instances:** T-875/877/878/879/880/881/886/911 completed · T-876 captured/now **HELD** (peer question on the rail: editor-save or backfill, 5 or 24) · T-882/883/884 captured, horizon later.
- **arc-001 designer-authoring-surface:** closed this round T-890, T-902, T-905, T-906, T-907, T-892 · partial-complete T-893 (Q1), plus the 41 pre-existing awaiting review · started-work T-889 (Sovereign question on AC 1 wording, 09-27) · captured/now T-901 (decision), T-424 (blocked on T-357 review) · horizon later T-279/280/281/282/564/895/896.
- **arc-003 / arc-002:** not entered — trace to no G1–G6 per the purpose document; T-863 and T-860 (listed by the arc-scoped `fw bvp` though tagged arc-003 / untagged) are horizon later.

## What remains in Q1/Q2, per task, and why not done

- **T-889** (hv-hc 133) — AC 1 names a proof the recorded Sovereign question (09-27) says cannot exist as written. Not mine to re-rule.
- **T-876** (142, no cost) — held by the T-877 rail question to AEF about a byte-pinned interface. Peer/Sovereign.
- **T-901** (unscored) — "decide its fate": a decision task on a ratified-but-live vocabulary value across AEF-pinned artefacts. Sovereign.
- **T-885** (160) — every AC verified (5/5 legs), `owner: human`; the close gate refused and the autonomous-mode boundary says stop. Evidence for closing is in the task and commit `d328aff6`.
- **T-424** — depends on T-357, which is partial-complete awaiting the human.
- **T-869 S4, T-863, T-860, T-882/883/884** — horizon later; out of scope by the selection rule, not by value.
- **41 pre-existing partial-completes** (T-233 … T-858) — human review queue; not agent work.

## Sovereign questions, priority order

1. **T-885 close** — human-owned, fully verified; suggest closing on the cited evidence (`fw task update T-885 --status work-completed` after reading `## Verification`, 5/5).
2. **T-889 AC 1** — the 09-27 question stands: split AC 1 into the two checkable claims, or leave it unmet as a standing defect in the criterion.
3. **T-876** — editor-save vs bulk backfill, 5 vs 24 maps, on artefacts AEF byte-pins (rail offset 226).
4. **T-901** — `authority="none"`: retire across both forms now (18 laneMeta occurrences) or record why it stays until T-895.
5. **T-893's effective default (PD-344)** — I decided that during T-895's migration the lane's legacy `authority` stands in as the authoring default (else every node on all 24 maps would show "missing"). Recorded as a Decision; if the pure clause-4 reading is wanted instead, it is one line in `effectiveLaneDefault`.
6. **T-866 Human AC step 3** — `fw inception status` shows T-878 and T-879 both recorded as GO, so an acceptance through the gated path may already have happened; the task files do not say whether the operator's decision went through `fw inception decide` (gated) or another route. If it did, the Human AC can be ticked on that evidence; I did not tick it (agents never tick Human ACs).
7. **OBS-413 (from prior run), still open** — `fw handover` pushes to origin without a flag. I did **not** run `fw handover` at the end of this round for that reason; this file is the handback. If the framework's session-end handover is wanted, run it deliberately with the push understood.

## Gates that refused me, and what I did instead

- **`check-active-task` on `export FW=…`** and on shell-variable assignment/`for` loops in read-only commands — not on the allowlist. Rewrote as plain paths and single commands. Filing-worthy allowlist gaps: `export`, `f=$(…)`, `for … in`, `awk '…,0'`.
- **G-020 (placeholder ACs)** refused `fw bvp estimate` on T-907, T-905, T-902, T-893, T-892 until real ACs were written with the Edit tool. Correct; obeyed each time.
- **"Task must be started before modifying files"** refused `fw bvp estimate` on a captured task — so the mandate's *scored before started* is satisfiable only at `fw work-on`, which auto-estimates. Recorded; no bypass.
- **Completion gate, uncontrolled absence assertion** — refused T-880 and T-905 closes on `! grep` legs with no same-pattern control; fixed the legs (PL-328), not the gate.
- **Completion gate, human-owned** — refused T-885; parked.
- **Focus-drift gate** on committing T-890's fabric card while focused on T-889 — used the gate's own prescribed `FW_SWITCH_FOCUS=1` path (Tier 2, logged) for that one commit and the T-880 card; no `--force`, no `--skip-*` anywhere this round.
- **Partial-complete edit gate** refused a post-close `instance-node.py set T-880 frw_11_task` — correct; T-880's own record is now stale against its status, which is T-882's scope (OBS-433).
- **Playwright MCP browser "already in use"** by another session (G-006) — did not fight it; drove an isolated headless Chromium via the project's CDP plumbing for T-893/T-892.
- **`fw healing resolve`** blocked 321 s on an interactive prompt (OBS-434); killed, re-run with the name on stdin.

## Findings surfaced (observations filed)

- **OBS-432** — P-011 runner is killed by a leg containing `exit 1`; no FAIL line, no summary. Fixed at the leg (subshell).
- **OBS-433** — recorded `current_node` does not advance on lifecycle transitions; the framework's own transitions are the natural writer (T-882).
- **OBS-434** — `fw healing resolve` prompts for a pattern name with no flag; non-interactive it hangs or exits 0 having recorded nothing.
- **OBS-435** — `fw fabric register` prints REFUSED (no subsystem rule) and writes the card anyway with `subsystem: unknown`. Seen three times this round (binding yaml, two `.mjs` with shebangs).
- **OBS-436** — YAML-form IW-9 reads the lane only; XML applies clause-2 element-wins. A relation gap, distinct from T-902's vocabulary gap.
- Not filed, worth knowing: the arc-scoped `fw bvp` lists T-863/T-860/T-189 under the focused arc while `fw arc show` does not — arc membership by tag vs by id disagree.

## Cost vs estimate

- **T-893** is the calibration case the previous run predicted: `blast_radius=1` scored it 2.0 (cheapest Q1); real cost was the round's largest unit (driver, nine screenshots read, a decision). After components were populated it re-scored 4.4. Verification standard is not in the cost formula.
- **T-880** (estimate 4.4): about as estimated; the fixture-based guard-fires proof was the extra.
- **T-881, T-907, T-905, T-902, T-892** (3.2–4.4): each under an hour of wall time; teeth and mutation modes are now routine, roughly half of each unit.
- **Close-only units** (T-866, T-906, T-885): the G-027 shape cost ~15 minutes each and unblocked the quadrant axis for everything after. Three in one round says the shape is common enough to want an instrument.
- **Wasted:** ~300 s on the healing prompt; two gate round-trips on absence legs; one 60-second detour on `git status --cached`.

## Auditability

Every close above is a `fw task update … --status work-completed` that passed its own `## Verification` (counts in each commit message), every partial-complete was produced by the same verb, every score by `fw bvp confirm`, and every claim of "green" has a leg in the task file that re-runs it. Working tree: 435 uncommitted paths at stop, all pre-existing noise (cron audit deletions, editor-version artefacts, `.context/working`), none from this round except the refreshed episodics the commit hook rewrites.
