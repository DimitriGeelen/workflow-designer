#!/usr/bin/env python3
"""kit-calibration-gate.py — a kit release must carry a real calibration of ITS OWN bytes (T-1008, ledger L16).

WHY. In 0.15.2 a drafted rubric line and the clean control map conflicted, and only the real
calibration (loop.sh --calibrate with a live reviewer) exposed it; nothing on the release path ran
new rules against clean.bpmn. L16 (confirmed by OpenAI, Z.AI and Google reviewers, T-1006): every
new or changed rule goes through calibration before release, and a finding on clean.bpmn blocks it.

A record is bound to the kit it measured by the sha256 of that kit's SHA256SUMS (the builder is
deterministic: same sources + same version = same bytes). Edit one rule after calibrating and the
hash moves, the record no longer applies, and the release is refused until someone calibrates again.

  record --version V --reviewer NAME --vendor V --result-file OUT
        build the kit for V into a temp dir, parse loop.sh --calibrate's printed result from OUT
        (recall, false findings, PASS/FAIL), and append it to
        docs/authoring-kit/calibration-records/V.yaml with the kit hash.
  check --version V
        exit 0 only if the record for V exists, its kit hash equals the kit V builds to NOW, it has
        at least one reviewer, and every reviewer recorded PASS. Otherwise exit 1 with the reason.
  kit-hash --version V      print the hash the kit for V builds to now.
"""
import argparse
import datetime
import hashlib
import os
import re
import subprocess
import sys
import tempfile

import yaml

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
BUILDER = os.path.join(ROOT, 'tools', 'build-authoring-kit.py')
RECORDS = os.environ.get('KIT_CALIBRATION_RECORDS') or os.path.join(ROOT, 'docs', 'authoring-kit', 'calibration-records')


def kit_hash(version):
    with tempfile.TemporaryDirectory() as t:
        out = os.path.join(t, 'kit')
        r = subprocess.run([sys.executable, BUILDER, '--version', version, '--out', out],
                           capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit('kit for %s does not build: %s' % (version, (r.stdout + r.stderr)[-400:]))
        return hashlib.sha256(open(os.path.join(out, 'SHA256SUMS'), 'rb').read()).hexdigest()


def parse_result(text):
    rec = re.search(r'recall: (\d+)/(\d+)', text)
    fls = re.search(r'false findings: (\d+) on the clean map, (\d+) on unplanted', text)
    res = re.search(r'CALIBRATION: (PASS|FAIL|COULD NOT MEASURE)', text)
    if not res:
        sys.exit('no "CALIBRATION:" line in the result file: not a loop.sh --calibrate output')
    return {'result': res.group(1),
            'recall': '%s/%s' % rec.groups() if rec else None,
            'false_on_clean': int(fls.group(1)) if fls else None,
            'false_on_unplanted': int(fls.group(2)) if fls else None}


def path_for(version):
    return os.path.join(RECORDS, '%s.yaml' % version)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    r = sub.add_parser('record'); r.add_argument('--version', required=True); r.add_argument('--reviewer', required=True)
    r.add_argument('--vendor', required=True); r.add_argument('--result-file', required=True)
    c = sub.add_parser('check'); c.add_argument('--version', required=True)
    k = sub.add_parser('kit-hash'); k.add_argument('--version', required=True)
    a = ap.parse_args(argv)
    if a.cmd == 'kit-hash':
        print(kit_hash(a.version)); return 0
    if a.cmd == 'record':
        res = parse_result(open(a.result_file, encoding='utf-8').read())
        h = kit_hash(a.version)
        p = path_for(a.version)
        doc = yaml.safe_load(open(p)) if os.path.exists(p) else None
        if not doc or doc.get('kit_sha256') != h:
            doc = {'version': a.version, 'kit_sha256': h, 'reviewers': []}  # a new kit voids old rows
        doc['reviewers'].append(dict(res, reviewer=a.reviewer, vendor=a.vendor.lower(),
                                     at=datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')))
        os.makedirs(RECORDS, exist_ok=True)
        with open(p, 'w', encoding='utf-8') as f:
            f.write('# Calibration record for kit %s (tools/kit-calibration-gate.py, T-1008). Bound to the\n'
                    '# kit bytes by kit_sha256; any change to the kit voids it.\n' % a.version)
            yaml.safe_dump(doc, f, sort_keys=False)
        print('%s: %s %s (%s) recall %s, false on clean %s' % (a.version, a.reviewer, res['result'], a.vendor,
                                                              res['recall'], res['false_on_clean']))
        return 0 if res['result'] == 'PASS' else 1
    p = path_for(a.version)
    if not os.path.exists(p):
        print('REFUSED: no calibration record for kit %s (%s). Run loop.sh --calibrate on the built kit '
              'and record it: tools/kit-calibration-gate.py record ... (ledger L16)' % (a.version, os.path.relpath(p, ROOT)))
        return 1
    doc = yaml.safe_load(open(p)) or {}
    h = kit_hash(a.version)
    if doc.get('kit_sha256') != h:
        print('REFUSED: the calibration record for %s measured a different kit (%s...) than the one that '
              'builds now (%s...): something changed after calibration. Calibrate again.' % (
                  a.version, str(doc.get('kit_sha256'))[:12], h[:12]))
        return 1
    rows = doc.get('reviewers') or []
    bad = [x for x in rows if x.get('result') != 'PASS']
    if not rows or bad:
        print('REFUSED: kit %s calibration: %s' % (a.version, 'no reviewer recorded' if not rows else
              'not PASS for ' + ', '.join('%s (%s: %s)' % (x['reviewer'], x['vendor'], x['result']) for x in bad)))
        return 1
    print('kit %s calibrated: %s' % (a.version, ', '.join('%s (%s) %s' % (x['reviewer'], x['vendor'], x['recall']) for x in rows)))
    return 0


if __name__ == '__main__':
    sys.exit(main())
