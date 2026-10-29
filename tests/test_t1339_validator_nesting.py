"""T-1339 (T-1266 GO, slice 1): the validator walks into subprocess containers.

The designer now saves another tool's nested nodes and flows inside their subProcess, transaction or adHocSubProcess.
Before, the validator read only the process's direct children: a nested flow naming a node that does not exist went
unreported, and (when the designer moved every nested node up to the process) each nested node outside the lanes was
E-XML-NODE-UNASSIGNED. Pinned here:
  1. a dangling reference inside a container is reported (the walk reaches it; red on the pre-T-1339 validator);
  2. a nested node in no lane is not E-XML-NODE-UNASSIGNED (Camunda Modeler lists none in the lanes, T-1266 F3),
     while a top-level node in no lane still is (the rule is unchanged for the process's own nodes);
  3. a container's own children (incoming/outgoing, loop markers, completionCondition) are not taken for flow nodes;
  4. a process with no nested content is walked exactly as before (the helper returns list(process)).
"""
import importlib.util
import os
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_spec = importlib.util.spec_from_file_location('vw_t1339', os.path.join(ROOT, 'tools', 'validate-workflow.py'))
vw = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(vw)

XML = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:aef="http://anchorpoint.framework/aef/extensions">
  <bpmn:process id="Pool_t" name="t">
    <bpmn:laneSet id="LS"><bpmn:lane id="agent" name="Agent">
      <bpmn:flowNodeRef>s</bpmn:flowNodeRef><bpmn:flowNodeRef>sub</bpmn:flowNodeRef><bpmn:flowNodeRef>e</bpmn:flowNodeRef>
    </bpmn:lane></bpmn:laneSet>
    <bpmn:startEvent id="s"/>
    <bpmn:sequenceFlow id="f1" sourceRef="s" targetRef="sub"/>
    <bpmn:subProcess id="sub" name="Inner">
      <bpmn:incoming>f1</bpmn:incoming>
      <bpmn:outgoing>f2</bpmn:outgoing>
      <bpmn:standardLoopCharacteristics/>
      <bpmn:startEvent id="in_s"/>
      <bpmn:sequenceFlow id="in_f" sourceRef="in_s" targetRef="%(inner_target)s"/>
      <bpmn:endEvent id="in_e"/>
    </bpmn:subProcess>
    <bpmn:sequenceFlow id="f2" sourceRef="sub" targetRef="e"/>
    <bpmn:endEvent id="e"/>%(extra)s
  </bpmn:process>
</bpmn:definitions>
"""


def _rules(xml, rule):
    return sorted(f.location for f in vw.run_xml(xml) if f.rule == rule)


def test_dangling_reference_inside_a_container_is_reported():
    got = _rules(XML % dict(inner_target='nowhere', extra=''), 'E-XML-FLOW-DANGLING')
    assert got == ["sequenceFlow 'in_f'"], got


def test_resolved_inner_flow_is_not_dangling():
    assert _rules(XML % dict(inner_target='in_e', extra=''), 'E-XML-FLOW-DANGLING') == []


def test_nested_node_in_no_lane_is_not_unassigned_but_top_level_still_is():
    got = _rules(XML % dict(inner_target='in_e', extra='\n    <bpmn:endEvent id="loose"/>'), 'E-XML-NODE-UNASSIGNED')
    assert got == ["node 'loose'"], got


def test_container_own_children_are_not_flow_nodes():
    # incoming/outgoing/standardLoopCharacteristics inside the subProcess would be E-XML-NODE-TYPE if walked as nodes
    assert _rules(XML % dict(inner_target='in_e', extra=''), 'E-XML-NODE-TYPE') == []


def test_flat_process_walk_is_unchanged():
    root = ET.fromstring((XML % dict(inner_target='in_e', extra='')).encode())
    proc = root.find('{http://www.omg.org/spec/BPMN/20100524/MODEL}process')
    flat = ET.fromstring(ET.tostring(proc))
    for sub in flat.findall('{http://www.omg.org/spec/BPMN/20100524/MODEL}subProcess'):
        for c in list(sub):
            sub.remove(c)
    walk = vw.XmlValidator()._flow_children(flat)
    assert walk == list(flat)
    # and with the contents left in, they follow their container, the container's own children skipped
    assert [c.get('id') for c in vw.XmlValidator()._flow_children(proc) if c.get('id')] == \
        ['LS', 's', 'f1', 'sub', 'in_s', 'in_f', 'in_e', 'f2', 'e']
