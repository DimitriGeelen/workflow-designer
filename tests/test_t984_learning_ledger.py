#!/usr/bin/env python3
"""T-984 (T-982 GO, slice B2): the learning ledger keeps the loop's lessons and enforces the
human checkpoint before anything becomes a rule.

Legs, each on a throwaway ledger (--ledger), never the real one:
  1. ingest: a new lesson becomes ONE proposed entry; a 'none' destination is skipped
  2. ingest again: the same lesson (different case/punctuation) bumps occurrences, no duplicate
  3. promote a PROPOSED learning -> refused (checkpoint)
  4. confirm, then promote with a marker the file does NOT contain -> refused
  5. promote with a marker the file DOES contain -> accepted, and check passes
  6. check catches a promotion whose confirmation was skipped (hand-edited ledger)
  7. check catches a promotion whose marker is not in its file (hand-edited ledger)
  8. the REAL ledger passes check
Exit 0 iff every check passes. Run: python3 tests/test_t984_learning_ledger.py
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
TOOL = os.path.join(ROOT, 'tools', 'learning-ledger.py')
results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond)))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def run(*args):
    return subprocess.run([sys.executable, TOOL] + list(args), capture_output=True, text=True, timeout=60)


def main():
    tmp = tempfile.mkdtemp(prefix='t984-')
    try:
        led = os.path.join(tmp, 'ledger.yaml')
        open(led, 'w').write('# test ledger\nlearnings: []\n')
        c1 = os.path.join(tmp, 'c1.json')
        json.dump([{'element': 'x', 'category': 'scope', 'lesson': 'Command lists are not process steps.',
                    'lesson_destination': 'rubric'},
                   {'element': 'y', 'category': 'readability', 'lesson': 'nothing to learn',
                    'lesson_destination': 'none'}], open(c1, 'w'))
        r = run('--ledger', led, 'ingest', c1)
        d = yaml.safe_load(open(led))['learnings']
        check('1. ingest: one proposed entry, the none-destination lesson skipped',
              r.returncode == 0 and len(d) == 1 and d[0]['status'] == 'proposed' and d[0]['destination'] == 'rubric',
              r.stdout.strip())
        c2 = os.path.join(tmp, 'c2.json')
        json.dump([{'element': 'z', 'category': 'scope', 'lesson': 'command LISTS are not process steps',
                    'lesson_destination': 'rubric'}], open(c2, 'w'))
        run('--ledger', led, 'ingest', c2)
        d = yaml.safe_load(open(led))['learnings']
        check('2. the same lesson again bumps occurrences, no duplicate',
              len(d) == 1 and d[0]['occurrences'] == 2, str([(x['id'], x['occurrences']) for x in d]))
        lid = d[0]['id']
        r = run('--ledger', led, 'promote', lid, '--where', 'docs/authoring-kit/RUBRIC.md', '--marker', 'are always major')
        check('3. promoting a PROPOSED learning is refused', r.returncode == 1 and 'confirmed first' in r.stderr, r.stderr.strip())
        run('--ledger', led, 'confirm', lid, '--by', 'test operator')
        r = run('--ledger', led, 'promote', lid, '--where', 'docs/authoring-kit/RUBRIC.md', '--marker', 'no such text here 9f3c')
        check('4. promotion with a marker absent from the file is refused', r.returncode == 1 and 'not found' in r.stderr, r.stderr.strip())
        r = run('--ledger', led, 'promote', lid, '--where', 'docs/authoring-kit/RUBRIC.md', '--marker', 'are always major')
        r2 = run('--ledger', led, 'check')
        check('5. promotion with a real marker is accepted and check passes',
              r.returncode == 0 and r2.returncode == 0, (r.stdout + r2.stdout).strip())
        bad = yaml.safe_load(open(led))
        bad['learnings'][0].pop('confirmed_by')
        open(led, 'w').write(yaml.safe_dump(bad))
        r = run('--ledger', led, 'check')
        check('6. check catches a promotion that skipped confirmation', r.returncode == 1 and 'checkpoint' in r.stdout, r.stdout.strip())
        bad['learnings'][0]['confirmed_by'] = 'x'
        bad['learnings'][0]['promoted'] = {'where': 'docs/authoring-kit/RUBRIC.md', 'marker': 'absent 7c1e'}
        open(led, 'w').write(yaml.safe_dump(bad))
        r = run('--ledger', led, 'check')
        check('7. check catches a promotion whose marker is not in its file', r.returncode == 1 and 'marker' in r.stdout, r.stdout.strip())
        r = run('check')
        check('8. the real ledger passes check', r.returncode == 0, r.stdout.strip())
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    failed = [n for n, ok in results if not ok]
    print('\nT-984 learning ledger: %d/%d passed' % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
