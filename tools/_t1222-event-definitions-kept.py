#!/usr/bin/env python3
"""T-1222: every native BPMN event definition a third-party map carries survives a save, per kind.

Saves each third-party fixture through the REAL designer (tools/_t358-byteid-thirdparty.mjs --record into a temp
golden dir, so nothing in the repo is written), then counts `*EventDefinition` elements per kind in each fixture and
in its save. A kind that comes back fewer times than it went in is a loss. Also checks that every messageRef /
signalRef / errorRef / escalationRef a kept definition names resolves to an element with that id in the same save,
so preserving a definition can never leave the export pointing at an id it does not contain, and that every
kept definition sits inside an event element (reviewer amber 2026-10-20: never inside a flattened serviceTask).

Measured before the fix (2026-10-19): 47 definitions in, 3 out (link 2/2 since T-1217; message 1, from a process the
designer carries verbatim).
Exit 0 = nothing lost, every reference resolves; 1 = a loss or a dangling reference; 2 = could not measure.
"""
import os
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXDIR = os.path.join(ROOT, "tests", "fixtures", "third-party")
DEF = re.compile(r"<(?:[A-Za-z0-9]+:)?([a-z][A-Za-z]*)EventDefinition\b")
REF = re.compile(r"\b(messageRef|signalRef|errorRef|escalationRef)=\"([^\"]+)\"")


def counts(text):
    return Counter(DEF.findall(text))


def hosts_by_def_id(text):
    """{definition id: (host local name, host has attachedToRef)} for every *EventDefinition that carries an id."""
    try:
        tree = ET.fromstring(text.encode("utf-8"))
    except ET.ParseError:
        return {}
    out = {}
    for host in tree.iter():
        for el in host:
            if el.tag.rsplit("}", 1)[-1].endswith("EventDefinition") and el.get("id"):
                out[el.get("id")] = (host.tag.rsplit("}", 1)[-1], bool(host.get("attachedToRef")))
    return out


def main():
    with tempfile.TemporaryDirectory(prefix="t1222-") as out:
        env = dict(os.environ, T358_GOLDENDIR=out)
        p = subprocess.run(["node", os.path.join(ROOT, "tools", "_t358-byteid-thirdparty.mjs"), "--record"],
                           cwd=ROOT, env=env, capture_output=True, text=True, timeout=900)
        if p.returncode != 0:
            print("COULD NOT MEASURE: the save harness exited %d\n%s" % (p.returncode, (p.stdout + p.stderr)[-800:]))
            return 2
        lost, dangling, misplaced, total_in, total_out = [], [], [], Counter(), Counter()
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
            # Reviewer amber (2026-10-20): a definition must sit inside an EVENT element. Saving one inside the
            # serviceTask a boundary event was flattened into would be invalid BPMN with every count intact.
            try:
                tree = ET.fromstring(dst.encode("utf-8"))
            except ET.ParseError as e:
                misplaced.append("%s: the save is not well-formed XML (%s)" % (f, e))
                tree = None
            if tree is not None:
                parent = {c: p for p in tree.iter() for c in p}
                for el in tree.iter():
                    local = el.tag.rsplit("}", 1)[-1]
                    if local.endswith("EventDefinition"):
                        host = parent[el].tag.rsplit("}", 1)[-1] if el in parent else "(root)"
                        if not host.endswith("Event"):
                            misplaced.append("%s: <%s> inside <%s>" % (f, local, host))
                # Second amber (2026-10-20): each definition keeps its HOST TAG (matched by the definition's id: a typed
                # start or throw must not come back as a catch), and every boundary host keeps its attachedToRef.
                src_hosts = hosts_by_def_id(src)
                for did, (s_host, _) in src_hosts.items():
                    d = hosts_by_def_id(dst).get(did)
                    if d is None:
                        continue  # a loss, already counted above
                    d_host, d_attached = d
                    if d_host != s_host:
                        misplaced.append("%s: definition %s moved from <%s> to <%s>" % (f, did, s_host, d_host))
                    elif d_host == "boundaryEvent" and not d_attached:
                        misplaced.append("%s: boundary event of definition %s lost its attachedToRef" % (f, did))
            # A boundary event stays a boundary event with its attachment, with or without a definition (boundary-events
            # fixture: three definition-less boundaries were flattened, which a definition-only check cannot see).
            b_in = len(re.findall(r"<(?:[A-Za-z0-9]+:)?boundaryEvent\b[^>]*\battachedToRef=", src))
            b_out = len(re.findall(r"<(?:[A-Za-z0-9]+:)?boundaryEvent\b[^>]*\battachedToRef=", dst))
            if b_out < b_in:
                misplaced.append("%s: boundary events with attachedToRef %d -> %d" % (f, b_in, b_out))
            # Third amber (2026-10-20): an unedited open-and-save adds no <aef:eventDef>; the native definition carries
            # the type until a binding is set.
            added = len(re.findall(r"<aef:eventDef\b", dst)) - len(re.findall(r"<aef:eventDef\b", src))
            if added > 0:
                misplaced.append("%s: an unedited save added %d <aef:eventDef> element(s)" % (f, added))
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
        for line in misplaced:
            print("MISPLACED " + line)
        if lost or dangling or misplaced:
            print("FAIL: %d loss(es), %d dangling reference(s), %d misplaced definition(s)"
                  % (len(lost), len(dangling), len(misplaced)))
            return 1
        print("OK: every native event definition survives a save, and every reference resolves")
        return 0


if __name__ == "__main__":
    sys.exit(main())
