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
