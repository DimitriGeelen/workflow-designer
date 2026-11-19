# T-676 Human AC#1 — evidence report (reviewer judge-t-676-r3-55f48cf6eddf)

Revision reviewed: df98fc5727d2510f6edfebb5ea281c99a3676510 (HEAD at review; task file and
`.agentic-framework/agents/context/` have no uncommitted changes).

## The criterion
"[REVIEW] Should P-002 exempt read-only Bash when focus is absent, captured, or completed?"
Expected: a recorded ruling. Nothing edits `check-active-task.sh` before it.

My job here is not to make or second-guess the ruling, only to check the box records it.

## What I checked

1. **A ruling is recorded, and it is bound to this criterion as it stands.**
   - `.context/reviews/recorded-rulings.jsonl` line 1: `id RL-87476ffe`, `task T-676`, `ac 1`,
     `ruling "a"`, `ac_digest 950d31cffd1e`, `by root`, ts 2026-11-19T07:41:00Z, ref "operator in
     session 2026-11-18, recorded under the criterion (commit b826295ef)".
   - `fw reviewer verdict digest T-676 --ac 1` returns `950d31cffd1e` now: the criterion text I
     read is the text the ruling was recorded against.
   - The record was made by the operator-only step of operator job 168
     (`.context/runme/168-close-t676-and-h1/run-20261119T084057.log` lines 25-38: "Recorded
     RL-87476ffe", then commit df98fc572).

2. **The ruling answers this criterion's question.**
   - The text under the criterion (task file lines 270-276, added by commit b826295ef) reads:
     `Operator ruling, 2026-11-18 (in session, answering the escalation above): "a" — close T-676
     as overtaken upstream`, with no local change to `check-active-task.sh`.
   - The escalation it answers (line 269, verdict V-20261116-3d4eead8) is on this same criterion
     and put two choices, in this order: close T-676 as overtaken by upstream, or keep it open
     for a gap upstream leaves. "a" as the first of those matches the gloss in the task.
   - That is an answer to the criterion's GO / NO-GO / DEFER question: no local exemption is
     applied and the task closes, because upstream already supplies the exemption.
   - Limit of what I saw: I did not find the in-session message where the choices were lettered.
     The mapping of "a" to "close as overtaken" rests on the task text, the order of choices in
     the escalation, and on the operator having themselves run job 168, whose title and reason
     ("You ruled 'a' on T-676 yesterday…") and whose ref point at commit b826295ef, which holds
     that gloss.

3. **What the task records matches the ruling; the stated facts hold.**
   - "AEF's read-only allow-list … checked before any focus test": `check-active-task.sh:354`
     calls `is_bash_safe_command` ahead of the active-task check. Sourcing
     `.agentic-framework/agents/context/lib/safe-commands.sh` and testing: `git status --short`,
     `git log --oneline -5`, `fw arc list`, `git push` → SAFE; `rm -rf x`, `git commit -m x` →
     not safe. `git push` counted safe is the wider scope the ruling says the operator accepts.
   - Path note: the ruling text names `lib/safe-commands.sh`; the file is at
     `.agentic-framework/agents/context/lib/safe-commands.sh` (relative to the hook's directory).

4. **Nothing edits `check-active-task.sh` for this task, before or after the ruling.**
   - `git log --grep='T-676' -- .agentic-framework/agents/context/check-active-task.sh`: empty.
   - Commits touching the hook since the ruling (2026-11-18 13:13): only the be.60 re-vendor pair
     (f3b189557 pristine, a36051acb local fixes re-applied). The local patch on the hook is
     line-for-line the same as the one carried on be.57 (diff of the two patch sets: empty), and
     it is the older T-639 / T-921 / T-662 / T-1037 fixes, none of them a read-only exemption.

## Out-of-date literal (does not change the verdict)
Step 1 says "eight occurrences"; the register has nine rows (line 76, instance 9). This is in a
reading step, not in the Expected clause, and the escalation the operator answered already said
so on its face. I do not propose a restatement: the ruling is bound to digest 950d31cffd1e, and
rewriting the criterion now would detach the recorded ruling from it for no gain.

## Verdict
green. A ruling is recorded (RL-87476ffe), it is bound to this criterion's current text, the
task text under the criterion says what the ruling says, and no T-676 edit to the hook exists.
