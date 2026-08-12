#!/usr/bin/env python3
"""_t451-unwired-guard-census.py — how many tools/ instruments have no live caller.

A `## Verification` block is a ONE-SHOT COMPLETION GATE, not a standing guard.
P-011 executes a task's Verification block on the `--status work-completed`
transition and at no other time. So an instrument whose only call site is a task's
Verification block runs exactly once — at that task's completion — and never again.
Once the task moves to `.tasks/completed/`, the instrument is not merely unrun; it is
unrunnable by anything in the tree, while still reading as a wired guard to anyone
who greps for its name and finds a Verification line.

PL-148 (T-426) named this mechanism from three anecdotes and called one of them
"exiting 1 into a void". T-450 hit the fourth — `_norec-verify.py`, the operator's
approvals-queue guard, whose only caller was `.tasks/completed/T-236-*.md`. It last
ran on 2026-07-22 with the queue at 0 NO-REC; the queue is now 14, and nothing in the
tree was in a position to notice. Nobody had ever counted the class. This counts it.

WHAT IS AND IS NOT A FINDING
Not every one-shot is a defect. `*-teeth.sh` and `*-mutation-check.sh` are mutation
tests: they exist to prove a guard HAS teeth at the moment it is authored, and running
them once is the whole point. A standing guard is different — it asserts an invariant
that can regress tomorrow. This tool does NOT try to tell them apart per file, because
that distinction is intent, and guessing at intent produces the confident-but-unfounded
verdict T-440 was about. It splits by naming convention, reports both counts, and
leaves the judgement to a reader who can see which is which.

EXIT CODES
  0  every standing-guard instrument has a live caller
  1  at least one non-teeth instrument has no live caller
  2  a side could not be enumerated — nothing was measured, and this is NOT a pass

`--json` emits the gauge envelope `lib/gaps.py` reads for one-click gap closure, and
deliberately exits 0 for BOTH verdicts, putting READY/NOT_READY in the payload. The
gauge maps any non-zero exit to UNKNOWN, so exiting 1 on findings would make "measured,
and the answer is no" indistinguishable from "the gauge is broken" — collapsing the
abstention channel this census exists to keep open. Refusal still exits 2, which the
gauge reads as UNKNOWN, and that mapping is correct: a refusal IS a gauge that could
not measure.

DERIVED, NOT RESTATED (PL-158)
Both sides come from the tree: the population is `tools/*`, the live-caller set is
every path that re-executes without a task completing. No count appears as a literal
in this file. A written-down denominator is wrong the next time anyone adds a tool,
and a guard that restates its own denominator is the defect one level up.

LIMIT — state it, never imply coverage (PL-148's own prescribed remedy)
Reachability is decided by TEXTUAL reference. A caller that composes a tool's path at
runtime, or invokes it through a variable, is invisible here and its tool is reported
unwired. That is a false-positive direction this census cannot close from outside, so
the output says so rather than letting a number imply a certainty it lacks.
"""
import glob
import os
import re
import sys

TOOL_RE = re.compile(r'tools/([A-Za-z0-9_.\-]+\.(?:py|sh|mjs|js))')
EXT = ('py', 'sh', 'mjs', 'js')

# Every path that re-executes WITHOUT a task completing. This list is the authority the
# "wired" verdict is measured against — adding a wiring mechanism to the project means
# adding it here, and a mechanism absent from this list reports its tools as unwired,
# which is the safe direction.
LIVE_SOURCES = (
    '.claude/settings.json',                      # PreToolUse/PostToolUse hooks
    '.context/cron/*',                            # scheduled
    'tests/**/*',                                 # the test suites
    'tools/*',                                    # tool-invokes-tool chains
    '.agentic-framework/agents/**/*.sh',          # framework agent scripts
    '.context/project/concerns.yaml',             # gap closure conditions that RUN
)

# Instruments that are one-shot BY DESIGN. Teeth prove a guard can fail at authoring
# time; a mutation-check proves a check notices a mutation. Both are complete once they
# have run. Held as a naming convention rather than a per-file judgement, and reported
# separately so a reader can see exactly what was excused and disagree with it.
ONE_SHOT_BY_DESIGN = ('-teeth.sh', '-teeth.py', '-mutation-check.sh',
                      '-probe.sh', '-probe.py', '-probe.mjs')


def refuse(msg):
    """Stop without a verdict. Exit 2, never 0, never 1 (T-430 abstention discipline)."""
    sys.stderr.write('REFUSING: ' + msg + '\nNothing was measured; this is not a pass.\n')
    raise SystemExit(2)


def read_refs(paths):
    found = set()
    for p in paths:
        if not os.path.isfile(p):
            continue
        try:
            found.update(TOOL_RE.findall(open(p, encoding='utf-8', errors='replace').read()))
        except OSError:
            continue
    return found


def verification_refs(task_paths):
    """tool -> [task ids] for tools named in a task's ## Verification block."""
    out = {}
    for p in task_paths:
        s = open(p, encoding='utf-8', errors='replace').read()
        m = re.search(r'^## Verification\s*$(.*?)(?=^## |\Z)', s, re.M | re.S)
        if not m:
            continue
        body = '\n'.join(l for l in m.group(1).splitlines() if not l.strip().startswith('#'))
        tid = re.match(r'(T-\d+)', os.path.basename(p))
        for t in set(TOOL_RE.findall(body)):
            out.setdefault(t, []).append(tid.group(1) if tid else os.path.basename(p))
    return out


def main():
    root = os.environ.get('T451_ROOT')
    if root:
        os.chdir(root)

    if not os.path.isdir('tools'):
        refuse('no tools/ directory here, so there is no population to range over.')
    population = sorted(os.path.basename(p) for p in glob.glob('tools/*')
                        if os.path.isfile(p) and p.rsplit('.', 1)[-1] in EXT)
    if not population:
        refuse('tools/ holds no *.{%s}, so "0 unwired" would be a verdict about nothing.'
               % ','.join(EXT))
    for d in ('.tasks/active', '.tasks/completed'):
        if not os.path.isdir(d):
            refuse('%s is missing, so the caller set cannot be enumerated and every '
                   'instrument would read as unwired.' % d)

    live = set()
    for pattern in LIVE_SOURCES:
        live |= read_refs(glob.glob(pattern, recursive=True))
    # A name that resolves to no file on disk is not a caller of anything here.
    live &= set(population)

    done = verification_refs(sorted(glob.glob('.tasks/completed/*.md')))
    active = verification_refs(sorted(glob.glob('.tasks/active/*.md')))

    # An ACTIVE task's Verification block is a pending one-shot, not a standing caller:
    # it runs once, when that task completes, and then joins the dead set. It is counted
    # in its own column rather than as live, because folding it into "wired" is exactly
    # how every instrument in this census looked wired on the day it was written.
    pending = sorted(t for t in population if t in active and t not in live)
    unwired = sorted(t for t in population if t not in live and t not in active)
    excused = [t for t in unwired if t.endswith(ONE_SHOT_BY_DESIGN)]
    findings = [t for t in unwired if t not in excused]
    orphans = [t for t in findings if t not in done]

    if '--json' in sys.argv:
        import json
        print(json.dumps({
            'verdict': 'READY' if not findings else 'NOT_READY',
            'ready': not findings,
            'population': len(population),
            'live_callable': len(live),
            'pending_one_shot': len(pending),
            'no_live_caller': len(unwired),
            'excused_one_shot_by_design': len(excused),
            'findings': len(findings),
            'never_referenced_by_any_task': len(orphans),
            'findings_files': findings,
            'limit': 'reachability decided by textual reference to tools/<name>; a caller '
                     'composing the path at runtime is invisible and its tool reads unwired',
        }, indent=2))
        return 0        # see the docstring: the verdict is the payload, not the rc

    print('=== T-451: instruments with no live caller ===')
    print()
    print('  population                                       %4d  tools/*.{%s} on disk'
          % (len(population), ','.join(EXT)))
    print('  live-callable                                    %4d  hook, cron, tests/, '
          'tool-chain, agent, gap condition' % len(live))
    print('  pending one-shot (ACTIVE task Verification only)  %4d  will run once, then '
          'join the set below' % len(pending))
    print('  NO live caller                                   %4d' % len(unwired))
    print('    one-shot BY DESIGN (teeth/mutation-check/probe) %4d  excused by naming '
          'convention' % len(excused))
    print('    FINDINGS — read as standing guards             %4d' % len(findings))
    print('      never referenced by ANY task at all           %4d' % len(orphans))
    print()
    if findings:
        print('FINDINGS — each has run at most once, at the completion of the task named,')
        print('and cannot be re-run by anything in this tree:')
        for t in findings:
            where = ','.join(sorted(set(done.get(t, [])))) or '** NO CALLER ANYWHERE **'
            print('  %-42s last ran at: %s' % (t, where[:60]))
        print()
    print('LIMIT: reachability is decided by TEXTUAL reference to `tools/<name>`. A caller')
    print('  that composes the path at runtime is invisible here and its tool is reported')
    print('  unwired. That false-positive direction cannot be closed from outside, and is')
    print('  stated so a clean run cannot imply coverage it does not have (PL-148).')
    return 1 if findings else 0


if __name__ == '__main__':
    sys.exit(main())
