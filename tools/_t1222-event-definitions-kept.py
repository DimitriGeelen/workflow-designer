#!/usr/bin/env python3
"""T-1222: every native BPMN event definition a third-party map carries survives a save, per kind.

Saves each third-party fixture through the REAL designer (tools/_t358-byteid-thirdparty.mjs --record into a temp
golden dir, so nothing in the repo is written), then counts `*EventDefinition` elements per kind in each fixture and
in its save. A kind that comes back fewer times than it went in is a loss. Also checks that every messageRef /
signalRef / errorRef / escalationRef a kept definition names resolves to an element with that id in the same save,
so preserving a definition can never leave the export pointing at an id it does not contain.

Measured before the fix (2026-10-19): 47 definitions in, 3 out (link 2/2 since T-1217; message 1, from a process the
designer carries verbatim).
Exit 0 = nothing lost, every reference resolves; 1 = a loss or a dangling reference; 2 = could not measure.
"""
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXDIR = os.path.join(ROOT, "tests", "fixtures", "third-party")
DEF = re.compile(r"<(?:[A-Za-z0-9]+:)?([a-z][A-Za-z]*)EventDefinition\b")
REF = re.compile(r"\b(messageRef|signalRef|errorRef|escalationRef)=\"([^\"]+)\"")


def counts(text):
    return Counter(DEF.findall(text))


def main():
    with tempfile.TemporaryDirectory(prefix="t1222-") as out:
        env = dict(os.environ, T358_GOLDENDIR=out)
        p = subprocess.run(["node", os.path.join(ROOT, "tools", "_t358-byteid-thirdparty.mjs"), "--record"],
                           cwd=ROOT, env=env, capture_output=True, text=True, timeout=900)
        if p.returncode != 0:
            print("COULD NOT MEASURE: the save harness exited %d\n%s" % (p.returncode, (p.stdout + p.stderr)[-800:]))
            return 2
        lost, dangling, total_in, total_out = [], [], Counter(), Counter()
        fixtures = sorted(f for f in os.listdir(FIXDIR) if f.endswith(".bpmn"))
        for f in fixtures:
            saved = os.path.join(out, f + ".golden")
            if not os.path.isfile(saved):
                print("COULD NOT MEASURE: no save recorded for %s" % f)
                return 2
            src, dst = open(os.path.join(FIXDIR, f), encoding="utf-8").read(), open(saved, encoding="utf-8").read()
            ci, co = counts(src), counts(dst)
            total_in += ci
            total_out += co
            for kind, n in ci.items():
                if co[kind] < n:
                    lost.append("%s: %s %d -> %d" % (f, kind, n, co[kind]))
            ids = set(re.findall(r'\bid="([^"]+)"', dst))
            for attr, ref in REF.findall(dst):
                if ref not in ids:
                    dangling.append("%s: %s=\"%s\" names no element in the save" % (f, attr, ref))
        print("per kind, in -> out over %d fixture(s):" % len(fixtures))
        for kind in sorted(total_in):
            print("  %-12s %3d -> %3d" % (kind, total_in[kind], total_out[kind]))
        print("total %d -> %d" % (sum(total_in.values()), sum(total_out.values())))
        for line in lost:
            print("LOST      " + line)
        for line in dangling:
            print("DANGLING  " + line)
        if lost or dangling:
            print("FAIL: %d loss(es), %d dangling reference(s)" % (len(lost), len(dangling)))
            return 1
        print("OK: every native event definition survives a save, and every reference resolves")
        return 0


if __name__ == "__main__":
    sys.exit(main())
