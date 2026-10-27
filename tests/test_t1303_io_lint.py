"""T-1303: mapping v1.1 lint on the io (AEF spec T-4415), XML form.

R1 E-XML-IO-MATCH-MISSING (ERROR): an io with operation update / upsert / delete and no aef:field role="match"
   ("a map must never be readable as 'delete everything' or 'update everything'").
R2 E-XML-IO-PREFIX-UNDECLARED (ERROR): a CURIE prefix in fieldRef / typeRef / conceptRef, on the io or an aef:field,
   that the process-level aef:prefixes does not declare. http / https / urn are not prefixes; `ref` is not read (v1,
   its own read rule).
R3 W-XML-IO-MATCH-UNRESOLVED (WARN): a role="match" field with neither fieldRef nor path ("a key exists but is not
   yet determined").

XML-only by measurement: the YAML form's bridge writes an io's name, type and required, nothing more, so none of these
constructs can be written there (the parity guard re-measures that, tests/test_rule_form_parity.py).
Each rule: a positive map, a negative map, and the exemptions. The location names the node and the io by kind and
index (`node 'T1' output[0] "opp"`; single quotes mark ids, the name is not one), which the designer reads to place the finding under that io row.
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_spec = importlib.util.spec_from_file_location('vw_t1303', os.path.join(ROOT, 'tools', 'validate-workflow.py'))
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

PREFIXES = ('<bpmn:extensionElements><aef:meta mappingVersion="1.1"><aef:prefixes>'
            '<aef:prefix name="sfdc" iri="https://example.org/sfdc#" kind="field"/>'
            '</aef:prefixes></aef:meta></bpmn:extensionElements>')


def doc(io, prefixes=PREFIXES):
    return """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:aef="http://anchorpoint.framework/aef/extensions">
  <bpmn:process id="Pool_t" name="t">%s
    <bpmn:laneSet id="LS"><bpmn:lane id="agent" name="Agent">
      <bpmn:flowNodeRef>s</bpmn:flowNodeRef><bpmn:flowNodeRef>T1</bpmn:flowNodeRef><bpmn:flowNodeRef>e</bpmn:flowNodeRef>
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="s"/>
    <bpmn:task id="T1" name="Write"><bpmn:extensionElements><aef:io>%s</aef:io></bpmn:extensionElements></bpmn:task>
    <bpmn:endEvent id="e"/>
    <bpmn:sequenceFlow id="f1" sourceRef="s" targetRef="T1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="T1" targetRef="e"/>
  </bpmn:process>
</bpmn:definitions>""" % (prefixes, io)


def hits(io, rule, prefixes=PREFIXES):
    return [f for f in vw.run_xml(doc(io, prefixes)) if f.rule == rule]


R1, R2, R3 = 'E-XML-IO-MATCH-MISSING', 'E-XML-IO-PREFIX-UNDECLARED', 'W-XML-IO-MATCH-UNRESOLVED'
CASES = []


def case(name):
    def wrap(fn):
        CASES.append((name, fn))
        return fn
    return wrap


@case('R1 positive: update / upsert / delete without a match field is an ERROR, one per io, located on it')
def _():
    for op in ('update', 'upsert', 'delete'):
        h = hits('<aef:output name="opp" typeRef="sfdc:Opp" operation="%s">'
                 '<aef:field fieldRef="sfdc:Opp.Name" role="write"/></aef:output>' % op, R1)
        assert len(h) == 1 and h[0].severity == vw.ERROR, (op, [x.as_dict() for x in h])
        assert h[0].location == 'node \'T1\' output[0] "opp"', h[0].location


@case('R1 negative: a match field, or create / read / no operation, is silent')
def _():
    assert not hits('<aef:output name="opp" typeRef="sfdc:Opp" operation="delete">'
                    '<aef:field fieldRef="sfdc:Opp.Id" role="match"/></aef:output>', R1)
    for op in ('create', 'read', ''):
        attr = ' operation="%s"' % op if op else ''
        assert not hits('<aef:output name="opp" typeRef="sfdc:Opp"%s/>' % attr, R1), op


@case('R2 positive: an undeclared prefix on the io or an aef:field is an ERROR naming the attribute')
def _():
    h = hits('<aef:input name="opp" typeRef="sf:Opportunity" conceptRef="biz:Deal">'
             '<aef:field fieldRef="crm:Opp.Id" role="read"/></aef:input>', R2)
    got = sorted(f.message.split("'")[1] for f in h)
    assert got == ['biz', 'crm', 'sf'], [f.as_dict() for f in h]
    assert all(f.severity == vw.ERROR and f.location == 'node \'T1\' input[0] "opp"' for f in h)


@case('R2 negative: declared prefix, http / https / urn, a non-CURIE, and `ref` are silent')
def _():
    assert not hits('<aef:input name="a" typeRef="sfdc:Opp" conceptRef="https://example.org/c#Deal" '
                    'fieldRef="urn:x:y" ref="nid:attr-1"><aef:field fieldRef="sfdc:Opp.Id" role="read"/>'
                    '<aef:field fieldRef="http://example.org/f" role="read"/><aef:field path="Name"/></aef:input>', R2)
    assert not hits('<aef:input name="b" fieldRef="NoColonHere"/>', R2)


@case('R2 without any prefix map: every CURIE prefix is undeclared')
def _():
    h = hits('<aef:input name="opp" fieldRef="sfdc:Opp.Id"/>', R2, prefixes='')
    assert len(h) == 1 and "'sfdc'" in h[0].message, [f.as_dict() for f in h]


@case('R3 positive: a match field with neither fieldRef nor path is a WARN')
def _():
    h = hits('<aef:output name="opp" typeRef="sfdc:Opp" operation="update"><aef:field role="match"/></aef:output>', R3)
    assert len(h) == 1 and h[0].severity == vw.WARN and h[0].location == 'node \'T1\' output[0] "opp"', \
        [f.as_dict() for f in h]


@case('R3 negative: a match field with fieldRef or with path is silent, and R3 does not double as R1')
def _():
    io = ('<aef:output name="a" typeRef="sfdc:Opp" operation="update"><aef:field fieldRef="sfdc:Opp.Id" role="match"/>'
          '</aef:output><aef:output name="b" typeRef="sfdc:Opp" operation="update"><aef:field path="Id" role="match"/>'
          '</aef:output>')
    assert not hits(io, R3)
    assert not hits(io, R1)
    assert not hits('<aef:output name="c" typeRef="sfdc:Opp" operation="update"><aef:field role="match"/></aef:output>',
                    R1)


@case('location index counts inputs and outputs separately, in document order')
def _():
    io = ('<aef:input name="i0"/><aef:output name="o0" operation="update"/>'
          '<aef:input name="i1"/><aef:output name="" operation="delete"/>')
    locs = sorted(f.location for f in hits(io, R1))
    assert locs == ['node \'T1\' output[0] "o0"', 'node \'T1\' output[1] ""'], locs


@case('a v1 map (no v1.1 attributes) draws none of the three')
def _():
    io = '<aef:input name="opp" type="object" ref="nid:x" dataType="id" required="true"/><aef:output name="o"/>'
    for rule in (R1, R2, R3):
        assert not hits(io, rule, prefixes=''), rule


@case('the corpus-impact scan (tools/_t1303-corpus-impact.py) flags each rule fixture with the rule the validator fires')
def _():
    spec = importlib.util.spec_from_file_location('ci_t1303', os.path.join(ROOT, 'tools', '_t1303-corpus-impact.py'))
    ci = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(ci)
    fx = os.path.join(ROOT, 'tests', 'fixtures')
    for path, want, rule in (('invalid/E-XML-IO-MATCH-MISSING.bpmn', 'R1', R1),
                             ('invalid/E-XML-IO-PREFIX-UNDECLARED.bpmn', 'R2', R2),
                             ('warn/W-XML-IO-MATCH-UNRESOLVED.bpmn', 'R3', R3)):
        got = ci.scan(os.path.join(fx, path))
        fired = {f.rule for f in vw.run_xml(open(os.path.join(fx, path), encoding='utf-8').read())}
        assert rule in fired, (path, 'validator', fired)
        assert got[want] and not any(got[k] for k in ('R1', 'R2', 'R3') if k != want), (path, got)


def main():
    failed = 0
    for name, fn in CASES:
        try:
            fn()
            print('PASS  ' + name)
        except AssertionError as e:
            failed += 1
            print('FAIL  %s: %s' % (name, e))
    print('T-1303 io lint: %d passed, %d failed' % (len(CASES) - failed, failed))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
