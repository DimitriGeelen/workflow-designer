#!/usr/bin/env python3
"""_corpus-adopt-verify.py — T-145 gate for adopting editor-saved layouts.

For each of the 11 maps saved via "Save to project" (Jul 6 sessions), assert:
  1. rendered/<id>.bpmn parses as well-formed XML
  2. every .editor-versions/<id>/v*.bpmn snapshot parses as well-formed XML
  3. rendered/<id>.bpmn is byte-identical to the latest saved version (index.json max v)

Stdlib only. Exit 0 = all pass; exit 1 = any failure (P-011 reads this).
"""
import glob
import json
import os
import sys
import xml.dom.minidom

MAPS = [
    'arc-lifecycle', 'assumption-validation', 'context-memory',
    'error-escalation-ladder', 'fabric-blast-radius', 'git-commit-flow',
    'harvest-pipeline', 'healing-loop', 'resume-status', 'task-gate',
    'tier0-escalation',
]

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
RENDERED = os.path.join(ROOT, 'examples', 'aef-processes', 'rendered')
STORE = os.path.join(ROOT, '.editor-versions')

fails = []


def parses(path):
    try:
        xml.dom.minidom.parse(path)
        return True
    except Exception as e:
        fails.append('parse %s: %s' % (path, e))
        return False


def main():
    for id_ in MAPS:
        rendered = os.path.join(RENDERED, id_ + '.bpmn')
        idx_path = os.path.join(STORE, id_, 'index.json')
        if not os.path.exists(rendered):
            fails.append('missing rendered %s' % rendered)
            continue
        if not os.path.exists(idx_path):
            fails.append('missing store %s' % idx_path)
            continue
        parses(rendered)
        for snap in sorted(glob.glob(os.path.join(STORE, id_, 'v*.bpmn'))):
            parses(snap)
        idx = json.load(open(idx_path))
        latest = max(e['v'] for e in idx)
        latest_bpmn = os.path.join(STORE, id_, 'v%d.bpmn' % latest)
        with open(rendered, 'rb') as a, open(latest_bpmn, 'rb') as b:
            if a.read() != b.read():
                fails.append('%s: rendered != latest v%d' % (id_, latest))
            else:
                print('PASS %s: parses + rendered == v%d' % (id_, latest))

    if fails:
        print('\nFAIL (%d):' % len(fails))
        for f in fails:
            print('  - ' + f)
        sys.exit(1)
    print('\nAll %d maps: rendered + snapshots parse, rendered == latest save.' % len(MAPS))
    sys.exit(0)


if __name__ == '__main__':
    main()
