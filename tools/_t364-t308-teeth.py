#!/usr/bin/env python3
"""_t364-t308-teeth.py — prove _t308's `unusable` bucket can actually FILL.

G-023's prevention added a self-stability check to the byte-identity gate: a document
that is not byte-stable with itself is reported `unusable` rather than counted
`identical`. The first run came back `unusable: 0` — which is exactly what a check
that cannot fire also reports. A bucket whose count is the finding has to be shown
fillable before its emptiness means anything.

Two runs against a TEMP corpus (the real corpus is never touched — _t308 takes
T308_CORPUS):

  control  the 24 designer maps            -> expect ok=true,  unusable=0, identical=24
  teeth    the same 24 + one third-party   -> expect ok=FALSE, unusable=1, identical=24

The teeth document is a real third-party fixture: it arrives without `aef:uid`, so the
importer mints fresh ones per parse and it cannot be byte-compared at all. That is the
population the gate was silently omitting, so it is the honest thing to inject.

The second assertion is the load-bearing one: `identical` must stay 24. If the
unstable document were counted identical, or dropped from every count, the gate would
be overstating or quietly shrinking its own denominator — the two failure modes G-023
was registered for.

---- WHY THIS STILL PASSES AFTER THE T-364 REPAIR, AND WHEN IT WILL STOP ----

Repair (a) made uid derive from the element id, so a third-party document IS now
byte-stable with itself in the CURRENT build. These teeth kept passing anyway, and
the reason is worth naming rather than enjoying: _t308 emits each map twice in BOTH
builds, and the baseline (`3bf37909~1`) still has the random mint, so the injected
document is unusable on the baseline side. The teeth now depend on a property of the
BASELINE, not of the code under test.

The day `BASELINE_REF` moves past the repair, both sides derive, the injected document
becomes perfectly comparable, `unusable` goes to 0 and these teeth go RED — reporting
"the bucket cannot fill" when the truth is "this injection is no longer a hazard".
When that happens the fix is a NEW injection that is genuinely unstable in both builds
(a document with a nondeterministic emitted field, whatever the next one turns out to
be), NOT deleting the teeth and NOT pinning BASELINE_REF to keep them green. A teeth
file that is green because its baseline is old is measuring history.

Usage: python3 tools/_t364-t308-teeth.py     Exit 0 = the bucket fills as predicted.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CORPUS = os.path.join(ROOT, "examples", "aef-processes", "rendered")
UNSTABLE = os.path.join(ROOT, "tests", "fixtures", "third-party", "simple.bpmn")
REF = "3bf37909~1"


def run(corpus_dir):
    env = dict(os.environ, T308_CORPUS=corpus_dir)
    p = subprocess.run(
        [shutil.which("node"), os.path.join(HERE, "_t308-export-byte-identity-cdp.mjs"), REF],
        capture_output=True, text=True, timeout=1800, env=env,
    )
    try:
        return p.returncode, json.loads(p.stdout)
    except Exception:
        print("TEETH BROKEN — _t308 did not emit parseable JSON:")
        print((p.stdout or "")[-800:])
        print((p.stderr or "")[-400:])
        raise SystemExit(2)


def temp_corpus(extra=None):
    d = tempfile.mkdtemp(prefix="t364-corpus-")
    for f in os.listdir(CORPUS):
        if f.endswith(".bpmn"):
            shutil.copy2(os.path.join(CORPUS, f), os.path.join(d, f))
    if extra:
        shutil.copy2(extra, os.path.join(d, "_teeth-unstable.bpmn"))
    return d


if not os.path.exists(UNSTABLE):
    raise SystemExit(f"TEETH BROKEN — teeth fixture missing: {UNSTABLE}")

fails = []

ctl_dir = temp_corpus()
try:
    rc, ctl = run(ctl_dir)
finally:
    shutil.rmtree(ctl_dir, ignore_errors=True)
print(f"control : rc={rc} maps={ctl['maps']} identical={ctl['identical']} "
      f"drifted={ctl['drifted']} unusable={ctl['unusable']}")
if rc != 0:
    print("TEETH BROKEN — the control corpus does not pass, so nothing below proves anything.")
    print(json.dumps(ctl.get("drift") or ctl.get("errors"), indent=2)[:800])
    raise SystemExit(2)
if ctl["unusable"] != 0:
    fails.append("control corpus reported an unusable map")
baseline_identical = ctl["identical"]

teeth_dir = temp_corpus(extra=UNSTABLE)
try:
    rc, th = run(teeth_dir)
finally:
    shutil.rmtree(teeth_dir, ignore_errors=True)
print(f"teeth   : rc={rc} maps={th['maps']} identical={th['identical']} "
      f"drifted={th['drifted']} unusable={th['unusable']}")

if rc == 0:
    fails.append("the gate PASSED with a document it cannot compare — the unusable path never fired")
if th["unusable"] != 1:
    fails.append(f"expected exactly 1 unusable map, got {th['unusable']}")
if th["identical"] != baseline_identical:
    fails.append(
        f"identical moved {baseline_identical} -> {th['identical']}: the unstable document was "
        "absorbed into a verdict instead of being held out")
names = [m.get("map") for m in th.get("unusableMaps", [])]
if names != ["_teeth-unstable"]:
    fails.append(f"unusable map named {names!r}, expected ['_teeth-unstable']")
if not th.get("population", {}).get("does_not_cover"):
    fails.append("the run does not state the population it cannot cover")

print()
if fails:
    for f in fails:
        print("  FAIL " + f)
    print("\nTEETH FAIL — _t308's unusable path is not doing what G-023 requires.")
    sys.exit(1)
print("TEETH PASS — the unusable bucket fills, the run goes red for it, `identical` does")
print("not absorb it, and the population it cannot cover is stated in the output.")
sys.exit(0)
