#!/usr/bin/env python3
"""_t366-uid-shape-teeth.py — prove the uid-shape probe can SEE a shape validator.

`_t366-uid-shape-agnostic.mjs` reports NO SHAPE CONSTRAINT, which is exactly what a
probe blind to shape constraints also reports. This makes one exist.

Two runs, neither touching src/ (the probe takes T366_SRC):

  control  the real source                    -> expect rc=0, "NO SHAPE CONSTRAINT"
  teeth    a copy whose import path coerces    -> expect rc=1, "SHAPE CONSTRAINT FOUND"
           any uid not matching ^n_[0-9a-f]{8}$

The mutation is the hazard AEF described at RAIL-441 in its most plausible form: not a
crash, not a rejection, but a SILENT REWRITE of any uid that does not look like ours.
That is the shape a real one would take — nobody writes a validator that throws on a
peer's identity key; they write one that "normalises" it.

TWO assertions carry this, and the second is the one worth having:

  1. The probe must go red.
  2. The probe must report a SPLIT — mint-shaped uids surviving while AEF's slugs are
     rewritten — and must NOT claim a general uid bug. A probe that goes red for any
     reason cannot distinguish "shape validator" from "uids are broken generally", and
     those two findings send the reader to different code and to different messages to
     the peer.

Usage: python3 tools/_t366-uid-shape-teeth.py
Exit 0 = the probe detects an injected shape validator AND names it as shape-selective,
         and stays quiet on the real source.
"""
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src", "aef-workflow-designer.html")
PROBE = os.path.join(HERE, "_t366-uid-shape-agnostic.mjs")

# The node-side import fallback. Wrapping it in a shape test is the whole mutation.
ANCHOR = "const uid = uidEl?.getAttribute('value') || deriveUid('n', displayId);"
MUTANT = ("const uid = (function(v){ return /^n_[0-9a-f]{8}$/.test(v || '') "
          "? v : deriveUid('n', displayId); })(uidEl?.getAttribute('value'));")

ANCHOR_E = "const uid = uidEl?.getAttribute('value') || deriveUid('e', el.getAttribute('id') || '');"
MUTANT_E = ("const uid = (function(v){ return /^e_[0-9a-f]{8}$/.test(v || '') "
            "? v : deriveUid('e', el.getAttribute('id') || ''); })(uidEl?.getAttribute('value'));")


def run(src_path):
    env = dict(os.environ, T366_SRC=src_path)
    p = subprocess.run([shutil.which("node"), PROBE],
                       capture_output=True, text=True, timeout=1800, env=env)
    return p.returncode, (p.stdout or "") + (p.stderr or "")


rc_ctl, out_ctl = run(SRC)
print(f"control : rc={rc_ctl}  NONE={'NO SHAPE CONSTRAINT' in out_ctl}  "
      f"FOUND={'SHAPE CONSTRAINT FOUND' in out_ctl}")
if rc_ctl != 0 or "NO SHAPE CONSTRAINT" not in out_ctl:
    print("TEETH BROKEN — the real source does not pass, so nothing below proves anything.")
    print(out_ctl[-900:])
    raise SystemExit(2)

text = open(SRC, encoding="utf-8").read()
for old, new in ((ANCHOR, MUTANT), (ANCHOR_E, MUTANT_E)):
    if text.count(old) != 1:
        print(f"TEETH BROKEN — expected exactly one occurrence of the import anchor, found "
              f"{text.count(old)}:\n  {old}\nThe import path moved; re-anchor before trusting "
              f"this result.")
        raise SystemExit(2)
    text = text.replace(old, new)

d = tempfile.mkdtemp(prefix="t366-teeth-")
mutated = os.path.join(d, "designer-mutated.html")
try:
    with open(mutated, "w", encoding="utf-8") as fh:
        fh.write(text)
    rc_th, out_th = run(mutated)
finally:
    shutil.rmtree(d, ignore_errors=True)

print(f"teeth   : rc={rc_th}  NONE={'NO SHAPE CONSTRAINT' in out_th}  "
      f"FOUND={'SHAPE CONSTRAINT FOUND' in out_th}")

fails = []
if rc_th == 0:
    fails.append("the run PASSED with a shape validator injected — the probe never saw it")
if "SHAPE CONSTRAINT FOUND" not in out_th:
    fails.append("output does not state a shape constraint was found")
if "NO SHAPE CONSTRAINT" in out_th:
    fails.append("output claims no constraint while one is injected")
# The discriminating assertion: shape-SELECTIVE, not a general uid bug.
if "signature of a shape validator" not in out_th:
    fails.append("the probe went red but did not identify the result as shape-SELECTIVE "
                 "(mint control surviving while slugs were rewritten) — it cannot tell a "
                 "shape validator from uids being broken generally")
if "aef-slug" not in out_th:
    fails.append("the lost-by-shape breakdown does not name aef-slug as the affected family")

print()
if fails:
    for f in fails:
        print("  FAIL " + f)
    print("\nTEETH FAIL — the probe's NO SHAPE CONSTRAINT does not mean what it says.")
    sys.exit(1)
print("TEETH PASS — the probe detects an injected shape validator, reports it as")
print("shape-SELECTIVE via the surviving mint-shaped control, and stays quiet on the")
print("real source.")
sys.exit(0)
