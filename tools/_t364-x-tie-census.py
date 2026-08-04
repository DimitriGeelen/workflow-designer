#!/usr/bin/env python3
"""_t364-x-tie-census.py — can two nodes in the same lane share an exact x?

WHY THIS EXISTS. `computeDisplayId` ranks nodes by x within a lane and breaks a tie
with `a.uid.localeCompare(b.uid)`. The source comment calls that "deterministic".
It is deterministic within a session and NOT across parses, because T-364 showed
`aef:uid` is minted randomly for any node that arrives without one. And `displayIdOf`
is the EMITTED BPMN element id — flowNodeRef, id=, sourceRef/targetRef, attachedToRef,
incoming/outgoing. So a tie between two uid-less nodes does not churn private
metadata; it permutes the document's identity graph.

The determinism probe found ZERO non-uid drift over six documents. This census asks
whether that is a property of the defect or a property of the population, by
measuring the two ingredients separately:

  TIE      two nodes in one lane at the same x
  UIDLESS  neither node carries aef:uid on arrival (so both are minted per parse)

Only their CONJUNCTION permutes emitted ids. Reported separately and never summed,
because a corpus with many ties and no uid-less nodes is safe today and one file
away from unsafe.

Three populations, deliberately distinguished:

  corpus      designer-produced maps  — carry aef:position AND aef:uid
  fixtures    third-party documents   — carry neither; the importer's fallback
              layout assigns x = base + n*90 per lane, strictly increasing, so a
              tie is UNREACHABLE for them. Their clean result is a capability
              zero, not evidence of safety.
  di          the SAME third-party documents read through their BPMN DI, which is
              what T-357 proposes to adopt as the designer geometry. This is the
              population that does not exist yet. It is the forecast.

Usage: python3 tools/_t364-x-tie-census.py
Exit 0 = census ran. It is a measurement, not a gate; it does not fail on findings.
"""
import os
import sys
import glob
import xml.etree.ElementTree as ET
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

BPMN = "http://www.omg.org/spec/BPMN/20100524/MODEL"
BPMNDI = "http://www.omg.org/spec/BPMN/20100524/DI"
DC = "http://www.omg.org/spec/DD/20100524/DC"
AEF_HINTS = ("aef", "http://agentic-engineering-framework/schema")


def aef_children(el, local):
    """Children in ANY aef-ish namespace with the given local name.

    The extensionElements namespace is an open seam with AEF (their 414/417), so
    matching on the local name and a loose namespace test is deliberate: a probe
    that silently matched nothing because the URI moved would report a confident
    zero, which is the failure this whole task is about.
    """
    out = []
    for c in el.iter():
        tag = c.tag
        if "}" in tag:
            uri, name = tag[1:].split("}", 1)
        else:
            uri, name = "", tag
        if name == local and any(h in uri.lower() for h in AEF_HINTS):
            out.append(c)
    return out


def lane_membership(proc):
    """displayId -> laneId, read from flowNodeRef. Nodes in no lane share a bucket."""
    m = {}
    for lane in proc.iter(f"{{{BPMN}}}lane"):
        lid = lane.get("id")
        for ref in lane.iter(f"{{{BPMN}}}flowNodeRef"):
            if ref.text and ref.text.strip():
                m[ref.text.strip()] = lid
    return m


FLOW_TAGS = {
    "task", "userTask", "serviceTask", "scriptTask", "manualTask", "sendTask",
    "receiveTask", "businessRuleTask", "callActivity", "subProcess",
    "startEvent", "endEvent", "intermediateCatchEvent", "intermediateThrowEvent",
    "boundaryEvent", "exclusiveGateway", "parallelGateway", "inclusiveGateway",
    "eventBasedGateway", "complexGateway",
}


def di_bounds(root):
    """bpmnElement -> x, from BPMNShape/Bounds."""
    out = {}
    for shape in root.iter(f"{{{BPMNDI}}}BPMNShape"):
        ref = shape.get("bpmnElement")
        b = shape.find(f"{{{DC}}}Bounds")
        if ref and b is not None and b.get("x") is not None:
            try:
                out[ref] = float(b.get("x"))
            except ValueError:
                pass
    return out


def scan(path):
    """Return (rows, parsed_ok). rows: (elem_id, laneId, aef_x, di_x, has_uid)."""
    try:
        root = ET.parse(path).getroot()
    except Exception as e:
        return None, f"unparseable: {e}"
    procs = list(root.iter(f"{{{BPMN}}}process"))
    if not procs:
        return None, "no bpmn:process"
    di = di_bounds(root)
    rows = []
    for proc in procs:
        lanes = lane_membership(proc)
        for el in proc.iter():
            tag = el.tag
            if not tag.startswith(f"{{{BPMN}}}"):
                continue
            local = tag.split("}", 1)[1]
            if local not in FLOW_TAGS:
                continue
            eid = el.get("id")
            if not eid:
                continue
            pos = aef_children(el, "position")
            ax = None
            if pos and pos[0].get("x") is not None:
                try:
                    ax = float(pos[0].get("x"))
                except ValueError:
                    ax = None
            has_uid = bool(aef_children(el, "uid"))
            rows.append((eid, lanes.get(eid), ax, di.get(eid), has_uid))
    return rows, None


def ties(rows, which):
    """Group by (lane, x) for the chosen coordinate; return colliding groups."""
    buckets = defaultdict(list)
    for eid, lane, ax, dx, has_uid in rows:
        x = ax if which == "aef" else dx
        if x is None:
            continue
        buckets[(lane, x)].append((eid, has_uid))
    return {k: v for k, v in buckets.items() if len(v) > 1}


def report(title, files, which, note):
    print(f"\n{title}")
    print(f"  coordinate: {which}   files: {len(files)}")
    tot_nodes = tot_placed = tot_uid = 0
    tie_files = []
    danger_files = []
    unparsed = []
    for p in files:
        rows, err = scan(p)
        if rows is None:
            unparsed.append((os.path.basename(p), err))
            continue
        tot_nodes += len(rows)
        tot_uid += sum(1 for r in rows if r[4])
        placed = [r for r in rows if (r[2] if which == "aef" else r[3]) is not None]
        tot_placed += len(placed)
        t = ties(rows, which)
        if t:
            # A tie only permutes ids if BOTH tied nodes are uid-less on arrival.
            hot = {k: v for k, v in t.items() if sum(1 for _, u in v if not u) > 1}
            tie_files.append((os.path.basename(p), len(t), sum(len(v) for v in t.values())))
            if hot:
                danger_files.append((os.path.basename(p), hot))
    print(f"  nodes: {tot_nodes}   with a {which} coordinate: {tot_placed}")
    print(f"  uid coverage: {tot_uid}/{tot_nodes} carry aef:uid"
          f"{'' if tot_uid == tot_nodes else f'   *** {tot_nodes - tot_uid} WITHOUT'}")
    if tot_placed == 0:
        print(f"  *** NO NODE CARRIES A {which.upper()} COORDINATE — a tie is UNREACHABLE here.")
        print("      This zero is a capability bound, not a safety result.")
    if unparsed:
        print(f"  unparsed: {len(unparsed)}")
        for n, e in unparsed[:3]:
            print(f"      {n}: {e}")
    if tie_files:
        print(f"  files with >=1 same-lane x collision: {len(tie_files)}")
        for n, g, m in tie_files[:8]:
            print(f"      {n}: {g} collision group(s), {m} node(s)")
        if len(tie_files) > 8:
            print(f"      ... and {len(tie_files) - 8} more")
    else:
        print("  same-lane x collisions: 0")
    if danger_files:
        print(f"  *** {len(danger_files)} file(s) where a collision group has >1 UID-LESS node")
        print("      -> emitted element ids can permute between two parses of the same bytes")
        for n, hot in danger_files[:5]:
            (lane, x), members = next(iter(hot.items()))
            print(f"      {n}: lane={lane} x={x} -> {[m for m, u in members if not u][:4]}")
    else:
        print("  collision groups with >1 uid-less node: 0")
    print(f"  note: {note}")
    return len(tie_files), len(danger_files), tot_placed


corpus = sorted(glob.glob(os.path.join(ROOT, "examples", "aef-processes", "rendered", "*.bpmn")))
fixtures = sorted(glob.glob(os.path.join(ROOT, "tests", "fixtures", "third-party", "*.bpmn")))


def population_crosscheck(selected):
    """Compute the .bpmn population a second, independent way and diff the counts.

    Adopted from AEF at RAIL-432, who hit this the hard way: their uid census used
    glob('**/*.bpmn', recursive=True), which SKIPS DOT-DIRECTORIES, and their entire
    live corpus lives under .context/designer/projects/. It read 19 files, reported
    18 exposed nodes, and looked like a finished measurement — plausible number,
    per-file rows, a total. It disagreed with `find` by 32 files and nothing in the
    output said so. Their framing: not a predicate that classified wrongly, a
    DENOMINATOR that never contained the subject.

    This census scopes to two named populations on purpose, so a gap here is not a
    bug. But "deliberately scoped" and "accidentally truncated" produce identical
    output unless the unexamined space is printed next to the examined one.
    """
    seen = set()
    for dirpath, dirnames, filenames in os.walk(ROOT):
        if ".git" in dirpath.split(os.sep):
            continue
        for f in filenames:
            if f.endswith(".bpmn"):
                seen.add(os.path.join(dirpath, f))
    sel = {os.path.abspath(p) for p in selected}
    rest = sorted(seen - sel)
    buckets = {}
    for p in rest:
        d = os.path.relpath(os.path.dirname(p), ROOT)
        buckets[d] = buckets.get(d, 0) + 1
    print("\nPOPULATION CROSS-CHECK (two independent walks, per AEF RAIL-432)")
    print(f"  .bpmn in tree (os.walk, .git excluded): {len(seen)}")
    print(f"  examined by this census                : {len(sel)}")
    print(f"  NOT examined                           : {len(rest)}")
    if rest:
        print("  The unexamined space, by directory — this census says nothing about these:")
        for d, n in sorted(buckets.items(), key=lambda kv: -kv[1])[:8]:
            dot = "  <- dot-directory (the shape that bit AEF)" if any(
                s.startswith(".") for s in d.split(os.sep)) else ""
            print(f"      {n:4d}  {d}{dot}")
        if len(buckets) > 8:
            print(f"      ... and {len(buckets) - 8} more directories")
    print("  Reading: the three populations above are chosen and named, not everything")
    print("  present. tests/fixtures/aef-bpmn in particular is peer-authored material this")
    print("  census has never measured for ties or uid coverage.")

print("=" * 78)
print("T-364 — can a same-lane x tie permute emitted element ids?")
print("=" * 78)
print("""
computeDisplayId sorts by (x, uid) and displayIdOf IS the emitted BPMN id. A tie
between two nodes whose uids are minted fresh each parse therefore permutes
ids, sourceRef/targetRef, flowNodeRef and attachedToRef — not just aef:uid.
Two ingredients, measured separately; only together do they bite.""")

c_t, c_d, c_p = report(
    "POPULATION 1 — designer corpus (examples/aef-processes/rendered)",
    corpus, "aef",
    "these carry aef:uid, so even a tie resolves the same way every parse")

f_t, f_d, f_p = report(
    "POPULATION 2 — third-party fixtures, AS IMPORTED TODAY",
    fixtures, "aef",
    "no aef:position: the importer lays out x = base + n*90 per lane, strictly "
    "increasing,\n        so a tie cannot occur — this population's clean result is unreachability")

d_t, d_d, d_p = report(
    "POPULATION 3 — the same third-party fixtures, read through their BPMN DI",
    fixtures, "di",
    "T-357 proposes adopting DI as the designer geometry. These x values are what\n"
    "        those nodes WOULD have. They still arrive without aef:uid.")

print("\n" + "=" * 78)
print("READING")
print("=" * 78)
if c_p and not c_d:
    print("  Corpus: safe, and safe for a REASON — aef:uid is in the bytes, so the")
    print("          tie-break is stable across parses whether or not ties exist.")
if f_p == 0:
    print("  Fixtures today: a tie is structurally unreachable. Reporting this as")
    print("          '0 collisions' would be the capability-zero mistake T-364 exists for.")
if d_d:
    print(f"  DI forecast: {d_d} file(s) ALREADY hold a collision group of uid-less nodes.")
    print("          Adopting DI as geometry (T-357) converts a latent hazard into a live")
    print("          one, because it supplies the missing ingredient — real, colliding x —")
    print("          to documents that still have no stable identity in their bytes.")
    print("          T-364's repair is therefore a PREREQUISITE of T-357, not parallel to it.")
elif d_t:
    print(f"  DI forecast: {d_t} file(s) have same-lane x collisions but no collision group")
    print("          has two uid-less nodes in it. The hazard needs both; today it has one.")
else:
    print("  DI forecast: no same-lane x collisions in DI coordinates on this sample.")
    print("          That bounds THIS sample; DI x is authored by the exporting tool and")
    print("          nothing prevents a collision in general.")
# POPULATION 4 — closing the debt this census recorded in its own cross-check. These are
# peer-authored maps living in our tree, and AEF reported at RAIL-432 that their live
# corpus is 424/424 uid-covered. Whether OUR copies are is a different question with the
# same stakes: a uid-less node here is one their _find_uid would forge a duplicate task
# for on re-parse, and if it also ties on x it permutes emitted element ids as well.
aef_authored = sorted(glob.glob(os.path.join(ROOT, "tests", "fixtures", "aef-bpmn", "*.bpmn")))
a_t, a_d, a_p = report(
    "POPULATION 4 — peer-authored maps in our tree (tests/fixtures/aef-bpmn)",
    aef_authored, "aef",
    "AEF reports their live corpus is 424/424 uid-covered; this measures OUR copies.\n"
    "        Both ingredients are read here, because only their conjunction permutes ids.")

population_crosscheck(corpus + fixtures + aef_authored)
print()
sys.exit(0)
