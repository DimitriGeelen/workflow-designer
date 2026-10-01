#!/usr/bin/env python3
"""T-983 (T-982 GO, slice B1): the review loop ships in the authoring kit, and works.

No LLM runs here. The loop's ORCHESTRATION is tested with stub agents standing in for the
configured generator and reviewer, which is exactly the seam loop.sh exposes
(KIT_GENERATOR_CMD / KIT_REVIEWER_CMD). The reviewer's JUDGMENT is what calibration measures, and
a real calibration run (GLM-5.2: 3/3 caught, 0 false findings) is recorded in expected.json.

Legs:
  1. a built kit contains the loop files and calibration/, all covered by SHA256SUMS
  2. calibration/clean.bpmn validates with 0 errors, and every citation is verbatim from SOURCE.md
  3. every defect expected.json names is REALLY planted (checked per defect, not by id presence)
  4. loop.sh refuses to start without its two agent commands; --calibrate without a reviewer
  5. --calibrate PASSES with a reviewer that reports exactly the planted defects
  6. --calibrate FAILS with a blind reviewer (finds nothing) -- the teeth for leg 5
  7. --calibrate FAILS with a noisy reviewer (a finding on the clean map)
  8. the full loop with a stub generator and a clean-reporting reviewer stops DONE in round 1

Exit 0 iff every check passes. Run: python3 tests/test_t983_review_loop_kit.py
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
BUILDER = os.path.join(ROOT, 'tools', 'build-authoring-kit.py')
B = '{http://www.omg.org/spec/BPMN/20100524/MODEL}'
A = '{http://anchorpoint.framework/aef/extensions}'

STUB = r'''
import json, os, shutil, sys
mode, kit = sys.argv[1], sys.argv[2]
cal = os.path.join(kit, "calibration")
if mode == "gen":
    if os.path.exists("REVIEW.json"):           # correct step: nothing to change
        json.dump([], open("CORRECTIONS.json", "w"))
    else:
        shutil.copyfile(os.path.join(cal, "clean.bpmn"), "map.bpmn")
    sys.exit(0)
planted = "send-payment-reminder" in open("map.bpmn").read()
if mode == "good":
    out = [{"element": e["element"], "category": e["category"], "severity": "major"}
           for e in json.load(open(os.path.join(cal, "expected.json")))["planted"]] if planted else []
elif mode == "blind":
    out = []
elif mode == "noisy":
    out = [{"element": "pick-parts", "category": "readability", "severity": "minor"}]
json.dump(out, open("REVIEW.json", "w"))
'''

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond)))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def run(args, env=None, cwd=None):
    return subprocess.run(args, capture_output=True, text=True, env=env, cwd=cwd, timeout=120)


def main():
    tmp = tempfile.mkdtemp(prefix='t983-')
    try:
        kit = os.path.join(tmp, 'kit')
        r = run([sys.executable, BUILDER, '--version', '0.0.0-t983', '--out', kit])
        if r.returncode != 0:
            print('COULD-NOT-MEASURE: build failed: %s' % r.stderr[-300:])
            return 3
        cal = os.path.join(kit, 'calibration')

        # 1 ------------------------------------------------------------------------------
        want = ['CORRECT.md', 'GENERATE.md', 'REVIEW.md', 'RUBRIC.md', 'loop.sh',
                'calibration/SOURCE.md', 'calibration/clean.bpmn', 'calibration/expected.json',
                'calibration/planted.bpmn']
        sums = {l.split('  ', 1)[1] for l in open(os.path.join(kit, 'SHA256SUMS')).read().splitlines() if l}
        check('1. loop files and calibration/ are in the kit and in SHA256SUMS',
              all(w in sums and os.path.isfile(os.path.join(kit, w)) for w in want),
              'missing %s' % [w for w in want if w not in sums])
        check('1b. loop.sh is executable', os.access(os.path.join(kit, 'loop.sh'), os.X_OK))

        # 2 ------------------------------------------------------------------------------
        r = run([sys.executable, os.path.join(kit, 'validate-workflow.py'), os.path.join(cal, 'clean.bpmn')])
        check('2a. clean.bpmn validates with 0 errors', r.returncode in (0, 1), r.stdout[-160:])
        src = re.sub(r'\s+', ' ', open(os.path.join(cal, 'SOURCE.md')).read())
        root = ET.parse(os.path.join(cal, 'clean.bpmn')).getroot()
        quotes = [m.group(1) for d in root.iter(B + 'documentation')
                  for m in [re.search(r'source:\s*"(.*)"', d.text or '', re.S)] if m]
        bad = [q for q in quotes if re.sub(r'\s+', ' ', q).strip() not in src]
        check('2b. every clean.bpmn citation is verbatim from SOURCE.md',
              len(quotes) >= 10 and not bad, '%d quotes, %d not verbatim' % (len(quotes), len(bad)))

        # 3 ------------------------------------------------------------------------------
        p = ET.parse(os.path.join(cal, 'planted.bpmn')).getroot()
        lanes = {l.get('id'): l for l in p.iter(B + 'lane')}
        flows = {(f.get('sourceRef'), f.get('targetRef')) for f in p.iter(B + 'sequenceFlow')}
        wh = [m.get('authority') for m in lanes['Lane_warehouse'].iter(A + 'laneMeta')]
        reminder = [d.text for t in p.iter(B + 'task') if t.get('id') == 'send-payment-reminder'
                    for d in t.iter(B + 'documentation')]
        check('3a. planted: warehouse lane really marked authority', wh == ['authority'], str(wh))
        check('3b. planted: inspection really wired between picking and packing',
              ('pick-parts', 'quality-inspection') in flows and ('quality-inspection', 'pack-order') in flows)
        check('3c. planted: the reminder step really exists, with a citation NOT in the source',
              reminder and re.search(r'"(.*)"', reminder[0]) and
              re.search(r'"(.*)"', reminder[0]).group(1) not in src)

        # 4 ------------------------------------------------------------------------------
        loop = os.path.join(kit, 'loop.sh')
        env0 = {k: v for k, v in os.environ.items() if not k.startswith('KIT_')}
        r = run(['bash', loop, os.path.join(tmp, 'w0'), os.path.join(cal, 'SOURCE.md')], env=env0)
        check('4a. loop.sh refuses without KIT_GENERATOR_CMD / KIT_REVIEWER_CMD',
              r.returncode == 2 and 'KIT_GENERATOR_CMD' in r.stderr and 'KIT_REVIEWER_CMD' in r.stderr,
              r.stderr.strip()[-160:])
        r = run(['bash', loop, '--calibrate', os.path.join(tmp, 'c0')], env=env0)
        check('4b. --calibrate refuses without KIT_REVIEWER_CMD', r.returncode == 2)

        stub = os.path.join(tmp, 'stub.py')
        open(stub, 'w').write(STUB)

        def env(**kw):
            e = dict(env0)
            e.update({k: 'python3 %s %s %s' % (stub, v, kit) for k, v in kw.items()})
            return e

        # 5 / 6 / 7 ----------------------------------------------------------------------
        for leg, mode, want_rc, label in (('5', 'good', 0, 'PASSES with a reviewer that catches every planted defect'),
                                          ('6', 'blind', 1, 'FAILS with a blind reviewer'),
                                          ('7', 'noisy', 1, 'FAILS with a reviewer that flags the clean map')):
            r = run(['bash', loop, '--calibrate', os.path.join(tmp, 'cal-' + mode)],
                    env=env(KIT_REVIEWER_CMD=mode))
            verdict = 'CALIBRATION: PASS' if want_rc == 0 else 'CALIBRATION: FAIL'
            check('%s. --calibrate %s' % (leg, label), r.returncode == want_rc and verdict in r.stdout,
                  'rc=%d %s' % (r.returncode, (r.stdout.strip().splitlines() or [''])[-1] if r.stdout else r.stderr[-120:]))

        # 8 ------------------------------------------------------------------------------
        wd = os.path.join(tmp, 'loop')
        r = run(['bash', loop, wd, os.path.join(cal, 'SOURCE.md'), '3'],
                env=env(KIT_GENERATOR_CMD='gen', KIT_REVIEWER_CMD='blind'))
        log = open(os.path.join(wd, 'LOOP.txt')).read() if os.path.isfile(os.path.join(wd, 'LOOP.txt')) else ''
        check('8. full loop with stub agents stops DONE on a clean round-1 review, artefacts kept',
              r.returncode == 0 and 'DONE: clean review in round 1' in log
              and os.path.isfile(os.path.join(wd, 'map.r0.bpmn')) and os.path.isfile(os.path.join(wd, 'review.r1.json')),
              (log.strip().splitlines() or [''])[-1] if log else r.stderr[-160:])
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    failed = [n for n, ok in results if not ok]
    print('\nT-983 review loop kit: %d/%d passed' % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
