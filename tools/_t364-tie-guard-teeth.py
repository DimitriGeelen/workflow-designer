#!/usr/bin/env python3
"""_t364-tie-guard-teeth.py — prove the T-364 regression guard can go RED.

`_t364-tie-permutes-ids.mjs` changed polarity when repair (a) landed. It used to exit 0
when the DEFECT was present; it now exits 0 when the REPAIR HOLDS and 1 on regression.
That new failure branch has never fired, and a guard whose red is unproven is a guard
that reports green for both "the repair holds" and "the check silently stopped working".

Two runs, neither of which touches src/ (the probe takes T364_SRC):

  control  the real source                   -> expect rc=0, "REPAIR HOLDS"
  teeth    a copy with deriveUid reverted    -> expect rc=1, "REGRESSION"
           to the random generateUid mint

The mutation is the exact defect the repair removed: put the two `|| generateUid(...)`
fallbacks back into parseBpmnXml. If the guard cannot see THAT, it cannot see anything.

The load-bearing assertion is the control. A guard that fires on everything is as
useless as one that fires on nothing.

Usage: python3 tools/_t364-tie-guard-teeth.py
Exit 0 = the guard goes red for a reintroduced random mint and stays green for the real
         source.
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
PROBE = os.path.join(HERE, "_t364-tie-permutes-ids.mjs")

# The repair, and the pre-repair expression it replaced. Reverting these two is what
# reintroduces the nondeterministic mint.
MUTATIONS = [
    ("deriveUid('n', displayId)", "generateUid('n')"),
    ("deriveUid('e', el.getAttribute('id') || '')", "generateUid('e')"),
]


def run(src_path):
    env = dict(os.environ, T364_SRC=src_path)
    p = subprocess.run([shutil.which("node"), PROBE],
                       capture_output=True, text=True, timeout=1800, env=env)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


rc_ctl, out_ctl = run(SRC)
print(f"control : rc={rc_ctl}  HOLDS={'REPAIR HOLDS' in out_ctl}  "
      f"REGRESSION={'REGRESSION' in out_ctl}")
if rc_ctl != 0 or "REPAIR HOLDS" not in out_ctl:
    print("TEETH BROKEN — the real source does not pass, so nothing below proves anything.")
    print(out_ctl[-900:])
    raise SystemExit(2)

text = open(SRC, encoding="utf-8").read()
for old, new in MUTATIONS:
    if text.count(old) != 1:
        print(f"TEETH BROKEN — expected exactly one occurrence of {old!r}, found "
              f"{text.count(old)}. The repair moved; re-anchor this mutation before "
              f"trusting the guard.")
        raise SystemExit(2)
    text = text.replace(old, new)

d = tempfile.mkdtemp(prefix="t364-guard-teeth-")
mutated = os.path.join(d, "designer-mutated.html")
try:
    with open(mutated, "w", encoding="utf-8") as fh:
        fh.write(text)
    rc_th, out_th = run(mutated)
finally:
    shutil.rmtree(d, ignore_errors=True)

print(f"teeth   : rc={rc_th}  HOLDS={'REPAIR HOLDS' in out_th}  "
      f"REGRESSION={'REGRESSION' in out_th}")

fails = []
if rc_th == 0:
    fails.append("the run PASSED with the random mint reinstated — the guard never fired")
if "REGRESSION" not in out_th:
    fails.append("output does not state a regression")
if "REPAIR HOLDS" in out_th:
    fails.append("output claims the repair holds while the mint is random again")

print()
if fails:
    for f in fails:
        print("  FAIL " + f)
    print("\nTEETH FAIL — the guard cannot see the defect it exists to catch.")
    sys.exit(1)
print("TEETH PASS — the guard goes red when the nondeterministic mint returns and stays")
print("green for the real source.")
sys.exit(0)
