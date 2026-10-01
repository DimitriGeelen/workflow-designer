#!/usr/bin/env python3
"""T-974: the vendor authoring kit is complete, self-contained, deterministic and immutable.

WHAT THIS GUARDS. A vendor project deployed designer v0.13.0, which shipped no exemplar, no
validator and no checklist, and its generator produced 26 maps with zero governance carriers.
The kit is what a generating agent reads instead of being told by us. Each leg pins one way
it could quietly stop doing that:

  1. contents + SHA256SUMS verify;
  2. two builds of one tree are byte-identical;
  3. CONFORMANCE.md lists every rule the BPMN form can emit. The expected set is derived HERE
     by regex over the validator's source, independently of the builder's AST walk, so the
     two cannot share a blind spot;
  4. every rule id AUTHORING.md names exists in the validator (a guide naming a rule that does
     not exist teaches a vendor to look for something that never fires);
  5. SELF-CONTAINED: copied to a directory outside this repo and run with `python3 -I`, the
     kit's validator passes its exemplar clean and names both missing carriers on a map shaped
     like the vendor's (synthetic; their content is not ours to commit);
  6. a dirty exemplar is REFUSED at build time;
  7. an existing kit that differs is never rewritten, and --check writes nothing;
  8. scripts/release-designer.sh builds the kit beside the artifact and records it in the
     manifest, run against a scratch RELEASE_DIST so dist/ is never touched.

Exit 0 iff every check passes. Run: python3 tests/test_t974_authoring_kit.py
"""
import hashlib
import importlib.util
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
BUILDER = os.path.join(ROOT, 'tools', 'build-authoring-kit.py')
VALIDATOR = os.path.join(ROOT, 'tools', 'validate-workflow.py')
GUIDE = os.path.join(ROOT, 'docs', 'authoring-kit', 'AUTHORING.md')
RELEASE = os.path.join(ROOT, 'scripts', 'release-designer.sh')

# Shaped like the vendor corpus, none of its content: default namespace, plain tasks, lanes
# with no laneMeta, no workflowMeta.
VENDOR_SHAPED = '''<?xml version="1.0" encoding="UTF-8"?>
<definitions xmlns="http://www.omg.org/spec/BPMN/20100524/MODEL" id="D" targetNamespace="x">
  <process id="P" isExecutable="false">
    <laneSet id="LS">
      <lane id="l1" name="Sales"><flowNodeRef>s</flowNodeRef><flowNodeRef>t1</flowNodeRef></lane>
      <lane id="l2" name="Warehouse"><flowNodeRef>t2</flowNodeRef><flowNodeRef>e</flowNodeRef></lane>
    </laneSet>
    <startEvent id="s"/><task id="t1" name="Take order"/><task id="t2" name="Ship"/><endEvent id="e"/>
    <sequenceFlow id="f1" sourceRef="s" targetRef="t1"/>
    <sequenceFlow id="f2" sourceRef="t1" targetRef="t2"/>
    <sequenceFlow id="f3" sourceRef="t2" targetRef="e"/>
  </process>
</definitions>
'''

results = []


def check(name, cond, detail=''):
    results.append((name, bool(cond)))
    print('%s %s%s' % ('PASS' if cond else 'FAIL', name, (' — ' + detail) if detail else ''))


def run(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def build(out, version='0.0.0-t974', *extra):
    return run([sys.executable, BUILDER, '--version', version, '--out', out, *extra])


def tree_bytes(d):
    return {n: open(os.path.join(d, n), 'rb').read() for n in sorted(os.listdir(d))}


def validator_xml_rule_ids():
    src = open(VALIDATOR, encoding='utf-8').read()
    start = src.index('class XmlValidator')
    end = src.index('\ndef ', start)
    return set(re.findall(r'self\.(?:err|warn|info)\(\s*"([EWI]-[A-Z0-9-]+)"', src[start:end]))


def all_rule_ids():
    return set(re.findall(r'"([EWI]-[A-Z0-9-]+)"', open(VALIDATOR, encoding='utf-8').read()))


def main():
    tmp = tempfile.mkdtemp(prefix='t974-')
    try:
        k1, k2 = os.path.join(tmp, 'k1'), os.path.join(tmp, 'k2')
        r = build(k1)
        check('builder builds', r.returncode == 0, r.stderr.strip()[-200:])
        if r.returncode != 0:
            return 1
        names = sorted(os.listdir(k1))
        check('1a. kit holds exactly the five files',
              names == ['AUTHORING.md', 'CONFORMANCE.md', 'SHA256SUMS', 'exemplar.bpmn',
                        'validate-workflow.py'], str(names))
        sums = dict(reversed(l.split('  ', 1)) for l in
                    open(os.path.join(k1, 'SHA256SUMS')).read().split('\n') if l)
        ok = sums and all(hashlib.sha256(open(os.path.join(k1, n), 'rb').read()).hexdigest() == h
                          for n, h in sums.items())
        check('1b. SHA256SUMS covers every other file and verifies',
              ok and set(sums) == set(names) - {'SHA256SUMS'})
        check('1c. the kit validator is the repo validator, byte for byte',
              open(os.path.join(k1, 'validate-workflow.py'), 'rb').read()
              == open(VALIDATOR, 'rb').read())

        build(k2)
        check('2. two builds are byte-identical', tree_bytes(k1) == tree_bytes(k2))

        conf = open(os.path.join(k1, 'CONFORMANCE.md'), encoding='utf-8').read()
        listed = set(re.findall(r'^\| `([EWI]-[A-Z0-9-]+)`', conf, re.M))
        expected = validator_xml_rule_ids()
        check('3a. independent rule derivation found rules (the regex is not vacuous)',
              len(expected) >= 20, 'found %d' % len(expected))
        check('3b. CONFORMANCE.md lists every BPMN-form rule',
              expected <= listed, 'missing %s' % sorted(expected - listed))
        check('3c. no rule is UNCLASSIFIED', '| UNCLASSIFIED |' not in conf)

        named = set(re.findall(r'`([EWI]-[A-Z0-9-]+)`', open(GUIDE, encoding='utf-8').read()))
        check('4. every rule AUTHORING.md names exists in the validator',
              named and named <= all_rule_ids(), 'unknown %s' % sorted(named - all_rule_ids()))

        lone = os.path.join(tmp, 'elsewhere', 'kit')
        shutil.copytree(k1, lone)
        with open(os.path.join(lone, 'vendor.bpmn'), 'w') as f:
            f.write(VENDOR_SHAPED)
        r = run([sys.executable, '-I', 'validate-workflow.py', 'exemplar.bpmn'], cwd=lone)
        check('5a. outside the repo, the kit validator passes its exemplar clean',
              r.returncode == 0, (r.stdout + r.stderr).strip()[-200:])
        r = run([sys.executable, '-I', 'validate-workflow.py', 'vendor.bpmn'], cwd=lone)
        check('5b. ... and names both missing carriers on a vendor-shaped map',
              r.returncode == 1 and 'W-XML-NO-WORKFLOWMETA' in r.stdout
              and 'W-XML-LANE-NO-AUTHORITY' in r.stdout,
              'rc=%d %s' % (r.returncode, r.stdout.strip()[-300:]))

        spec = importlib.util.spec_from_file_location('_t974_builder', BUILDER)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.EXEMPLAR = os.path.join(lone, 'vendor.bpmn')
        try:
            mod.build_into(os.path.join(tmp, 'dirty'), 'x')
            refused = False
        except RuntimeError:
            refused = True
        check('6. a dirty exemplar is refused at build time',
              refused and not os.path.exists(os.path.join(tmp, 'dirty')))

        with open(os.path.join(k1, 'AUTHORING.md'), 'a') as f:
            f.write('tampered\n')
        before = tree_bytes(k1)
        r = build(k1)
        check('7a. an existing kit that differs is refused, not rewritten',
              r.returncode == 1 and tree_bytes(k1) == before, r.stderr.strip()[-160:])
        absent = os.path.join(tmp, 'absent')
        r = build(absent, '0.0.0-t974', '--check')
        check('7b. --check on an absent kit writes nothing',
              r.returncode == 0 and not os.path.exists(absent))

        dist = os.path.join(tmp, 'dist')
        env = dict(os.environ, RELEASE_DIST=dist, RELEASE_SKIP_RENDER_CHECK='1',
                   RELEASE_SKIP_ANNOUNCE='1')
        r = run(['bash', RELEASE], env=env, cwd=ROOT)
        version = open(os.path.join(ROOT, 'VERSION')).read().strip()
        kit = os.path.join(dist, 'aef-authoring-kit-%s' % version)
        manifest = open(os.path.join(dist, 'MANIFEST.yaml')).read() \
            if os.path.isfile(os.path.join(dist, 'MANIFEST.yaml')) else ''
        check('8a. the release script builds the kit beside the artifact (scratch dist)',
              r.returncode == 0 and os.path.isfile(os.path.join(kit, 'SHA256SUMS'))
              and os.path.isfile(os.path.join(dist, 'aef-workflow-designer-%s.html' % version)),
              'rc=%d %s' % (r.returncode, (r.stdout + r.stderr).strip()[-300:]))
        check('8b. the manifest records the kit and its SHA256SUMS checksum',
              'kit_sha256: "' in manifest and 'aef-authoring-kit-%s' % version in manifest)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    failed = [n for n, ok in results if not ok]
    print('\nT-974 authoring kit: %d/%d passed' % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
