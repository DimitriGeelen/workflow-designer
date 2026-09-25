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

## The change to apply

Register it under `PostToolUse` for `Write|Edit`. If that matcher already has entries, append
this to its `hooks` array rather than replacing it:

```json
{
  "matcher": "Write|Edit",
  "hooks": [
    {
      "type": "command",
      "command": "$CLAUDE_PROJECT_DIR/tools/hooks/warn-uncontrolled-absence.sh"
    }
  ]
}
```

**After editing `.claude/settings.json`, refresh the enforcement baseline** or `fw doctor` will
report a standing FAIL ("Enforcement baseline CHANGED") that accumulates silently — L-398,
which bit T-1849/T-1730/T-1731 each in turn:

```
cd /opt/832-Workflow-designer && .agentic-framework/bin/fw enforcement baseline
```

## Verified before handover

- Fires on a file with an uncontrolled leg, printing the leg and both repair routes.
- Silent on a clean file.
- Exits 0 in both cases (advisory, as designed).
- Degrades silently when the classifier is absent — no output rather than a guess, the same
  NOT-EVALUATED principle the close gate applies to its own dependency.
- Only inspects task files; every other write path exits immediately.

## One caveat you should know before installing

**It will currently warn on `T-592`, and that warning is a false positive.** Not the hook's
fault: the census's `SEARCH_SOURCED` test lacks the command-boundary anchoring its form
patterns have, so the literal word `grep` inside a quoted `eval` payload reads as a search
invocation. Filed as **OBS-376**, deliberately not worked around — fitting the corpus to the
instrument would make the corpus number less meaningful.

So: installing this now means one recurring nag on one task until OBS-376 is fixed. A nagging
advisory is how advisories get muted, so **the defensible order is OBS-376 first, then install
this.** I would not install it today. That is a recommendation, not a decision — the config is
yours either way, and the hook is ready when you want it.

## What is already live without you doing anything

The close gate itself needs no configuration: it is wired into `update-task.sh`'s
pre-verification phase beside `find_port_literals` and `find_unjudged_test_runs`. Route 3 is
purely the early-warning addition.
