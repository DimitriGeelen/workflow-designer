#!/usr/bin/env python3
"""_t364-byteid-precondition-teeth.py — prove the byte-identity precondition can FIRE.

`_t358-byteid-thirdparty.mjs` normalises `aef:uid` and nothing else. That is sound only
while a uid cannot influence any other emitted byte — and it can: `computeDisplayId`
breaks a same-lane x tie with `uid.localeCompare`, and `displayIdOf` IS the emitted BPMN
element id. T-364 added a precondition check that measures the tie and refuses the run
when a fixture has a tie among uid-less nodes.

It reported PRECONDITION HOLDS on the first run, which is exactly what a check that
cannot fire also reports. This makes it fire.

Two runs against a TEMP fixture dir (the real one is never touched — the tool takes
T358_FIXDIR):

  control  the 10 real third-party fixtures        -> expect rc=0, "PRECONDITION HOLDS"
  teeth    the same 10 + one crafted tie document  -> expect rc=1, "PRECONDITION VIOLATED"

The teeth document is the population the precondition exists for and which no current
fixture can be: nodes that carry `aef:position` (so the importer does NOT lay them out
strictly increasing) at an IDENTICAL x in one lane, and NO `aef:uid` anywhere. Today the
real fixtures cannot hold that combination — none carries aef:position at all — which is
precisely why the hazard bucket is empty and why its emptiness proves nothing on its own.

The load-bearing assertion is the second one: the control must still say HOLDS. A
precondition that fires on everything is as useless as one that fires on nothing.

Usage: python3 tools/_t364-byteid-precondition-teeth.py
Exit 0 = the hazard path fires for the crafted document and stays quiet for the real set.
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FIX = os.path.join(ROOT, "tests", "fixtures", "third-party")
TOOL = os.path.join(HERE, "_t358-byteid-thirdparty.mjs")
REF = "3bf37909~1"

# Two nodes, one lane, SAME x in aef:position, no aef:uid anywhere in the document.
TIE_DOC = """<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
                  xmlns:aef="http://anchorpoint.framework/aef/extensions"
                  id="Definitions_tie" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_tie" isExecutable="false">
    <bpmn:laneSet id="LaneSet_1">
      <bpmn:lane id="Lane_1" name="Lane">
        <bpmn:extensionElements>
          <aef:laneMeta abbr="lan" authority="initiative" height="130"/>
        </bpmn:extensionElements>
        <bpmn:flowNodeRef>lan_1_alpha</bpmn:flowNodeRef>
        <bpmn:flowNodeRef>lan_2_bravo</bpmn:flowNodeRef>
      </bpmn:lane>
    </bpmn:laneSet>
    <bpmn:task id="lan_1_alpha" name="alpha">
      <bpmn:extensionElements><aef:position x="300.0" y="60.0"/></bpmn:extensionElements>
    </bpmn:task>
    <bpmn:task id="lan_2_bravo" name="bravo">
      <bpmn:extensionElements><aef:position x="300.0" y="60.0"/></bpmn:extensionElements>
    </bpmn:task>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="D_1"><bpmndi:BPMNPlane id="P_1" bpmnElement="Process_tie"/></bpmndi:BPMNDiagram>
</bpmn:definitions>
"""


def temp_fixtures(extra_name=None, extra_text=None):
    d = tempfile.mkdtemp(prefix="t364-fix-")
    for f in os.listdir(FIX):
        if f.endswith(".bpmn"):
            shutil.copy2(os.path.join(FIX, f), os.path.join(d, f))
    if extra_name:
        with open(os.path.join(d, extra_name), "w") as fh:
            fh.write(extra_text)
    return d


def run(fixdir):
    env = dict(os.environ, T358_FIXDIR=fixdir)
    p = subprocess.run([shutil.which("node"), TOOL, REF],
                       capture_output=True, text=True, timeout=1800, env=env)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


fails = []

d = temp_fixtures()
try:
    rc_ctl, out_ctl = run(d)
finally:
    shutil.rmtree(d, ignore_errors=True)
print(f"control : rc={rc_ctl}  HOLDS={'PRECONDITION HOLDS' in out_ctl}  "
      f"VIOLATED={'PRECONDITION VIOLATED' in out_ctl}")
if rc_ctl != 0 or "PRECONDITION HOLDS" not in out_ctl:
    print("TEETH BROKEN — the real fixture set does not pass, so nothing below proves anything.")
    print(out_ctl[-900:])
    raise SystemExit(2)

d = temp_fixtures("_teeth-xtie.bpmn", TIE_DOC)
try:
    rc_th, out_th = run(d)
finally:
    shutil.rmtree(d, ignore_errors=True)
print(f"teeth   : rc={rc_th}  HOLDS={'PRECONDITION HOLDS' in out_th}  "
      f"VIOLATED={'PRECONDITION VIOLATED' in out_th}")

if rc_th == 0:
    fails.append("the run PASSED with a tie among uid-less nodes — the hazard path never fired")
if "PRECONDITION VIOLATED" not in out_th:
    fails.append("output does not state the precondition was violated")
if "PRECONDITION HOLDS" in out_th:
    fails.append("output claims the precondition HOLDS while also carrying the hazard")
if "_teeth-xtie.bpmn" not in out_th:
    fails.append("the violating document is not named in the output")

print()
if fails:
    for f in fails:
        print("  FAIL " + f)
    print("\nTEETH FAIL — the precondition cannot fire, so its HOLDS means nothing.")
    sys.exit(1)
print("TEETH PASS — the precondition fires for a tie among uid-less nodes, names the")
print("document, refuses the run, and stays quiet for the real fixture set.")
sys.exit(0)
