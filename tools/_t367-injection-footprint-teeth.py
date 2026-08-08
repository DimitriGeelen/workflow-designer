#!/usr/bin/env python3
"""_t367-injection-footprint-teeth.py — prove the footprint census MEASURES.

`_t367-aef-injection-footprint.mjs` prints a table of what we inject into a foreign
document and concludes that uid is 48.5% of it. A census that recited a hard-coded
vocabulary, or whose controls could not fail, would print a table of exactly the same
shape. So each load-bearing claim gets a mutation that must move it.

Four legs, three of which attack the probe's own controls rather than its subject —
the controls are what license reading the numbers, so an inert control is worse than a
wrong count.

  control  real source                      -> rc=0, all controls PASS
  (a)      emitter stops writing aef:uid    -> rc=1, POSITIVE CONTROL FAILED
           Without this, "uid injected 149x" could be a constant. The positive
           control exists to prove the open->save actually ran; a control that
           cannot go red proves nothing about that.
  (b)      emitter writes EVERY kind        -> rc=1, NEGATIVE CONTROL FAILED
           The negative control's job is to distinguish "we inject 4 kinds" from
           "the harvester matches too broadly and would report any kind present".
           This makes every kind present and requires the control to notice.
  (c)      emitter stops writing aef:position -> rc=0, but the census TOTAL must move
           and aef:position must leave the table. Legs (a)/(b) only prove the
           controls fire. This proves the census itself tracks the emitter instead
           of reprinting a vocabulary — the failure mode that produces a confident,
           stable, wrong table.

Leg (c) deliberately expects rc=0: removing a kind we inject is not an error, it is a
different measurement, and a probe that went red would be reporting "the emitter
changed" as "the probe broke". Its assertion is on the NUMBERS, not the exit code.

None of the legs touch src/ — the probe takes T367_SRC and every mutation lands in a
temp copy.

Usage: python3 tools/_t367-injection-footprint-teeth.py
Exit 0 = every leg behaved; the census and its controls have teeth.
Exit 1 = a leg failed; the corresponding claim in the census is not evidence.
Exit 2 = teeth broken (anchor moved, control run already red) — nothing proven.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
PROBE = os.path.join(HERE, "_t367-aef-injection-footprint.mjs")

# aef:uid is emitted at TWO sites — nodes and edges. The first version of leg (a)
# removed only the node site and the leg went green: 29 edge uids kept the positive
# control satisfied, and the control was RIGHT to be satisfied, because the save had
# in fact run. A single-site mutation against a two-site emission tests nothing, and
# it fails in the direction that looks like success. Both sites, or the leg is a lie.
UID_ANCHOR = 'if (node.uid) out += `        <aef:uid value="${escAttr(node.uid)}"/>\\n`;'
UID_ANCHOR_E = 'if (e.uid) lines.push(`        <aef:uid value="${escAttr(e.uid)}"/>`);'
POS_ANCHOR = ('out += `        <aef:position x="${node.x.toFixed(1)}" '
              'y="${node.y.toFixed(1)}"/>\\n`;')

# Every kind the probe lists as emittable. Leg (b) emits all of them so the
# not-injected set empties and the negative control has to fire.
ALL_KINDS = ['uid', 'position', 'meta', 'endpoint', 'contextReads', 'artifactsWrites',
             'decisionInput', 'decisionOutputs', 'link', 'eventDef', 'boundaryPos',
             'io', 'input', 'output', 'constituents', 'constituent', 'workflowMeta',
             'laneMeta', 'anchors', 'loopDetour', 'forceStraight', 'routingHint',
             'routing', 'waypoint']
FLOOD = "".join(f"<aef:{k} teeth=\\\"1\\\"/>" for k in ALL_KINDS)


def run(src_path):
    env = dict(os.environ, T367_SRC=src_path)
    p = subprocess.run([shutil.which("node"), PROBE],
                       capture_output=True, text=True, timeout=1800, env=env)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def mutate(pairs):
    """Write a temp copy of src with each (old, new) applied; anchors must be unique."""
    text = open(SRC, encoding="utf-8").read()
    for old, new in pairs:
        if text.count(old) != 1:
            print(f"TEETH BROKEN — anchor is not unique ({text.count(old)} occurrences):\n"
                  f"  {old}\nThe emitter moved; re-anchor before trusting this result.")
            raise SystemExit(2)
        text = text.replace(old, new)
    d = tempfile.mkdtemp(prefix="t367-teeth-")
    path = os.path.join(d, "designer-mutated.html")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    return d, path


def census_total(out):
    m = re.search(r"^\s*TOTAL\s+\d+\s+\d+\s+(\d+)\s*$", out, re.M)
    return int(m.group(1)) if m else None


fails = []

# ---- control ----
rc, out = run(SRC)
ctl_total = census_total(out)
print(f"control : rc={rc}  total_injected={ctl_total}")
if rc != 0 or ctl_total is None:
    print("TEETH BROKEN — the real source does not produce a clean census, so no leg below\n"
          "proves anything.")
    print(out[-1200:])
    raise SystemExit(2)

# ---- leg (a): positive control must fire ----
d, path = mutate([(UID_ANCHOR, "/* teeth(a): node uid emission removed */;"),
                  (UID_ANCHOR_E, "/* teeth(a): edge uid emission removed */;")])
try:
    rc_a, out_a = run(path)
finally:
    shutil.rmtree(d, ignore_errors=True)
print(f"(a) uid  : rc={rc_a}  POS_FAILED={'POSITIVE CONTROL      FAILED' in out_a}")
if rc_a == 0:
    fails.append("(a) the probe PASSED with aef:uid emission removed — the positive control "
                 "cannot fire, so 'the open->save ran' is not evidenced by it")
if "POSITIVE CONTROL      FAILED" not in out_a:
    fails.append("(a) the run went red but did not name the positive control — it cannot "
                 "distinguish a broken harness from a genuine change in what we inject")

# ---- leg (b): negative control must fire ----
d, path = mutate([(UID_ANCHOR, UID_ANCHOR + f"\n  out += '        {FLOOD}\\n';")])
try:
    rc_b, out_b = run(path)
finally:
    shutil.rmtree(d, ignore_errors=True)
print(f"(b) flood: rc={rc_b}  NEG_FAILED={'NEGATIVE CONTROL      FAILED' in out_b}")
if rc_b == 0:
    fails.append("(b) the probe PASSED with every emittable kind written into the output — "
                 "the negative control cannot fire, so 'the census discriminates' is unproven "
                 "and a too-broad harvester would read identically")
if "NEGATIVE CONTROL      FAILED" not in out_b:
    fails.append("(b) the run went red but did not name the negative control")

# ---- leg (c): the census itself must track the emitter ----
d, path = mutate([(POS_ANCHOR, "/* teeth(c): position emission removed */;")])
try:
    rc_c, out_c = run(path)
finally:
    shutil.rmtree(d, ignore_errors=True)
c_total = census_total(out_c)
has_pos = bool(re.search(r"^\s*aef:position\s", out_c, re.M))
print(f"(c) pos  : rc={rc_c}  total_injected={c_total}  position_row_present={has_pos}")
if rc_c != 0:
    fails.append(f"(c) the probe exited {rc_c} when a kind it reports on stopped being emitted. "
                 "That is a different measurement, not a broken probe — reporting it as red "
                 "would send the reader to debug a working instrument")
if has_pos:
    fails.append("(c) aef:position still appears in the census after its emission was removed — "
                 "the census is reciting a vocabulary, not measuring the output")
if c_total is None or ctl_total is None or c_total >= ctl_total:
    fails.append(f"(c) the injected total did not fall ({ctl_total} -> {c_total}) after removing "
                 "an emission — the totals are not derived from the bytes")

print()
if fails:
    for f in fails:
        print("  FAIL " + f)
    print("\nTEETH FAIL — at least one claim in the footprint census is not backed by an\n"
          "instrument that could have said otherwise.")
    sys.exit(1)
print("TEETH PASS — positive and negative controls both fire under mutation, and the")
print("census total tracks the emitter rather than reprinting a fixed vocabulary.")
sys.exit(0)
