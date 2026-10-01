#!/usr/bin/env python3
"""learning-ledger.py — the mapping loop's memory, with a human checkpoint (T-984, T-982 GO B2).

The review loop writes a `lesson` and a `lesson_destination` into every correction
(CORRECTIONS.json). Without somewhere to put them, they evaporate with the run. This tool gives
them a ledger (docs/learning-ledger.yaml) and enforces the checkpoint the operator asked for:
a single observation only PROPOSES; it is confirmed by repetition or by a human; only a confirmed
learning is promoted, and a promotion must be visible in the file it names.

  ingest <corrections.json>... [--source loop|reviewer|human|trial] [--evidence TEXT]
          each lesson becomes a proposed entry; a lesson already present (same normalised text)
          increments that entry's occurrences instead of duplicating it
  list [--status S]
  confirm <id> --by TEXT        the human checkpoint (records who/what confirmed it)
  promote <id> --where FILE --marker TEXT    | --where sidecar:<client_msg_id>
          refused unless the entry is confirmed and (for a file) the marker is in the file
  check   exit 1 if any promoted entry skipped confirmation or its marker is missing from its file

--ledger PATH overrides docs/learning-ledger.yaml (tests use it).
"""
import argparse
import json
import os
import re
import sys

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DEFAULT = os.path.join(ROOT, 'docs', 'learning-ledger.yaml')
DESTS = {'guide', 'rubric', 'validator', 'source-owner'}
SOURCES = {'loop', 'reviewer', 'human', 'trial'}


def norm(s):
    return re.sub(r'[^a-z0-9 ]', '', re.sub(r'\s+', ' ', (s or '').lower())).strip()


def load(path):
    with open(path, encoding='utf-8') as f:
        d = yaml.safe_load(f) or {}
    d.setdefault('learnings', [])
    return d


def save(path, d):
    # Keep the human-written header comment: rewrite only the body below it.
    head = ''
    if os.path.exists(path):
        lines = open(path, encoding='utf-8').read().split('\n')
        for i, l in enumerate(lines):
            if l.startswith('learnings:'):
                head = '\n'.join(lines[:i]) + '\n'
                break
    body = yaml.safe_dump({'learnings': d['learnings']}, sort_keys=False, allow_unicode=True, width=100)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(head + body)


def next_id(d):
    nums = [int(x['id'][1:]) for x in d['learnings'] if re.fullmatch(r'L\d+', str(x.get('id')))]
    return 'L%d' % (max(nums, default=0) + 1)


def problems(d):
    out = []
    for x in d['learnings']:
        i = x.get('id', '?')
        if x.get('destination') not in DESTS:
            out.append('%s: destination %r not in %s' % (i, x.get('destination'), sorted(DESTS)))
        if x.get('status') == 'promoted':
            if not x.get('confirmed_by'):
                out.append('%s: promoted without a confirmation (the human checkpoint was skipped)' % i)
            p = x.get('promoted') or {}
            where = str(p.get('where', ''))
            if where.startswith('sidecar:'):
                continue
            f = os.path.join(ROOT, where)
            if not where or not os.path.isfile(f):
                out.append('%s: promoted into %r, which does not exist' % (i, where))
            elif not p.get('marker') or p['marker'] not in open(f, encoding='utf-8').read():
                out.append('%s: promoted into %s but its marker %r is not in that file' % (i, where, p.get('marker')))
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--ledger', default=DEFAULT)
    sub = ap.add_subparsers(dest='cmd', required=True)
    g = sub.add_parser('ingest'); g.add_argument('files', nargs='+')
    g.add_argument('--source', default='loop', choices=sorted(SOURCES)); g.add_argument('--evidence', default='')
    l = sub.add_parser('list'); l.add_argument('--status')
    c = sub.add_parser('confirm'); c.add_argument('id'); c.add_argument('--by', required=True)
    p = sub.add_parser('promote'); p.add_argument('id'); p.add_argument('--where', required=True); p.add_argument('--marker')
    sub.add_parser('check')
    a = ap.parse_args(argv)
    d = load(a.ledger)
    by_id = {x['id']: x for x in d['learnings']}

    if a.cmd == 'ingest':
        added = bumped = 0
        for fn in a.files:
            for item in json.load(open(fn, encoding='utf-8')):
                lesson, dest = item.get('lesson'), item.get('lesson_destination')
                if not lesson or dest in (None, 'none'):
                    continue
                hit = next((x for x in d['learnings'] if norm(x['learning']) == norm(lesson)), None)
                if hit:
                    hit['occurrences'] = int(hit.get('occurrences', 1)) + 1
                    bumped += 1
                else:
                    d['learnings'].append({'id': next_id(d), 'learning': lesson,
                                           'evidence': a.evidence or '%s (%s %s)' % (fn, item.get('category'), item.get('element')),
                                           'source': a.source, 'destination': dest if dest in DESTS else 'guide',
                                           'status': 'proposed', 'occurrences': 1})
                    added += 1
        save(a.ledger, d)
        print('ingested: %d new proposed, %d occurrence(s) added to existing' % (added, bumped))
        return 0
    if a.cmd == 'list':
        for x in d['learnings']:
            if a.status and x.get('status') != a.status:
                continue
            print('%-4s %-9s %-12s x%-2s %s' % (x['id'], x.get('status'), x.get('destination'), x.get('occurrences', 1), x['learning']))
        return 0
    if a.cmd == 'confirm':
        x = by_id.get(a.id) or sys.exit('no such learning %s' % a.id)
        if x['status'] not in ('proposed', 'confirmed'):
            sys.exit('%s is %s; only a proposed learning can be confirmed' % (a.id, x['status']))
        x['status'], x['confirmed_by'] = 'confirmed', a.by
        save(a.ledger, d); print('%s confirmed by %s' % (a.id, a.by)); return 0
    if a.cmd == 'promote':
        x = by_id.get(a.id) or sys.exit('no such learning %s' % a.id)
        if x['status'] != 'confirmed':
            print('REFUSED: %s is %s; it must be confirmed first (the human checkpoint)' % (a.id, x['status']), file=sys.stderr)
            return 1
        if not a.where.startswith('sidecar:'):
            f = os.path.join(ROOT, a.where)
            if not a.marker or not os.path.isfile(f) or a.marker not in open(f, encoding='utf-8').read():
                print('REFUSED: %s: marker %r not found in %s; promote after the change is in the file' % (a.id, a.marker, a.where), file=sys.stderr)
                return 1
        x['status'] = 'promoted'
        x['promoted'] = {'where': a.where} if a.where.startswith('sidecar:') else {'where': a.where, 'marker': a.marker}
        save(a.ledger, d); print('%s promoted into %s' % (a.id, a.where)); return 0
    if a.cmd == 'check':
        ps = problems(d)
        for p_ in ps:
            print('LEDGER: ' + p_)
        print('ledger: %d learnings, %d problem(s)' % (len(d['learnings']), len(ps)))
        return 1 if ps else 0


if __name__ == '__main__':
    sys.exit(main())
