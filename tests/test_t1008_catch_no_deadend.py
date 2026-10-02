"""T-1008 / ledger L20: a link catch is an entry and draws no DEADEND of its own.

Before: a catch placed in front of a step whose successor is unrecorded drew W-(XML-)DEADEND on the
step AND on the catch — one unknown reported twice, while AUTHORING says a catch draws no
reachability warning. Confirmed by three calibrated reviewers (T-1006).

Both forms are pinned, plus the control that keeps the fix narrow: a catch REACHED BY FLOW (a
mid-flow wait) is still assessed, so a real trap behind it is not hidden.
"""
import importlib.util
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_spec = importlib.util.spec_from_file_location('vw_t1008', os.path.join(ROOT, 'tools', 'validate-workflow.py'))
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

YAML = """
workflowMeta: {id: t, version: 1, schemaVersion: 2}
pool: {id: Pool_t, name: t}
lanes:
  - {id: a, name: Ops, abbr: ops, authority: initiative, height: 400}
nodes:
  - {uid: s, type: startEvent, name: S, lane: a, x: 50, y: 100}
  - {uid: t1, type: task, name: T1, lane: a, x: 150, y: 100}
  - {uid: e, type: endEvent, name: E, lane: a, x: 250, y: 100}
  - {uid: in1, type: linkEventCatch, name: from P, lane: a, x: 50, y: 200}
  - {uid: x1, type: task, name: X1, lane: a, x: 150, y: 200}
edges:
  - {uid: f1, source: s, target: t1}
  - {uid: f2, source: t1, target: e}
  - {uid: f3, source: in1, target: x1}
"""

XML = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:aef="http://anchorpoint.framework/aef/extensions">
  <bpmn:process id="Pool_t" name="t">
    <bpmn:laneSet id="LS"><bpmn:lane id="agent" name="Agent">
      <bpmn:flowNodeRef>s</bpmn:flowNodeRef><bpmn:flowNodeRef>t1</bpmn:flowNodeRef>
      <bpmn:flowNodeRef>e</bpmn:flowNodeRef><bpmn:flowNodeRef>in1</bpmn:flowNodeRef>
      <bpmn:flowNodeRef>x1</bpmn:flowNodeRef>%(extra_refs)s
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="s"/><bpmn:task id="t1"/><bpmn:endEvent id="e"/>
    <bpmn:intermediateCatchEvent id="in1"/><bpmn:task id="x1"/>%(extra_nodes)s
    <bpmn:sequenceFlow id="f1" sourceRef="s" targetRef="t1"/>
    <bpmn:sequenceFlow id="f2" sourceRef="t1" targetRef="e"/>
    <bpmn:sequenceFlow id="f3" sourceRef="in1" targetRef="x1"/>%(extra_flows)s
  </bpmn:process>
</bpmn:definitions>
"""


def _deadends(findings, rule):
    return sorted(f.location for f in findings if f.rule == rule)


def test_yaml_link_catch_draws_no_deadend():
    got = _deadends(vw.run_yaml(YAML), 'W-DEADEND')
    assert got == ["node 'x1'"], got


def test_xml_link_catch_draws_no_deadend():
    got = _deadends(vw.run_xml(XML % dict(extra_refs='', extra_nodes='', extra_flows='')), 'W-XML-DEADEND')
    assert got == ["node 'x1'"], got


def test_xml_catch_reached_by_flow_is_still_assessed():
    # t1 -> w (a mid-flow wait) -> nothing: w is a real dead end and must still be reported.
    xml = XML % dict(extra_refs='<bpmn:flowNodeRef>w</bpmn:flowNodeRef>',
                     extra_nodes='<bpmn:intermediateCatchEvent id="w"/>',
                     extra_flows='<bpmn:sequenceFlow id="f4" sourceRef="t1" targetRef="w"/>')
    got = _deadends(vw.run_xml(xml), 'W-XML-DEADEND')
    assert "node 'w'" in got and "node 'in1'" not in got, got
