#!/usr/bin/env python3
"""_corpus-adopt-verify.py — T-145 gate for adopting editor-saved layouts.

For each of the 11 maps saved via "Save to project" (Jul 6 sessions), assert:
  1. rendered/<id>.bpmn parses as well-formed XML
  2. every .editor-versions/<id>/v*.bpmn snapshot parses as well-formed XML
  3. every version index.json lists has its v<N>.bpmn snapshot
(Assertion 3 used to be "rendered/<id>.bpmn is byte-identical to the latest saved version"; retired by T-1403, see main.)

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
        ok = parses(rendered)
        snaps = sorted(glob.glob(os.path.join(STORE, id_, 'v*.bpmn')))
        for snap in snaps:
            ok = parses(snap) and ok
        idx = json.load(open(idx_path))
        # Every version the index lists has its snapshot (the designer's Versions panel restores from these).
        for e in idx:
            p = os.path.join(STORE, id_, 'v%d.bpmn' % e['v'])
            if not os.path.exists(p):
                fails.append('%s: index lists v%d but %s is missing' % (id_, e['v'], p))
                ok = False
        # T-1403: assertion 3 ("rendered == the latest save") is retired. It guarded T-145's one-time adoption of these
        # 11 editor-saved layouts (2026-07-09) and held, byte for byte, from T-300's re-bake (2026-07-29) until T-1168
        # (2026-10-13), which deliberately rewrote rendered/ with the activities-only node ids (T-1094 GO, option 2) and
        # left the version store as it was. Since then rendered/ is canonical on its own; requiring it to equal an older
        # save would only ever be red. Operator's choice, 2026-11-12 (T-1403 option A): retire it, keep the rest.
        if ok:
            print('PASS %s: rendered + %d snapshot(s) parse; index complete' % (id_, len(snaps)))

    if fails:
        print('\nFAIL (%d):' % len(fails))
        for f in fails:
            print('  - ' + f)
        sys.exit(1)
    print('\nAll %d maps: rendered + snapshots parse, every indexed version present.' % len(MAPS))
    sys.exit(0)


if __name__ == '__main__':
    main()
