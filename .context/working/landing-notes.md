# Landing notes — T-575

Append-only. One line per discovery. No RCA, no ticket, no probe.
Tier 2 override of one-bug-one-task and G-019 logged once on T-575; not repeated per entry.

## Session 1 — 2026-08-20 — evidence pack for the 12 parked tasks

### The headline: the pile is not 16 investigations

Measured every `### Human` AC across the 12 tasks at `status: work-completed` in `active/`.
The pile decomposes as **2 free + 1 dead premise + 13 genuine rulings**, not as sixteen
things needing research. No amount of evidence-gathering shrinks the ruling half — that is
the operator's judgement by construction, which is why they were filed as `[REVIEW]`.

| Task | Unchecked | Verdict |
|---|---|---|
| T-178 | 0 | **FREE** — every Agent and Human AC ticked; 3 verification cmds ready. Completion was simply never re-run. |
| T-093 | 0 | **FREE** — same; 10 verification cmds ready. |
| T-368 | 2 | **AC-1 premise is DEAD** (below). AC-2 is a real question. |
| T-310 | 3 | 2 taste + 1 judgement call |
| T-410 | 2 | 2 decisions (one security-relevant) |
| T-308 | 2 | 2 taste |
| T-233 | 1 | taste |
| T-325 | 1 | decision |
| T-340 | 1 | decision (pick an option) |
| T-351 | 1 | decision |
| T-353 | 1 | ruling — **governs something already done, see below** |
| T-449 | 1 | ruling (pick a/b/c) |

### T-368 AC-1: the premise no longer holds

AC reads *"Decide whether to cut 0.9.0, and whether AEF should be told to re-pin"*, with
`**Expected:** dist/MANIFEST.yaml latest: reads ...`.

Measured: `dist/MANIFEST.yaml` `latest: "0.10.0"`, released `2026-08-15T08:39:25Z`,
`supersedes: "0.9.0"`. 0.9.0 was cut `2026-08-08`. The artifact is byte-identical to its
recorded `src_commit` 3f2bb993, so the manifest is not describing something later overwritten.

**The decision this AC asks for was taken twelve days ago and then superseded.** Standing
default says close a task whose premise no longer holds — but T-368 is `owner: human`, so it
is queued for the operator rather than closed here. AC-2 (*"is a notation/routing revision
actually planned?"*) is untouched by this and remains a real question.

Consequence I got wrong and corrected on the rail (agent-chat-arc 201): I told CashWeb three
times today that a pending cut stood between them and every fix. It did not. They have been
able to re-pin to 0.10.0 since 08-15 and pick up T-355, T-233 and T-340 — verified by ancestry
against the src_commit, not by reading changelogs. What is genuinely pending is a **0.11.0**
carrying T-521, T-523, T-562, T-566, T-570.

### T-353: the ruling governs something I already did today

AC reads *"may an agent edit `## Verification` blocks inside `.tasks/completed/`?"* — awaiting
a yes/no.

**I did exactly that today, before reading this task.** T-572 completed with a malformed
verification block; I repaired the block in `.tasks/completed/` and re-ran the nine legs by
hand (T-574, commit 7d9b9a8d). Disclosed rather than left for the operator to discover. If the
ruling is NO, that edit needs reverting and the repair re-done another way — the re-run itself
stands either way, since it was executed against the commands, not against the file.

### Discoveries (one line each, no tickets)

- Nine of the twelve parked tasks are `[REVIEW]` taste/judgement, which is the correct prefix
  — this pile is not mis-classified ACs and there is no PL-027 conversion to harvest here.
- Several tasks carry template-boilerplate `**Expected:**` lines ("All panels visible, no
  console errors", "Verdict: PASS; no findings on block-message-completeness") inherited from
  the task template, which inflate a naive grep of Human ACs. Real count is 15 unchecked, not
  the ~24 `Expected:` lines a grep returns.
- `VERSION` reads `0.10.0` and `dist/` holds 13 artifacts; nothing in the repo cross-checks the
  consumer's *pinned* version against `latest:`. That is G-024, already registered, and it bit
  in the un-registered direction today: a RELEASED fix sat unconsumed for five days with
  nothing reporting it either.

## Session 2 — 2026-08-22 — closing what needed no permission

**Scoreboard: active 77 → 76 (−1).** One task fully closed and removed from `active/`;
two more moved from "agent-blocked" to "operator queue" where they actually belong.

| Task | Was blocked on | Outcome |
|---|---|---|
| T-542 | P-011 gate refused: "Nothing was run" | **CLOSED** — 6/6 AC, 6/6 verification, reviewer PASS |
| T-432 | missing `## RCA` block | **partial-complete** → operator, 1 `[REVIEW]` AC (a/b/c gate scope) |
| T-433 | one negative-constraint Agent AC never ticked | **partial-complete** → operator, 1 `[REVIEW]` AC (vendor bump) |

### The T-542 blocker was not what session 1 diagnosed

Session 1 recorded it as "a markdown table bleeding into the verification block". The real
cause is sharper and generalises: **`## Verification of the probe itself` sat ABOVE
`## Verification`, and the gate's `sed -n '/^## Verification/,/^## /p'` is a PREFIX match,
not an exact one.** The range opened on the *first* heading, ran to the second, and fed the
gate a mutant-kill table as shell commands. Renamed to `## Probe mutation evidence`; six
real commands then extracted and all six passed.

This is the **second shape** of the same extraction defect T-574 was filed for, and the two
fail in opposite directions:

- **T-572:** a backticked mention of the heading glued it mid-line, `^## Verification` never
  matched, sed returned zero lines, `[ -z "$verify_cmds" ] && return 0` → **passed silently
  on zero commands.**
- **T-542:** a heading that *prefixes* the real one → range opened early → **blocked loudly.**

One fragile regex, two shapes, and only one of them announces itself. The loud one cost ten
minutes; the silent one shipped a task with ten unrun legs. Feeds T-574's population sweep —
its AC already names "every sibling `sed -n '/^## .../,/^## /p'` extraction", and this is a
second confirmed instance in the same file, which is what makes that AC worth its cost.

### Discoveries (one line each, no tickets)

- I wrote *"no `--force-downgrade` occurrence anywhere in git history"* into T-433's evidence,
  grepped it before committing, and got **12 hits** — all flag *definitions* in
  `lib/upgrade.sh` plus doc/task prose, zero invocations. The claim was false as phrased.
  Restated as "exists in the tool, never called". Third time this week that checking my own
  number changed it; the pattern is that absence-claims are the ones that need counting.
- **T-499's open AC is not agent-blocked and was never operator-blocked either — it is a
  scoping call.** It needs `do_url`'s exit-code contract changed
  (`bin/watchtower.sh:335`): three branches, all `echo` + implicit rc=0, no abstention
  channel exists. G-008 *permits* fixing this in-tree. Not doing it silently — four callers
  depend on the always-succeeds behaviour (`handover.sh:16`, `designer.sh:96/221/239`,
  `ux-review.py`), and a handover that loses its Watchtower URL is a worse failure than the
  one being fixed. Routed to the operator as a yes/no rather than reversed unilaterally.
- **T-537 and T-540 carry operator decisions filed under `### Agent`.** Their unchecked ACs
  read *"Operator decision recorded"* and *"Operator approves or rejects the three
  proposals"* — verbatim. These are Human ACs in the wrong section, and the effect is that
  P-010 blocks completion on a box the agent is forbidden to tick. Not converted here:
  CLAUDE.md permits Agent→Human conversion only for the deterministic PL-027 mis-prefix
  class, and converting an AC to unblock one's own completion is the laundering shape this
  project keeps catching. Surfaced as an operator ruling instead.

## Session 3 — 2026-08-22 — lane 1 drained of its biggest item; lanes 2 and 3 delivered

**Scoreboard: active 77 → 75 (−2 this session, −3 across sessions 2+3).**
T-542 and T-574 fully closed; T-432 and T-433 moved to the operator queue.

### Lane 1 — T-574 closed (the P-011 silent-pass defect)

Full account in commit `b17e49fa`. Three things the work found that were not in the plan:

1. **The old extraction ate a command whenever the block was the file's last section.**
   `sed '$d'` trims the range terminator; with no terminator it trims a real line. The gate
   ran N-1 legs and reported N-1 as though that were the block. Found by the probe's own
   first red run, now its own fixture and leg.
2. **The gate `eval`s verification lines IN ITS OWN SCOPE.** A leg naming `$verify_cmds` had
   the gate's entire command list substituted into it and died on a SyntaxError. Any
   verification line referencing a gate-internal variable is exposed to this. Legs that must
   name such a string now build it with `chr()` inside a single-quoted argument.
3. **The first absence-assertion matched the fix's own comment**, which quotes the defective
   line in order to explain it. Sibling of G-041's closure-check caveat: an absence-assertion
   over a file that documents what it removed will always find its own prose.

Also note: my dry-run harness passed all seven legs before the real gate failed one. It was
**unfaithful** — it ran the commands without the gate's variable scope. A rehearsal that does
not reproduce the environment is not a rehearsal.

### Lane 3 — the 41 human-owned tasks nobody has looked at, classified

Evidence base: commits per task (`git log --grep "^T-NNN:"`), last commit date, horizon.
A task at `started-work` with **zero commits** never started, whatever its status says.

**14 tasks have ZERO commits.** Of those, 3 are legitimately blocked and 11 are not.

| Verdict | Count | Tasks |
|---|---|---|
| KILL — never touched, superseded, or self-describing as retirable | 11 | T-184, T-185, T-186, T-279, T-280, T-281, T-282, T-289, T-291, T-292, T-277 |
| KEEP-BLOCKED — zero commits but externally sequenced | 3 | T-424 (behind T-357/T-423), T-443 (pending AEF ruling), T-402 (behind the vendor bump) |
| MERGE — three one-line framework annotations, one task's worth of work | 3 | T-439, T-441, T-442 |
| KEEP-STALE — real work, last touched >3 weeks ago | 9 | T-041, T-105, T-125, T-195, T-200, T-228, T-264, T-265, T-286, T-293 |
| KEEP-LIVE — touched in August | 15 | T-101, T-102, T-189, T-209, T-309, T-344, T-345, T-347, T-357, T-422, T-426, T-440, T-498, T-501 |

Note on the KILL list: **T-279 and T-280 are literally titled "revive or retire"** — they were
filed as decisions, not as work, and have sat undecided for 25 days. T-184/T-185/T-186 are
"Child-3/4/5" of an umbrella inception, `horizon: later`, zero commits in 42 days. T-291 and
T-292 are placeholder docs for workflows that were referenced but never created.

**The agent cannot close any of these — they are `owner: human`.** Command block in the
session report.

### Discoveries (one line each, no tickets)

- Rail checked at session start: **38 unread, 100% machine noise** — hourly T-1438 heartbeats
  on two hubs, presence notes, one stale-hub alert. No peer content since my offset-201
  correction, so nothing inbound blocks landing. Hub `laptop-141` unreachable (network).
- The four latent prefix collisions found by T-574's population sweep (`## Decisions`,
  `## Gotchas`, `## Open Questions` ×2) were **run**, not reasoned about, and all four resolve
  correctly against the live handover today because each prefix has exactly one match. One
  added handover heading turns any of them into the T-542 shape.
