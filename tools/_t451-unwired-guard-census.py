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
Both sides come from the tree: the population is `tools/*`, the live-caller set is the
REACHABILITY CLOSURE from roots that re-execute without a task completing. No count
appears as a literal in this file. A written-down denominator is wrong the next time
anyone adds a tool, and a guard that restates its own denominator is the defect one
level up.

CLOSURE, NOT A ONE-HOP UNION (T-493)
Liveness is computed from ROOT_SOURCES outward. `tools/*` is an edge, never a root: a
tool is live only if a non-tool source reaches it, directly or through other tools that
are themselves live. The earlier version unioned every tool-to-tool reference in one
pass, which made reachability transitive through DEAD nodes and let a cluster of dead
instruments vouch for each other. That is a scan that always answers — the class this
whole file exists to count, one level up, inside the counter.

LIMIT — state it, never imply coverage (PL-148's own prescribed remedy)
Reachability is decided by TEXTUAL reference, and that cuts BOTH ways. The limit used
to be stated in one direction only, which made the statement itself the same shape as
the defect it was warning about.

  FALSE POSITIVE (reported unwired, actually reachable)
    A caller that composes a tool's path at runtime, or invokes it through a variable,
    is invisible here. This census cannot close that direction from outside.

  FALSE NEGATIVE (reported live, actually unreachable)   <- T-493, was unstated
    A reference inside a COMMENT counts as an edge. `tools/_t418-producer-attribution.py`
    is reached from `_t420-rail-attribution-gate.py`, a genuine root, by the docstring
    sentence "the miss is visible afterwards to <tool>" — prose about a compensating
    control, not a call. Measured at the time of writing: 46 of 115 tool-to-tool
    reference lines (40%) open as comments. This direction is the dangerous one, because
    it makes an unwatched instrument read as wired, and that is this file's whole
    subject. Filed separately rather than fixed here — stripping comments is a real
    change of definition and would move the count a third time in one day.
"""
import glob
import os
import re
import sys

TOOL_RE = re.compile(r'tools/([A-Za-z0-9_.\-]+\.(?:py|sh|mjs|js))')
EXT = ('py', 'sh', 'mjs', 'js')

# ROOTS: every path that re-executes WITHOUT a task completing AND is not itself a tool.
# This list is the authority the "wired" verdict is measured against — adding a wiring
# mechanism to the project means adding it here, and a mechanism absent from this list
# reports its tools as unwired, which is the safe direction.
#
# T-493: `tools/*` USED TO BE IN THIS LIST and that was the defect. Liveness was then a
# one-hop union — any tool named inside any tool read as reachable — so a tool referenced
# only by a DEAD tool was reported wired. Reachability is not transitive through dead
# nodes. `tools/*` is now a traversal EDGE (see main()), walked only from tools already
# known live, never a root. Measured at the time of the fix: 71 tools live under the flat
# union, 49 under the closure, 22 of the difference vouched for only by dead tools —
# `_t400-schema-teeth.sh` was referenced by nine dead teeth scripts, so nine dead things
# made one dead thing look alive.
ROOT_SOURCES = (
    '.claude/settings.json',                      # PreToolUse/PostToolUse hooks
    '.context/cron/*',                            # scheduled
    'tests/**/*',                                 # the test suites
    '.agentic-framework/agents/**/*.sh',          # framework agent scripts
)

# The gap register is a root, but only in the ONE field the framework executes.
# `lib/gaps.py` docstring/run_closure_gauge: the gauge command is `closure_check_command:`
# and nothing else. This file used to be grepped WHOLE, so a tool named anywhere in a
# gap's narrative prose read as wired — and that is exactly how T-492 found
# `_t418-producer-attribution.py` looking reachable: its name sits in `.concerns[25]
# .context`, a 2,362-character paragraph DESCRIBING A MEASUREMENT IT ONCE PERFORMED.
# A record of a past measurement is not the capacity to measure.
#
# Same defect as AEF's `next_id()` grepping `OBS-[0-9]+` over an inbox's message bodies,
# reported to them at rail 607 — in our own file, one day later.
GAUGE_FILE = '.context/project/concerns.yaml'
GAUGE_FIELD = 'closure_check_command'

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


def gauge_refs():
    """Tools named in a gap's `closure_check_command:` — the only executed field.

    Refuses rather than degrading: if the register cannot be parsed we have not
    enumerated a root source, and silently continuing would move tools into the
    findings column for a reason that has nothing to do with their wiring. Louder is
    not the same as correct (T-430 abstention discipline).
    """
    if not os.path.isfile(GAUGE_FILE):
        return set()
    try:
        import yaml
    except ImportError:
        refuse('PyYAML is unavailable, so %s cannot be field-scoped to %s. Grepping it '
               'whole is the T-493 defect this function exists to fix.'
               % (GAUGE_FILE, GAUGE_FIELD))
    try:
        doc = yaml.safe_load(open(GAUGE_FILE, encoding='utf-8')) or {}
    except Exception as exc:                      # noqa: BLE001 - any parse failure
        refuse('%s did not parse (%s), so a root source could not be enumerated.'
               % (GAUGE_FILE, exc))
    found = set()
    for entry in (doc.get('concerns') or []) + (doc.get('gaps') or []):
        if not isinstance(entry, dict):
            continue
        cmd = entry.get(GAUGE_FIELD)
        if isinstance(cmd, str):
            found.update(TOOL_RE.findall(cmd))
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

    # ROOTS first: reached by something that is not itself a tool.
    roots = set()
    for pattern in ROOT_SOURCES:
        roots |= read_refs(glob.glob(pattern, recursive=True))
    roots |= gauge_refs()
    # A name that resolves to no file on disk is not a caller of anything here.
    roots &= set(population)

    # Then CLOSE over tool->tool edges, walking only from tools already known live.
    # This is the T-493 fix. The edge set is the same data the old code unioned in one
    # step; the difference is entirely in the direction of travel. A dead tool's
    # references are never traversed, so dead tools can no longer vouch for each other.
    edges = {t: (read_refs(['tools/' + t]) & set(population)) - {t} for t in population}
    live = set(roots)
    frontier = set(roots)
    while frontier:
        nxt = set()
        for t in frontier:
            nxt |= edges.get(t, set())
        nxt -= live
        live |= nxt
        frontier = nxt

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
            'roots_non_tool': len(roots),
            'live_callable': len(live),
            'reached_only_via_tool_chain': len(live - roots),
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
    print('  roots (hook, cron, tests/, agent, gap gauge)     %4d  NOT itself a tool'
          % len(roots))
    print('  live-callable (closure from roots)               %4d  of which %d reached '
          'only via a live tool chain' % (len(live), len(live - roots)))
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
    print('LIMIT: reachability is decided by TEXTUAL reference to `tools/<name>`, BOTH ways.')
    print('  FALSE POSITIVE — a caller composing the path at runtime is invisible, so its')
    print('    tool is reported unwired. Cannot be closed from outside.')
    print('  FALSE NEGATIVE — a reference inside a COMMENT counts as an edge, so a tool')
    print('    merely DISCUSSED by a live tool reads as wired. 40% of tool-to-tool')
    print('    reference lines open as comments. This is the direction that hides an')
    print('    unwatched instrument, which is this census\'s own subject (T-493).')
    print('  Stated so a clean run cannot imply coverage it does not have (PL-148).')

    # ── T-491: --ratchet ────────────────────────────────────────────────────────────────
    # This census has been correct and unscheduled since T-451. Its only live caller is the
    # gap gauge in lib/gaps.py, which runs when somebody asks to close G-035 — so the count
    # (T-493: this said G-034. Derived from the register rather than remembered: G-035 is the
    # gap whose closure_check_command names this file. A wrong id in a comment that exists to
    # tell the next reader where the only caller lives sends them to the wrong gap.)
    # it produces is real and nobody is told when it grows. That is one step milder than the
    # class it measures: not unrunnable, just unwatched.
    #
    # Wiring the raw exit code into the suite is not available: it exits 1 on a pre-existing
    # backlog, so the suite would be permanently red and the redness would carry no
    # information. PL-004 (T-052) prescribed the alternative in the same sentence that named
    # the class — "wire every gate into CI over its full subject set, with a legacy allowlist
    # (with stale-entry detection)" — and only the first half was ever built.
    #
    # So the ratchet fails on MOVEMENT, in both directions:
    #   a finding not in the baseline   -> the class GREW; a new standing guard went dark
    #   a baseline entry not in findings -> it got wired or deleted; tighten the baseline
    # The second direction is the one that matters over time. Without it the baseline decays
    # into a permanent amnesty: entries that were fixed years ago keep excusing themselves,
    # and the file stops describing the tree. A baseline that never shrinks is a hand-typed
    # denominator wearing a different hat (PL-181).
    if '--ratchet' in sys.argv:
        base_path = os.path.join('tools', 'unwired-guard-baseline.txt')
        if not os.path.exists(base_path):
            print('\nRATCHET: no baseline at %s — refusing rather than minting one silently.'
                  % base_path)
            print('  A baseline created on the fly would record whatever today happens to be')
            print('  and call it approved. Create it deliberately.')
            return 2
        with open(base_path) as fh:
            baseline = {l.strip() for l in fh
                        if l.strip() and not l.lstrip().startswith('#')}
        cur = set(findings)
        grew = sorted(cur - baseline)
        fixed = sorted(baseline - cur)
        print('\nRATCHET: baseline %d, current findings %d' % (len(baseline), len(cur)))
        if not grew and not fixed:
            print('  no movement — the backlog neither grew nor shrank.')
            return 0
        if grew:
            print('  GREW by %d — a standing guard lost its last live caller:' % len(grew))
            for t in grew:
                print('    + %s' % t)
        if fixed:
            print('  SHRANK by %d — now wired or gone, so remove from the baseline:'
                  % len(fixed))
            for t in fixed:
                print('    - %s' % t)
            print('  (A stale baseline entry is a standing exemption for a problem that no')
            print('   longer exists. Leaving it costs nothing today and hides the next one.)')
        return 1

    return 1 if findings else 0


if __name__ == '__main__':
    sys.exit(main())
