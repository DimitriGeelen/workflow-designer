# T-843 Route 3 — write-time advisory hook: handover for the operator

**Status:** built and tested; **NOT installed.** Installing it requires editing
`.claude/settings.json`, which the agent is structurally blocked from writing (B-005), with no
`settings.local.json` side door. This document is the exact change so you can apply it in one
paste, plus an honest account of whether you should.

## What it is

`tools/hooks/warn-uncontrolled-absence.sh` — a **PostToolUse advisory**. When a write lands in
a `.tasks/{active,completed}/*.md` file, it re-reads that file's `## Verification` block, runs
the same classifier the close gate uses, and prints a warning to stderr if any leg asserts an
absence with no control.

**It never blocks. It always exits 0.** That is deliberate and not timidity: an author
legitimately writes the absence assertion first and its control second, so a hook that refused
the intermediate state would make the correct workflow impossible. Refusal belongs at close,
where the block is finished — and that gate already exists (this task's main deliverable).

## Why it is worth having anyway

The close gate is sufficient for correctness and insufficient for *feel*. It fires when the
author believes the work is done, which is the moment a gate is most resented and most likely
to earn a standing bypass. This hook fires while the author still has the context to fix it in
one line. **If it works, the close gate should almost never trigger** — which is the outcome
you want from an enforcement point.

## The change to apply — two commands (T-847)

**Superseded the hand-edit.** The original version of this doc gave a JSON fragment to paste,
which was a poor handover: `.claude/settings.json` already carries a `Write|Edit` PostToolUse
group holding `fw hook commit-cadence`, so pasting a *new* group with the same matcher is valid
JSON and quietly duplicated semantics. The fragment had to be merged into the existing group by
hand. A tested, idempotent registrar does it instead.

Look first if you like:

```
cd /opt/832-Workflow-designer && python3 tools/hooks/install-absence-hook.py --dry-run
```

Then apply, and refresh the baseline:

```
cd /opt/832-Workflow-designer && python3 tools/hooks/install-absence-hook.py
```
```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw enforcement baseline
```

The second is not optional: without it `fw doctor` reports a standing "Enforcement baseline
CHANGED" FAIL that accumulates silently (L-398 — it bit T-1849, T-1730 and T-1731 each in turn).

The registrar is idempotent (re-running reports "already registered" and writes nothing), appends
rather than duplicating, and refuses outright if the settings file is not valid JSON rather than
rewriting a half-parsed file. All four behaviours were verified against scratch copies before this
was offered — never against the live file.

## Verified before handover

- Fires on a file with an uncontrolled leg, printing the leg and both repair routes.
- Silent on a clean file.
- Exits 0 in both cases (advisory, as designed).
- Degrades silently when the classifier is absent — no output rather than a guess, the same
  NOT-EVALUATED principle the close gate applies to its own dependency.
- Only inspects task files; every other write path exits immediately.

## The caveat that used to be here is GONE — recommendation reversed (T-847)

This section previously said **do not install yet**: the hook warned on `T-592`, that warning was
a false positive, and a nagging advisory is how advisories get muted. That advice was right when
written and is now stale.

**T-844 resolved it.** The false positive was narrower than OBS-376 claimed — one leg, not a
class — and rather than change a classifier that now gates closes, T-592's leg was given a
control that is worth having on its own terms (it pins the fixture string the demonstration
depends on). Re-verified: the hook produces **no output** against `T-592` now, and `active/`
carries zero uncontrolled legs, so on a clean corpus the advisory is silent.

**Recommendation is therefore: safe to install.** Recorded as a reversal with its cause, so the
change of advice is traceable rather than mysterious.

## What is already live without you doing anything

The close gate itself needs no configuration: it is wired into `update-task.sh`'s
pre-verification phase beside `find_port_literals` and `find_unjudged_test_runs`. Route 3 is
purely the early-warning addition.
