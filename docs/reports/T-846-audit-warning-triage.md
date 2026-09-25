# T-846 — triage of the 15 standing audit warnings

**Date:** 2026-09-25 · **Source:** `.context/audits/2026-09-25.yaml` (35 rows: 20 PASS, 15 WARN, 0 FAIL)

Two questions per row: **is the claim true in this project?** and **is the named remedy runnable
as written?**

## Verdicts

| # | check (abbreviated) | claim true? | remedy runnable? | verdict |
|---|---------------------|-------------|------------------|---------|
| 1 | onboarding-seed corpus refs — NOT EVALUATED, candidate set empty | yes | n/a (diagnostic prose) | ACTIONABLE |
| 2 | PROJECT_ROOT resolution, 0 `.py` under `web/`+`lib/` — NOT EVALUATED | yes | n/a | ACTIONABLE |
| 3 | stale-slice-references, 0 files scanned — NOT EVALUATED | yes | n/a | ACTIONABLE |
| 4 | 26 GO-scope-not-propagated inceptions of 30 | yes | **yes** — the named `cat` target exists | ACTIONABLE |
| 5 | Fabric: 80/411 cards have no edges | yes (413 cards now) | **yes** — `fw fabric enrich` exists | ACTIONABLE |
| 6 | Fabric drift: 15 files have no card | yes | **yes** — `fw fabric scan` exists | ACTIONABLE |
| 7 | Fabric: 11 cards outside any watch pattern | yes | n/a (descriptive) | ACTIONABLE |
| 8 | Cron exec-bit, 0 directly-invoked scripts — NOT EVALUATED | yes | n/a | ACTIONABLE |
| 9 | Branch hygiene: 1 finding — "stale branches, worktrees or remote refs" | **NO** | **NO** | **MISLEADING + UNRUNNABLE** |
| 10 | Unit suite (tests/unit) NOT CHECKED | **NO** | **NO** | **MISLEADING + UNRUNNABLE** |
| 11 | BVP driver F4 has no handler or scoring spec | yes | **NO** | **UNRUNNABLE** |
| 12 | BVP driver F3 — same | yes | **NO** | **UNRUNNABLE** |
| 13 | BVP driver F1 — same | yes | **NO** | **UNRUNNABLE** |
| 14 | Continuous-run loop STOPPED: no-signal | yes | **yes** — `claude-fw` is on PATH | ACTIONABLE |
| 15 | Fabric: 94 under-populated cards | yes | **NO** | **UNRUNNABLE** |

**9 ACTIONABLE · 4 UNRUNNABLE · 2 MISLEADING-AND-UNRUNNABLE. 6 of 15 defective (40%).**

## The defective six

### Rows 11, 12, 13, 15 — the remedy names a binary this project does not have

All four mitigations say `bin/fw …`. **There is no `bin/fw` here.** Measured:

```
$ bin/fw version
/bin/bash: line 37: bin/fw: No such file or directory
```

This project runs in shared-tooling mode: the framework is vendored at
`.agentic-framework/bin/fw` and resolved through `.framework.yaml`. `bin/fw` is the path that
exists only *inside* the framework repo. So a reader who copies the mitigation gets
"No such file or directory" — and the audit's own PRIORITY ACTIONS block reprints these four
verbatim, so they are the first four things a reader is told to run.

Rows 11–13 are **doubly** unrunnable: even with the path corrected, `fw bvp driver --add
--scoring-file` creates a *new* driver and no verb attaches a spec to an existing one (sent to
AEF under T-841). The named remedy cannot reach the thing the check flags.

### Row 10 — three separate defects in one line

1. **It reports a pass over nothing.** Forced to run, `unit-suite.sh` reports
   `runner_exit=0 (bats: 0 file(s) rc=0; pytest: 0 file(s) rc=0)` — exit 0 having measured
   nothing. `.agentic-framework/tests` **does not exist** in the vendored tree, and this
   project has no `tests/unit` either.
2. **The claim overstates what it knows.** *"tests/unit reds are invisible until it does"*
   implies hidden failing tests. There is no corpus at all. This should read NOT EVALUATED —
   the pattern four other rows in the same audit already use correctly.
3. **The remedy is unrunnable twice over.** `agents/audit/unit-suite.sh` is **not executable**
   (`rw-r--r--`), so the paste fails; and when forced it writes to
   `.agentic-framework/.context/audits/unit-suite/LATEST.yaml` while the audit looks for
   `.context/audits/unit-suite/LATEST.yaml` — **so following the remedy never clears the
   warning.** It would warn forever.

### Row 9 — the headline describes a different finding than the one it found

The check prints *"stale branches, worktrees or remote refs"*. The actual finding is
`ahead-unpushed bleeding-edge ahead=32 oldest_days=1` — an **overdue merge-back**, not a stale
branch. And the remedy leads with `git branch -d <name> (merged)`, which git would refuse:
`bleeding-edge` is **not** merged into master (`git branch --merged master` does not list it).
So the first thing the remedy tells a reader to do is inapplicable to the finding that produced
it. The second clause (`fw integrate run bleeding-edge`) is the right one and is runnable.

## The cross-cutting finding, which matters more than any single row

**Four of the fifteen are permanently vacuous here** — rows 1, 2, 3 and 8. Each is honestly
labelled `NOT EVALUATED: candidate set empty`, which is exactly right and is the pattern I spent
this morning recommending. But their candidate sets are empty because of this project's
*layout*, not because of a transient state: there are no `.py` files under `web/` or `lib/`,
no `web/templates` or `web/blueprints`, no directly-invoked scripts in the crontab. **They will
warn every day forever and can never do anything else.**

So: **honest labelling is necessary but not sufficient.** A check that is structurally unable to
have a candidate set in a given project should be *scoped out* for that project, not reported
daily as an unresolved warning. Otherwise it becomes furniture — 27% of this audit's standing
warning count is rails that cannot fire, which is the same erosion as a permanently red ratchet
(OBS-293), arriving through the honest door rather than the dishonest one.

That refines the recommendation I opened the session with. Three-valued outcomes fix the *lying*
problem. They do not fix the *noise* problem, and noise is how a reader learns to skip the
report.

## My prediction was wrong, and the reason is instructive

I predicted a high hit rate from four accidental finds — "four for four". The systematic sweep
returns **40%**, not ~100%. The accidental finds were **selection-biased**: I hit exactly the
defective rows because those were the rows I tried to *act* on, and a remedy only reveals itself
as unrunnable when someone runs it. Nine rows are fine and I never touched them, because nothing
made me. A sweep of this kind cannot be replaced by accumulating incidents.

## Filed

- **Ours:** the `bin/fw` mitigation-path defect, the permanently-vacuous rails, row 9's
  mismatched headline.
- **Upstream (AEF):** rows 10, 11–13 and 15 — the audit text, the unit-suite path mismatch and
  exec bit, and the `bin/fw` assumption all live in vendored code.
- **Nothing in `.agentic-framework/` was changed under this task.** 15 warnings' worth of
  upstream edits in one task is the unscoped building G-020 exists to prevent.
