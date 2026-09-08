#!/usr/bin/env python3
"""_t423-di-schema-validate.py — validate exported BPMN against the real BPMN 2.0 schema.

WHY A SCHEMA AND NOT A GREP
---------------------------
T-423's acceptance criterion says it in as many words: *"Verified by validating one exported
map against the BPMN 2.0 DI schema — not by grepping for the element names."* The distinction
is not pedantry. A grep for `bpmndi:BPMNShape` proves a string is present. It cannot see a
shape with no `dc:Bounds`, an edge with one waypoint, a `bpmnElement` pointing at nothing, or
— the defect this tool found on its first run — a correctly-named element in a position the
schema forbids.

WHAT IT FOUND ON ITS FIRST RUN (recorded so the red is not lost once it is green)
--------------------------------------------------------------------------------
24 of 24 corpus maps failed, with 113 occurrences of one fault: `bpmn:extensionElements`
emitted AFTER `bpmn:conditionExpression` on `bpmn:sequenceFlow`. BPMN's `tBaseElement` puts
`extensionElements` first in the sequence, so every conditional flow we have ever exported has
been schema-invalid. Every element name involved was correct and present, which is exactly why
no name-based check ever noticed. Filed as its own task; see `--explain`.

THE DI-SPECIFIC LEGS, AND WHICH OF THEM THE SCHEMA ALREADY COVERS
-----------------------------------------------------------------
This section originally claimed the XSD leaves `dc:Bounds` optional and waypoint counts
unconstrained. **Both claims were wrong, and the self-test is what said so** — the cases
written to show the schema passing those documents came back with the schema rejecting them.
Measured, not assumed:

  SCHEMA-REDUNDANT (the XSD already refuses these; the geometry leg is defence in depth)
    - shape without `dc:Bounds`     -> DI's `Shape` requires `Bounds`
    - edge with fewer than 2 points -> DI's `Edge` declares `waypoint` minOccurs="2"

  SCHEMA-ADDITIVE (the XSD accepts these documents; only the geometry leg catches them)
    - `bpmndi:BPMNLabel` present but carrying no `dc:Bounds`
    - `bpmnElement` referencing an id that is not in the document — XSD has no cross-
      reference resolution here, so a plane full of dangling references validates clean
    - an empty `<bpmndi:BPMNPlane/>` — perfectly valid, and carries no geometry at all

The additive three are the reason this tool is not just `xmllint`. They are also the three
that a corpus could regress into while every name-based check and the schema both stay green.
Results are reported as two separate verdicts (`schema=` and `geometry=`) so that "well-formed
per OMG" is never silently read as "the geometry is actually there".

MODES
-----
  (default) <path>...   validate the given .bpmn files (default: the rendered corpus)
  --verify-schemas      re-check the vendored XSD digests, then exit
  --explain             print what the first run found and why it is a separate task
  --self-test           prove each leg goes red on a document built to break it
"""
from __future__ import annotations

import argparse
import glob
import hashlib
import os
import sys

try:
    from lxml import etree
except ImportError:  # pragma: no cover
    print('FATAL: lxml is required for schema validation (python3 -m pip install lxml)',
          file=sys.stderr)
    raise SystemExit(3)

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..'))
SCHEMA_DIR = os.path.join(HERE, 'schemas', 'bpmn20')
ROOT_XSD = os.path.join(SCHEMA_DIR, 'BPMN20.xsd')
CORPUS = os.path.join(REPO, 'examples', 'aef-processes', 'rendered', '*.bpmn')

BPMN = '{http://www.omg.org/spec/BPMN/20100524/MODEL}'
BPMNDI = '{http://www.omg.org/spec/BPMN/20100524/DI}'
DC = '{http://www.omg.org/spec/DD/20100524/DC}'
DI = '{http://www.omg.org/spec/DD/20100524/DI}'

# Pinned at vendoring time. A schema edited locally would silently weaken every run below.
SCHEMA_SHA256 = {
    'BPMN20.xsd':   'a07c159cb0594573dd7c97b1370dd116112378f377e43c89a8bf512ac5030705',
    'BPMNDI.xsd':   'f0dff1cd559d1514d8ebfc8c646f58402bcaced27ec22e2aa6456c2dcc80b038',
    'DC.xsd':       'a2f90e5ad9bb48c6915e4e034b4e27ac838264a1d4f27bfc70dbdfc69351312d',
    'DI.xsd':       '8220b179c175572df74e08a51bffabe957867962035cee7b5fee0b6acb4c4498',
    'Semantic.xsd': 'c4318842f7d2bbc262d7954c9452c501db16f0868eac0b8732ec5d7fb384d9a7',
}

EXPLANATION = """\
First run of this tool, 2026-09-08, against the committed corpus:

  24 of 24 maps INVALID — 113 occurrences, one cause.

  bpmn:extensionElements is emitted AFTER bpmn:conditionExpression inside
  bpmn:sequenceFlow. BPMN's tBaseElement declares extensionElements first in the
  sequence, so the order is not merely unconventional, it is invalid.

  Source: src/aef-workflow-designer.html — the sequenceFlow branch emits the
  conditional conditionExpression before the unconditional extensionElements block.

Why this is a SEPARATE task and not folded into T-423:

  It is not a DI defect. It predates the DI work, it affects conditional flows
  whether or not DI is emitted, and its fix touches a different branch of the
  exporter. CLAUDE.md: one bug = one task. Compounding it here would have put two
  root causes behind one checkbox.

Why nothing caught it for months:

  Every check the corpus had was name-based or byte-based. A name-based check sees
  the right element names, in the right document, with the right attributes — the
  ONLY thing wrong is their order, and order is precisely what a grep discards. A
  byte-identity baseline is worse than silent here: it pins the invalid bytes and
  would have gone RED on the fix.
"""


def verify_schema_digests() -> list[str]:
    """Return a list of problems; empty means the vendored schemas are untouched."""
    problems = []
    for name, want in sorted(SCHEMA_SHA256.items()):
        path = os.path.join(SCHEMA_DIR, name)
        if not os.path.exists(path):
            problems.append('%s: MISSING' % name)
            continue
        with open(path, 'rb') as f:
            got = hashlib.sha256(f.read()).hexdigest()
        if got != want:
            problems.append('%s: digest %s != pinned %s' % (name, got[:16], want[:16]))
    return problems


def load_schema() -> etree.XMLSchema:
    return etree.XMLSchema(etree.parse(ROOT_XSD))


def di_geometry_findings(doc: etree._ElementTree) -> list[str]:
    """The AC's three clauses, checked structurally alongside schema validity.

    Two of these legs (missing Bounds, short waypoint list) duplicate constraints the XSD
    already enforces — kept as defence in depth, but not the justification for this layer.
    The layer earns its place on the three the XSD accepts: a BPMNLabel with no bounds, a
    bpmnElement pointing at nothing, and an empty BPMNPlane. See the module docstring for
    the measurement that sorted them.
    """
    findings = []
    root = doc.getroot()

    planes = root.findall('.//' + BPMNDI + 'BPMNPlane')
    if not root.findall('.//' + BPMNDI + 'BPMNDiagram'):
        findings.append('no bpmndi:BPMNDiagram present')
    if not planes:
        findings.append('no bpmndi:BPMNPlane present')

    shapes = root.findall('.//' + BPMNDI + 'BPMNShape')
    edges = root.findall('.//' + BPMNDI + 'BPMNEdge')

    # An empty plane is schema-valid and geometrically useless. Say so rather than pass.
    if planes and not shapes and not edges:
        findings.append('BPMNPlane contains no shapes and no edges (schema-valid, empty)')

    for s in shapes:
        if s.find(DC + 'Bounds') is None:
            findings.append('BPMNShape %s has no dc:Bounds' % (s.get('id') or '?'))
        if not s.get('bpmnElement'):
            findings.append('BPMNShape %s has no bpmnElement' % (s.get('id') or '?'))
    for e in edges:
        wps = e.findall(DI + 'waypoint')
        if len(wps) < 2:
            findings.append('BPMNEdge %s has %d di:waypoint (needs >= 2)'
                            % (e.get('id') or '?', len(wps)))
        if not e.get('bpmnElement'):
            findings.append('BPMNEdge %s has no bpmnElement' % (e.get('id') or '?'))

    # Label bounds "where a label position is persisted": a BPMNLabel that exists but
    # carries no bounds is the failure — an absent BPMNLabel is not, because the AC
    # scopes this to labels whose position IS persisted.
    for lbl in root.findall('.//' + BPMNDI + 'BPMNLabel'):
        if lbl.find(DC + 'Bounds') is None:
            parent = lbl.getparent()
            findings.append('BPMNLabel on %s is present but carries no dc:Bounds'
                            % (parent.get('bpmnElement') if parent is not None else '?'))

    # Every DI reference must resolve to a real BPMN element in this document.
    ids = {el.get('id') for el in root.iter() if el.get('id')}
    for el in shapes + edges:
        ref = el.get('bpmnElement')
        if ref and ref not in ids:
            findings.append('%s references bpmnElement=%r which is not in the document'
                            % (etree.QName(el).localname, ref))
    return findings


def validate_one(schema: etree.XMLSchema, path: str, verbose: bool = True) -> tuple[bool, bool]:
    """Returns (schema_ok, geometry_ok). Both are reported; neither implies the other."""
    name = os.path.basename(path)
    try:
        doc = etree.parse(path)
    except etree.XMLSyntaxError as exc:
        if verbose:
            print('  MALFORMED %-38s %s' % (name, str(exc)[:90]))
        return False, False

    schema_ok = schema.validate(doc)
    findings = di_geometry_findings(doc)
    geom_ok = not findings

    if verbose:
        tag = 'OK  ' if (schema_ok and geom_ok) else 'FAIL'
        print('  %s %-38s schema=%-5s geometry=%-5s' % (tag, name, schema_ok, geom_ok))
        if not schema_ok:
            for err in list(schema.error_log)[:3]:
                print('        schema  L%s: %s' % (err.line, err.message[:120]))
        for f in findings[:3]:
            print('        geometry: %s' % f)
        if len(findings) > 3:
            print('        geometry: ... and %d more' % (len(findings) - 3))
    return schema_ok, geom_ok


def run(paths: list[str]) -> int:
    problems = verify_schema_digests()
    if problems:
        print('REFUSING TO VALIDATE — vendored schemas do not match their pinned digests:',
              file=sys.stderr)
        for p in problems:
            print('  ' + p, file=sys.stderr)
        print('\nValidating against an altered schema reports a weaker result as a pass.',
              file=sys.stderr)
        return 3

    schema = load_schema()
    print('BPMN 2.0 schema loaded from %s (5 XSDs, digests verified)'
          % os.path.relpath(SCHEMA_DIR, REPO))
    print('Validating %d document(s):' % len(paths))

    bad_schema = bad_geom = 0
    for p in sorted(paths):
        s_ok, g_ok = validate_one(schema, p)
        bad_schema += 0 if s_ok else 1
        bad_geom += 0 if g_ok else 1

    print('\n%d document(s): %d schema-invalid, %d missing DI geometry'
          % (len(paths), bad_schema, bad_geom))
    if bad_schema or bad_geom:
        print('\nRun --explain for what the first run of this tool found.')
        return 1
    print('All documents validate against the OMG BPMN 2.0 schema AND carry complete DI '
          'geometry.')
    return 0


def self_test() -> int:
    """Every leg must be shown red on a document built to break it.

    A validator that has only ever been run against real files is a claim. These cases are
    synthetic on purpose: each one is minimal, isolates a single leg, and would be reported
    as a pass by any name-based check.
    """
    problems = verify_schema_digests()
    if problems:
        print('SELF-TEST FAIL: schema digests already broken: %s' % problems, file=sys.stderr)
        return 1
    schema = load_schema()

    head = ('<?xml version="1.0" encoding="UTF-8"?>'
            '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL" '
            'xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI" '
            'xmlns:dc="http://www.omg.org/spec/DD/20100524/DC" '
            'xmlns:di="http://www.omg.org/spec/DD/20100524/DI" '
            'id="d1" targetNamespace="http://example.org">')
    tail = '</bpmn:definitions>'

    def doc(body):
        return etree.ElementTree(etree.fromstring((head + body + tail).encode('utf-8')))

    proc_ok = ('<bpmn:process id="p1"><bpmn:startEvent id="n1"/></bpmn:process>')

    cases = [
        # (name, body, expect_schema_ok, expect_geometry_ok)
        ('baseline-valid',
         proc_ok + '<bpmndi:BPMNDiagram id="dg"><bpmndi:BPMNPlane id="pl" bpmnElement="p1">'
         '<bpmndi:BPMNShape id="s1" bpmnElement="n1">'
         '<dc:Bounds x="0" y="0" width="36" height="36"/></bpmndi:BPMNShape>'
         '</bpmndi:BPMNPlane></bpmndi:BPMNDiagram>', True, True),

        # The real defect: right names, right attributes, forbidden ORDER.
        ('extensionElements-after-conditionExpression',
         '<bpmn:process id="p1"><bpmn:startEvent id="n1"/><bpmn:endEvent id="n2"/>'
         '<bpmn:sequenceFlow id="f1" sourceRef="n1" targetRef="n2">'
         '<bpmn:conditionExpression>x</bpmn:conditionExpression>'
         '<bpmn:extensionElements/></bpmn:sequenceFlow></bpmn:process>', False, False),

        ('shape-without-bounds',
         proc_ok + '<bpmndi:BPMNDiagram id="dg"><bpmndi:BPMNPlane id="pl" bpmnElement="p1">'
         '<bpmndi:BPMNShape id="s1" bpmnElement="n1"/>'
         '</bpmndi:BPMNPlane></bpmndi:BPMNDiagram>', False, False),

        ('edge-with-one-waypoint',
         '<bpmn:process id="p1"><bpmn:startEvent id="n1"/><bpmn:endEvent id="n2"/>'
         '<bpmn:sequenceFlow id="f1" sourceRef="n1" targetRef="n2"/></bpmn:process>'
         '<bpmndi:BPMNDiagram id="dg"><bpmndi:BPMNPlane id="pl" bpmnElement="p1">'
         '<bpmndi:BPMNEdge id="e1" bpmnElement="f1"><di:waypoint x="0" y="0"/>'
         '</bpmndi:BPMNEdge></bpmndi:BPMNPlane></bpmndi:BPMNDiagram>', False, False),

        ('label-present-without-bounds',
         proc_ok + '<bpmndi:BPMNDiagram id="dg"><bpmndi:BPMNPlane id="pl" bpmnElement="p1">'
         '<bpmndi:BPMNShape id="s1" bpmnElement="n1">'
         '<dc:Bounds x="0" y="0" width="36" height="36"/><bpmndi:BPMNLabel/>'
         '</bpmndi:BPMNShape></bpmndi:BPMNPlane></bpmndi:BPMNDiagram>', True, False),

        ('di-references-a-missing-element',
         proc_ok + '<bpmndi:BPMNDiagram id="dg"><bpmndi:BPMNPlane id="pl" bpmnElement="p1">'
         '<bpmndi:BPMNShape id="s1" bpmnElement="does-not-exist">'
         '<dc:Bounds x="0" y="0" width="36" height="36"/></bpmndi:BPMNShape>'
         '</bpmndi:BPMNPlane></bpmndi:BPMNDiagram>', True, False),

        ('empty-plane-is-schema-valid-but-carries-nothing',
         proc_ok + '<bpmndi:BPMNDiagram id="dg"><bpmndi:BPMNPlane id="pl" bpmnElement="p1"/>'
         '</bpmndi:BPMNDiagram>', True, False),
    ]

    failures = 0
    for name, body, want_schema, want_geom in cases:
        d = doc(body)
        got_schema = schema.validate(d)
        got_geom = not di_geometry_findings(d)
        ok = (got_schema == want_schema) and (got_geom == want_geom)
        print('  %-4s %-46s schema %s/%s  geometry %s/%s'
              % ('PASS' if ok else 'FAIL', name,
                 got_schema, want_schema, got_geom, want_geom))
        if not ok:
            failures += 1

    print('\n%d/%d self-test cases behaved as specified' % (len(cases) - failures, len(cases)))
    if failures:
        print('SELF-TEST FAILED — a leg that cannot go red asserts nothing.', file=sys.stderr)
        return 1
    print('self-test OK — every leg has been watched going red on a purpose-built document')
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('paths', nargs='*', help='.bpmn files (default: the rendered corpus)')
    ap.add_argument('--verify-schemas', action='store_true')
    ap.add_argument('--explain', action='store_true')
    ap.add_argument('--self-test', action='store_true')
    args = ap.parse_args()

    if args.explain:
        print(EXPLANATION)
        return 0
    if args.verify_schemas:
        problems = verify_schema_digests()
        for p in problems:
            print(p, file=sys.stderr)
        print('%d schema(s) verified against pinned digests'
              % (len(SCHEMA_SHA256) - len(problems)))
        return 1 if problems else 0
    if args.self_test:
        return self_test()

    paths = args.paths or sorted(glob.glob(CORPUS))
    if not paths:
        print('no documents to validate', file=sys.stderr)
        return 2
    return run(paths)


if __name__ == '__main__':
    sys.exit(main())
