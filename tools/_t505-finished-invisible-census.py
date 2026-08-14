#!/usr/bin/env python3
"""Census: tasks in .tasks/active/ whose acceptance criteria are ALL ticked.

WHY THIS EXISTS
    `fw task verify` enumerates tasks by their UNCHECKED Human ACs. That is the right
    surface for "what does the operator still have to look at", and it is structurally
    incapable of answering the opposite question: which tasks have nothing left to look
    at and were simply never transitioned. A task becomes invisible to that surface at
    the exact moment it becomes closable.

    T-502 named this ("`fw task verify` cannot see tasks whose Human ACs are already
    ticked but which were never transitioned"). T-264 is a witness: built 2026-07-27,
    5/5 Agent ACs, 1/1 Human [REVIEW] ticked by the operator, reviewer verdict PASS,
    full Verification block green on re-run 2026-08-14 — and `status: started-work`,
    listed by nothing, for eighteen days.

WHAT IT DOES NOT DO
    It does not close anything and must not. Every task it can find is `owner: human`
    or carries a Human AC; transitioning those is not delegated to an agent. The output
    is a list plus the evidence that justifies each row, for a human to act on. A
    "batch-close stale tasks" mode would be the precise thing CLAUDE.md's Human Task
    Completion Rule forbids.

WHY THE DENOMINATOR IS PRINTED ON EVERY RUN
    A census that prints only its hits is indistinguishable from one whose scan came up
    empty for a mechanical reason — the `every()`-over-an-empty-array shape that made
    three legs of T-233's guard report PASS while rendering zero cards. So each run
    states tasks scanned, tasks with a parseable AC block, and tasks skipped with the
    reason. `0 finished-and-invisible` is only a verdict if the denominator is non-zero.

HTML COMMENT SPANS ARE STRIPPED FIRST, AND THAT IS LOAD-BEARING
    The task template carries EXAMPLE acceptance criteria inside `<!-- ... -->` — including
    a literal `- [ ] [REVIEW] Dashboard renders correctly`. Counting those would make
    every task carrying the unedited template look permanently unfinished, which is the
    inverse error and would read as a clean result. Spans are removed before any
    checkbox is counted. Unlike the P-011 gate's stripper (OBS-043) this operates on
    prose, not on shell, so there is no quoting or command-boundary hazard here.

EXIT CODES
    0  scan completed and reported (whether or not it found anything)
    2  refusal — could not establish a population; nothing was measured, and this is
       NOT a pass. Never 1: a verdict code must not be reachable by a broken scan
       (T-430 abstention discipline; the failure mode T-495 hit twice).
"""

import glob
import json
import os
import re
import sys

CHECKBOX = re.compile(r'^\s*-\s+\[([ xX])\]')
COMMENT_SPAN = re.compile(r'<!--.*?-->', re.DOTALL)
FRONTMATTER_FIELD = re.compile(r'^(id|status|owner|name|horizon):\s*(.*)$')


def refuse(msg):
    sys.stderr.write('REFUSING: %s\nNothing was measured; this is not a pass.\n' % msg)
    raise SystemExit(2)


def read_frontmatter(text):
    """Return the leading YAML block's scalar fields. Absent block -> empty dict."""
    if not text.startswith('---'):
        return {}
    end = text.find('\n---', 3)
    if end == -1:
        return {}
    out = {}
    for line in text[3:end].splitlines():
        m = FRONTMATTER_FIELD.match(line)
        if m:
            out[m.group(1)] = m.group(2).strip().strip('"').strip("'")
    return out


def ac_block(text):
    """The `## Acceptance Criteria` section, comment spans removed.

    Returns None when the heading is absent — distinct from an empty block, because
    'this task has no AC section' and 'this task has an AC section with no boxes' are
    different facts and only the second is a bookkeeping problem.
    """
    m = re.search(r'^##\s+Acceptance Criteria\s*$', text, re.MULTILINE)
    if not m:
        return None
    rest = text[m.end():]
    nxt = re.search(r'^##\s+(?!#)', rest, re.MULTILINE)
    if nxt:
        rest = rest[:nxt.start()]
    return COMMENT_SPAN.sub('', rest)


def count_boxes(block):
    """(agent_total, agent_ticked, human_total, human_ticked) split by sub-heading.

    Boxes appearing before any `### Agent` / `### Human` sub-heading are attributed to
    Agent — that is the documented fallback for tasks written without the split (CLAUDE.md:
    'or all ACs if no split headers').
    """
    section = 'agent'
    counts = {'agent': [0, 0], 'human': [0, 0]}
    for line in block.splitlines():
        head = re.match(r'^###\s+(Agent|Human)\s*$', line)
        if head:
            section = head.group(1).lower()
            continue
        box = CHECKBOX.match(line)
        if box:
            counts[section][0] += 1
            if box.group(1) in ('x', 'X'):
                counts[section][1] += 1
    return (counts['agent'][0], counts['agent'][1],
            counts['human'][0], counts['human'][1])


def main():
    root = os.environ.get('T505_ROOT')
    if root:
        os.chdir(root)

    if not os.path.isdir('.tasks/active'):
        refuse('.tasks/active is missing, so there is no population to range over.')

    paths = sorted(glob.glob('.tasks/active/*.md'))
    if not paths:
        refuse('.tasks/active holds no *.md, so "0 finished-and-invisible" would be a '
               'verdict about nothing.')

    scanned = 0
    parsed = 0
    skipped = []
    hits = []

    for path in paths:
        scanned += 1
        try:
            with open(path, encoding='utf-8') as fh:
                text = fh.read()
        except OSError as exc:
            skipped.append({'file': os.path.basename(path), 'why': 'unreadable: %s' % exc})
            continue

        fm = read_frontmatter(text)
        tid = fm.get('id') or os.path.basename(path).split('-')[0] + '-?'

        block = ac_block(text)
        if block is None:
            skipped.append({'task': tid, 'why': 'no "## Acceptance Criteria" heading'})
            continue

        a_tot, a_ok, h_tot, h_ok = count_boxes(block)
        total = a_tot + h_tot
        if total == 0:
            skipped.append({'task': tid,
                            'why': 'AC section present but carries no checkboxes'})
            continue

        parsed += 1
        if (a_ok + h_ok) != total:
            continue
        if fm.get('status') == 'work-completed':
            # Already transitioned; it sits in active/ as partial-complete bookkeeping.
            # Still reported, separately, because it is equally closable and equally
            # invisible to `fw task verify`.
            state = 'transitioned-but-not-archived'
        else:
            state = 'never-transitioned'

        hits.append({
            'task': tid,
            'name': fm.get('name', ''),
            'status': fm.get('status', '?'),
            'owner': fm.get('owner', '?'),
            'horizon': fm.get('horizon', '?'),
            'agent_acs': '%d/%d' % (a_ok, a_tot),
            'human_acs': '%d/%d' % (h_ok, h_tot),
            'state': state,
            'file': path,
        })

    result = {
        'scanned': scanned,
        'parsed': parsed,
        'skipped': skipped,
        'finished_and_invisible': hits,
    }

    if '--json' in sys.argv:
        print(json.dumps(result, indent=2))
        return 0

    print('== Finished-and-invisible census (T-505) ==')
    print('DENOMINATOR: %d task file(s) scanned, %d with a countable AC block, '
          '%d skipped' % (scanned, parsed, len(skipped)))
    if parsed == 0:
        refuse('no task file yielded a countable AC block, so any verdict below would '
               'be about an empty population.')
    for s in skipped:
        print('  skipped %-8s %s' % (s.get('task', s.get('file', '?')), s['why']))
    print()
    if not hits:
        print('RESULT: 0 of %d — no task has every AC ticked while still sitting in '
              'active/.' % parsed)
        return 0
    print('RESULT: %d of %d task(s) have EVERY acceptance criterion ticked and are '
          'still in .tasks/active/' % (len(hits), parsed))
    print('These are invisible to `fw task verify`, which lists tasks by their '
          'UNCHECKED Human ACs.')
    print()
    for h in hits:
        print('  %-8s %s' % (h['task'], h['name'][:80]))
        print('           status=%-16s owner=%-6s horizon=%-6s  Agent %s  Human %s'
              % (h['status'], h['owner'], h['horizon'], h['agent_acs'], h['human_acs']))
        print('           %s' % h['state'])
    print()
    print('NOT CLOSED BY THIS TOOL. Every row is human-owned or carries a Human AC; '
          'transitioning them is the operator\'s.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
