#!/usr/bin/env python3
"""build-authoring-kit.py — the vendor authoring kit, built beside a designer release (T-974).

WHY. Designer v0.13.0 reached a vendor project with no exemplar, no validator and no
conformance checklist. Its generator produced 26 maps with zero governance carriers and 130
saves said nothing. A release is one immutable HTML that AEF vendors; a Python validator
cannot ride inside it, so the kit is a companion directory built by the release script under
the same immutability rule.

CONTENTS of aef-authoring-kit-<VERSION>/:
  validate-workflow.py  the repo's exact bytes (stdlib only; yaml optional)
  exemplar.bpmn         a corpus map, refused at build time unless it validates CLEAN
  CONFORMANCE.md        GENERATED from the validator's own source and the dialect axis:
                        every XML-form rule, its severity, its derived class, its message
  AUTHORING.md          the generator-agent guide (docs/authoring-kit/AUTHORING.md)
  SHA256SUMS            over every other file

NOTHING HERE IS WRITTEN BY HAND TWICE. Rule ids come from the validator's AST, classes from
tests/test_rule_dialect_axis.py's classification(), vocabularies from the validator's module
constants. A checklist typed out separately is a second copy of the rules, and two copies drift.

DETERMINISTIC: no timestamps, sorted output; two builds of one tree are byte-identical.

Usage:
  build-authoring-kit.py --version V --out DIR            build (refuses to rewrite a different DIR)
  build-authoring-kit.py --version V --out DIR --check    exit 0 if DIR absent or identical, 1 if not;
                                                          writes nothing (the release script's pre-write guard)
"""
import argparse
import ast
import filecmp
import hashlib
import importlib.util
import os
import re
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..'))
VALIDATOR = os.path.join(HERE, 'validate-workflow.py')
AXIS = os.path.join(ROOT, 'tests', 'test_rule_dialect_axis.py')
GUIDE = os.path.join(ROOT, 'docs', 'authoring-kit', 'AUTHORING.md')
EXEMPLAR = os.path.join(ROOT, 'examples', 'aef-processes', 'rendered', 'task-lifecycle.bpmn')

SEVERITY = {'err': 'ERROR', 'warn': 'WARN', 'info': 'INFO'}


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _template(node):
    """Readable text of a message argument, without evaluating it."""
    if isinstance(node, ast.Constant) and isinstance(node.value, str):
        text = node.value
    elif isinstance(node, ast.BinOp) and isinstance(node.op, ast.Mod) \
            and isinstance(node.left, ast.Constant) and isinstance(node.left.value, str):
        text = node.left.value
    else:
        text = '(computed: %s)' % ast.unparse(node)
    return re.sub(r'\s+', ' ', text).strip()


def xml_rules():
    """{rule_id: (severity, first message template)} for every XmlValidator emission site."""
    tree = ast.parse(open(VALIDATOR, encoding='utf-8').read())
    out = {}
    for cls in tree.body:
        if not (isinstance(cls, ast.ClassDef) and cls.name == 'XmlValidator'):
            continue
        for node in ast.walk(cls):
            if not isinstance(node, ast.Call):
                continue
            f = node.func
            if (isinstance(f, ast.Attribute) and f.attr in SEVERITY
                    and isinstance(f.value, ast.Name) and f.value.id == 'self'
                    and len(node.args) >= 3 and isinstance(node.args[0], ast.Constant)):
                rid = node.args[0].value
                out.setdefault(rid, (SEVERITY[f.attr], _template(node.args[2])))
    if not out:
        raise RuntimeError('found no XmlValidator emission sites in %s; the parse is broken, '
                           'and an empty checklist would read as "no rules"' % VALIDATOR)
    return out


def intake_rules():
    """{rule_id: (severity, message)} emitted OUTSIDE the validator classes: the document could
    not be read or parsed, so no modelling rule ran. Found by the T-975 review: the checklist
    claimed to list every rule and omitted these. Derived from the AST, not listed by hand."""
    tree = ast.parse(open(VALIDATOR, encoding='utf-8').read())
    inside = set()
    for cls in tree.body:
        if isinstance(cls, ast.ClassDef):
            inside.update(id(n) for n in ast.walk(cls))
    out = {}
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call) or id(node) in inside:
            continue
        f = node.func
        if isinstance(f, ast.Attribute) and f.attr in SEVERITY and len(node.args) >= 3 \
                and isinstance(node.args[0], ast.Constant):
            out.setdefault(node.args[0].value, (SEVERITY[f.attr], _template(node.args[2])))
        elif isinstance(f, ast.Name) and f.id == 'Finding' and len(node.args) >= 4 \
                and isinstance(node.args[1], ast.Constant) and isinstance(node.args[0], ast.Name):
            out.setdefault(node.args[1].value, (node.args[0].id, _template(node.args[3])))
    return out


def conformance_md(version):
    val = _load(VALIDATOR, '_kit_validator')
    axis = _load(AXIS, '_kit_axis').classification()
    rules = xml_rules()
    missing = sorted(r for r in rules if r not in axis)
    lines = [
        '# Conformance checklist: AEF Workflow Designer %s' % version,
        '',
        'GENERATED by tools/build-authoring-kit.py from validate-workflow.py and the dialect',
        'axis. Do not edit; regenerate. Every rule the BPMN form of the validator can emit is',
        'listed. If a finding names a rule that is not here, this file is stale.',
        '',
        '## Vocabularies',
        '',
        '- Lane `authority`: %s' % ', '.join('`%s`' % a for a in sorted(val.AUTHORITIES)),
        '- Authority -> owner: %s; %s: no owner can be derived (declared unknown); %s: '
        'performed outside this system, no task compiled (mapping-v1 §3)' % (
            ', '.join('`%s` -> %s' % kv for kv in sorted(val.AUTHORITY_OWNER.items())),
            ', '.join('`%s`' % a for a in sorted(val.AUTHORITY_NO_OWNER_DERIVABLE)),
            ', '.join('`%s`' % a for a in sorted(
                set(val.AUTHORITIES) - set(val.AUTHORITY_OWNER)
                - set(val.AUTHORITY_NO_OWNER_DERIVABLE)))),
        '- Map `kind` (workflowMeta): %s; absent = an ordinary process' % ', '.join(
            '`%s`' % k for k in sorted(val.WORKFLOW_KINDS)),
        '- Flow-node elements accepted: %s' % ', '.join(
            '`%s`' % t for t in sorted(val.XML_NODE_TYPES)),
        '',
        '## Rules',
        '',
        'Class: UNIVERSAL = any conformant document satisfies it. DIALECT-RELATIVE = house',
        'convention, not the standard. PRESENTATIONAL = layout only. UNCLASSIFIED = the axis has',
        'not ruled on it yet (stated, not guessed).',
        '',
        '| rule | severity | class | says |',
        '|---|---|---|---|',
    ]
    for rid in sorted(rules):
        sev, msg = rules[rid]
        lines.append('| `%s` | %s | %s | %s |' % (
            rid, sev, axis.get(rid, 'UNCLASSIFIED'), msg.replace('|', '\\|')))
    lines += ['', '%d rules, %d unclassified.' % (len(rules), len(missing)), '']
    intake = intake_rules()
    lines += ['## Before any rule runs', '',
              'These fire when the document cannot be read or parsed. No modelling rule has run,',
              'so the map has NOT been checked: fix the file first.', '',
              '| rule | severity | says |', '|---|---|---|']
    for rid in sorted(intake):
        sev, msg = intake[rid]
        lines.append('| `%s` | %s | %s |' % (rid, sev, msg.replace('|', '\\|')))
    lines.append('')
    return '\n'.join(lines)


def build_into(d, version):
    val = _load(VALIDATOR, '_kit_validator_check')
    findings = val.run_xml(open(EXEMPLAR, encoding='utf-8').read())
    if findings:
        raise RuntimeError('exemplar %s does not validate clean (%s); a kit whose exemplar '
                           'draws findings teaches the wrong thing' % (
                               EXEMPLAR, sorted({f.rule for f in findings})))
    os.makedirs(d)
    shutil.copyfile(VALIDATOR, os.path.join(d, 'validate-workflow.py'))
    shutil.copyfile(EXEMPLAR, os.path.join(d, 'exemplar.bpmn'))
    shutil.copyfile(GUIDE, os.path.join(d, 'AUTHORING.md'))
    with open(os.path.join(d, 'CONFORMANCE.md'), 'w', encoding='utf-8', newline='\n') as f:
        f.write(conformance_md(version))
    sums = []
    for name in sorted(os.listdir(d)):
        with open(os.path.join(d, name), 'rb') as f:
            sums.append('%s  %s' % (hashlib.sha256(f.read()).hexdigest(), name))
    with open(os.path.join(d, 'SHA256SUMS'), 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(sums) + '\n')


def same_tree(a, b):
    la, lb = sorted(os.listdir(a)), sorted(os.listdir(b))
    if la != lb:
        return False
    return all(filecmp.cmp(os.path.join(a, n), os.path.join(b, n), shallow=False) for n in la)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--version', required=True)
    ap.add_argument('--out', required=True)
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args(argv)
    out = os.path.abspath(a.out)
    tmp = tempfile.mkdtemp(prefix='authoring-kit-')
    try:
        fresh = os.path.join(tmp, 'kit')
        build_into(fresh, a.version)
        if os.path.exists(out):
            if same_tree(fresh, out):
                print('authoring kit %s: unchanged at %s' % (a.version, out))
                return 0
            # Same rule as the designer artifact (T-198, G-007): a released version is fixed
            # bytes. The release script's RELEASE_ALLOW_OVERWRITE is the one bypass, and it
            # removes the directory before calling us, so this path never overwrites.
            print('ERROR: %s exists and differs from a fresh build; refusing to rewrite a '
                  'released kit' % out, file=sys.stderr)
            return 1
        if a.check:
            print('authoring kit %s: would be created at %s' % (a.version, out))
            return 0
        shutil.copytree(fresh, out)
        print('authoring kit %s: built at %s' % (a.version, out))
        return 0
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
