#!/usr/bin/env python3
"""T-335 — can a validator finding be POINTED AT? (T-309 IW-1a, made answerable)

T-309 asks where findings should surface in the designer: gutter markers on the
canvas, an on-demand panel, or a save-time gate. Two of those three require
every finding to name a thing that EXISTS ON THE CANVAS AT A POSITION, which is
a property of the emitter and the renderer rather than anyone's preference. The
spike measured it: 15 of 23 XmlValidator rules are gutter-able, and split by
severity a gutter would hide 60% of ERRORs against 9% of WARNs -- it would show
the author the advice and hide the errors.

THIS FILE EXISTS BECAUSE THE TABLE BELOW IS A DECLARATION. A hand-written
classification that nothing re-runs is the shape this codebase keeps finding:
KNOWN_DISAGREEMENTS before T-330, the parity NOTEs before T-331. Add a rule to
XmlValidator tomorrow and the table quietly stops describing the tree while the
report keeps quoting a number someone may act on. So:

  1. The POPULATION is read from source by ast -- every self.err/warn/info call
     site. A rule no document happens to trigger is still in the denominator.
  2. The table is TOTAL: an emitted rule id with no ANCHOR entry is a hard
     failure naming that id. Never a silent default (T-333's lesson -- an
     unclassified scope gets measured against the wrong population).
  3. Every declared class is CHECKED against what real documents resolve to.

Three document populations, and the third is the one that matters:

  - corpus BPMN (examples/*/rendered) -- clean by construction, 1 rule fires
  - BPMN fixtures on disk (tests/fixtures/**.bpmn)
  - **BRIDGED documents**: every YAML fixture through tools/yaml-to-bpmn.py,
    validated with run_xml. These exist only in memory and are produced on every
    gating run. The first pass of this measurement omitted them and therefore
    reported 11 rows unverified when the true figure was 1 -- a denominator
    scoped to "files that happened to be on disk". That is the same defect as
    E-XML-FLOW-DANGLING below, one level up, so it is wired in here rather than
    left to whoever runs it next.
"""
import ast
import collections
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")
BRIDGE = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")

NS = {
    "bpmn": "http://www.omg.org/spec/BPMN/20100524/MODEL",
    "aef": "http://anchorpoint.framework/aef/extensions",
}

# ---------------------------------------------------------------------------
# What each rule's `location` string NAMES, and therefore what the canvas would
# have to draw a marker on.
#
#   NODE       flow node id -> element carrying <aef:position>; a marker fits
#   LANE       lane id -> a band; a marker fits on its header
#   LANE-PAIR  names TWO lanes; which one carries the marker is undecided
#   DOC        no id interpolated -- nothing on the canvas to point at
#   REFERENT   names the id the rule asserts DOES NOT RESOLVE. The canvas can
#              only show the REFERRER, and the location never names it.
#   DROPPED    the id RESOLVES in the document and is STILL not on the canvas:
#              renderEdges (src/aef-workflow-designer.html:3501-3504) does
#              `if (!src || !tgt) continue;` and findNode (src:2499) matches on
#              uid, which a dangling targetRef never becomes. Resolving against
#              the DOCUMENT scores this gutter-able and is wrong -- the document
#              is not the canvas.
#   VALUE      a DUPLICATED id: resolves to >=2 elements, so "the" anchor does
#              not exist; for UID-DUP the value is an aef:uid, not a bpmn id,
#              so a second index would be needed to find the carriers at all.
# ---------------------------------------------------------------------------
ANCHOR = {
    "E-XML-STRUCTURE":           "DOC",
    "E-XML-ID-DUP":              "VALUE",
    "E-XML-UID-DUP":             "VALUE",
    "E-XML-NODE-TYPE":           "NODE",
    "E-XML-FLOW-DANGLING":       "DROPPED",
    "E-XML-LANES-EMPTY":         "DOC",
    "E-XML-LANEREF-DANGLING":    "REFERENT",
    "E-XML-GW-OUTGOING":         "NODE",
    "W-XML-GW-AMBIGUOUS":        "NODE",
    "W-XML-NODE-UNASSIGNED":     "NODE",
    "W-XML-PGW-CONDITION":       "NODE",
    "W-XML-PGW-NOOP":            "NODE",
    "W-XML-PGW-UNBALANCED":      "NODE",
    "W-XML-UNREACHABLE":         "NODE",
    "W-XML-DEADEND":             "NODE",
    "I-XML-LANE-GEOMETRY-SKIP":  "DOC",
    "W-XML-LANE-GEOMETRY":       "LANE-PAIR",
    "I-XML-LANE-CAPACITY-SKIP":  "LANE",
    "W-XML-LANE-CAPACITY":       "LANE",
    "E-XML-AUTHORITY":           "LANE",
    "E-INCEPTION-NOT-SOVEREIGN": "NODE",
    "W-TYPE-LANE-MISMATCH":      "NODE",
    "W-LANE-NO-OWNER":           "NODE",
}

GUTTERABLE = {"NODE", "LANE"}

# Rules no document in the tree witnesses. NOT a skip list -- the count is
# asserted, so a row cannot slip in or out unnoticed, and each entry states
# WHY it is unwitnessed. `E-XML-STRUCTURE` is UNREACHABLE rather than merely
# unwitnessed: no emitter here produces a document whose root is not
# <bpmn:definitions>, so it is the E-LOAD case from T-333 (a missing witness
# and an impossible one look identical until you ask which). Keeping the table
# non-empty is deliberate -- deleting it would retire the question along with
# its current answer.
NEVER_WITNESSED = {
    "E-XML-STRUCTURE": "unreachable: no emitter produces a non-<bpmn:definitions> root",
}
EXPECTED_NEVER_WITNESSED = 1

# What a resolved id may legitimately turn out to be, per declared class. A
# class whose observation set falls outside this is a table that stopped
# describing the tree.
ACCEPTS = {
    "NODE":      lambda seen: seen == {"node"},
    "LANE":      lambda seen: seen == {"lane"},
    "LANE-PAIR": lambda seen: seen == {"lane"},
    "REFERENT":  lambda seen: seen == {"UNRESOLVED"},
    "DROPPED":   lambda seen: seen == {"edge"},
    "DOC":       lambda seen: seen <= {"none", "document"},
    # NOTE, stated rather than hidden: this predicate proves the duplicated id
    # resolves to SOMETHING, not that it resolves TWICE, which is the property
    # that makes VALUE distinct from NODE. Read as partially verified. It is
    # written this way because the finding names the VALUE, and recovering the
    # carrier count would mean re-deriving the rule inside its own check.
    "VALUE":     lambda seen: seen <= {"node", "edge", "lane"},
}


# ---------------------------------------------------------------------------
# Population: the rules, read from source
# ---------------------------------------------------------------------------

def call_sites():
    """(scope, rule_id, location_expr, lineno, method) per emission site."""
    tree = ast.parse(open(VALIDATOR, encoding="utf-8").read())
    out = []

    class V(ast.NodeVisitor):
        def __init__(self):
            self.scope = "<module>"

        def visit_ClassDef(self, node):
            prev, self.scope = self.scope, node.name
            self.generic_visit(node)
            self.scope = prev

        def visit_Call(self, node):
            f = node.func
            if (isinstance(f, ast.Attribute) and f.attr in ("err", "warn", "info")
                    and isinstance(f.value, ast.Name) and f.value.id == "self"
                    and len(node.args) >= 2):
                rule = node.args[0]
                rule = rule.value if isinstance(rule, ast.Constant) else "<dynamic>"
                out.append((self.scope, rule, ast.unparse(node.args[1]),
                            node.lineno, f.attr))
            self.generic_visit(node)

    V().visit(tree)
    return out


# ---------------------------------------------------------------------------
# Population: the documents
# ---------------------------------------------------------------------------

def _index(root):
    """id -> kind, for everything the canvas can draw."""
    idx = {}
    for el in root.iter():
        eid = el.get("id")
        if not eid:
            continue
        tag = el.tag.split("}")[-1]
        if tag == "sequenceFlow":
            idx[eid] = "edge"
        elif tag == "lane":
            idx[eid] = "lane"
        elif tag in ("process", "collaboration", "participant", "laneSet",
                     "definitions"):
            idx[eid] = "document"
        else:
            idx[eid] = "node"
    for lane in root.iter("{%s}lane" % NS["bpmn"]):
        if lane.get("name"):
            idx.setdefault(lane.get("name"), "lane")
    return idx


def _ids_in(location):
    """The quoted ids a location string names. `location` is PROSE with ids
    interpolated into it -- "node 'wrk_2'", "lane '%s' -> lane '%s'" -- not a
    structured field, which is itself part of the IW-1a answer."""
    out, rest = [], location
    while "'" in rest:
        _, _, rest = rest.partition("'")
        val, sep, rest = rest.partition("'")
        if not sep:
            break
        out.append(val)
    return out


def bpmn_documents():
    """(label, xml_text) for every BPMN document this tree can produce."""
    docs = []
    for d in ("examples/aef-processes/rendered", "examples/app-processes/rendered"):
        p = os.path.join(ROOT, d)
        if os.path.isdir(p):
            for f in sorted(os.listdir(p)):
                if f.endswith(".bpmn"):
                    docs.append(("corpus:" + f,
                                 open(os.path.join(p, f), encoding="utf-8").read()))
    for dirpath, _, names in os.walk(os.path.join(ROOT, "tests", "fixtures")):
        for n in sorted(names):
            if n.endswith(".bpmn"):
                docs.append(("fixture:" + n,
                             open(os.path.join(dirpath, n), encoding="utf-8").read()))
    # The bridged form. Omitting these is what made the first pass of this
    # measurement under-report verification by a factor of two.
    bridged = 0
    for dirpath, _, names in os.walk(os.path.join(ROOT, "tests", "fixtures")):
        for n in sorted(names):
            if not n.endswith(".yaml"):
                continue
            p = os.path.join(dirpath, n)
            proc = subprocess.run([sys.executable, BRIDGE, p],
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if proc.returncode == 0:
                docs.append(("bridged:" + n,
                             proc.stdout.decode("utf-8", "replace")))
                bridged += 1
    return docs, bridged


def main():
    sites = call_sites()
    xml_sites = [s for s in sites if s[0] == "XmlValidator"]

    # -- 1. the table must be total ------------------------------------------
    emitted = {s[1] for s in xml_sites if s[1] != "<dynamic>"}
    unclassified = sorted(emitted - set(ANCHOR))
    if unclassified:
        print("FAIL: XmlValidator emits rule id(s) not classified in ANCHOR: %s"
              % ", ".join(unclassified))
        print("      An unclassified rule is measured against the wrong population "
              "and manufactures a false answer. Classify it.")
        return 1
    stale = sorted(set(ANCHOR) - emitted)
    if stale:
        print("FAIL: ANCHOR classifies rule id(s) XmlValidator no longer emits: %s"
              % ", ".join(stale))
        return 1

    sev_of = {}
    SEV = {"err": "ERROR", "warn": "WARN", "info": "INFO"}
    for _, rule, _, _, meth in xml_sites:
        sev_of[rule] = SEV[meth]

    # -- 2. observe --------------------------------------------------------
    sys.path.insert(0, os.path.join(ROOT, "tools"))
    import importlib.util
    spec = importlib.util.spec_from_file_location("_vw", VALIDATOR)
    vw = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(vw)

    docs, bridged = bpmn_documents()
    observed = collections.defaultdict(set)
    for label, text in docs:
        try:
            idx = _index(ET.fromstring(text))
        except ET.ParseError:
            idx = {}
        for f in vw.run_xml(text):
            if f.rule not in ANCHOR:
                continue
            ids = _ids_in(f.location)
            kinds = {idx.get(i, "UNRESOLVED") for i in ids} or {"none"}
            observed[f.rule] |= kinds

    # -- 3. declared vs observed -------------------------------------------
    disagree = []
    for rule, kinds in sorted(observed.items()):
        cls = ANCHOR[rule]
        if not ACCEPTS[cls](kinds):
            disagree.append((rule, cls, sorted(kinds)))
    if disagree:
        print("FAIL: the declared anchor class disagrees with what documents "
              "resolved to -- the table stopped describing the tree:")
        for rule, cls, kinds in disagree:
            print("      %-27s declared %-10s observed %s" % (rule, cls, kinds))
        return 1

    # -- 4. never-witnessed rows -------------------------------------------
    never = sorted(set(ANCHOR) - set(observed))
    if set(never) != set(NEVER_WITNESSED):
        print("FAIL: the never-witnessed set moved.")
        print("      declared: %s" % (sorted(NEVER_WITNESSED) or "(none)"))
        print("      observed: %s" % (never or "(none)"))
        print("      A row that gained a witness is a stale declaration; one that "
              "lost its only witness must resurface here, not slip into silence.")
        return 1
    if len(NEVER_WITNESSED) != EXPECTED_NEVER_WITNESSED:
        print("FAIL: the never-witnessed table and its count disagree "
              "(%d entries, expected %d)"
              % (len(NEVER_WITNESSED), EXPECTED_NEVER_WITNESSED))
        return 1

    # -- 5. report ----------------------------------------------------------
    by_cls = collections.Counter(ANCHOR.values())
    gut = sum(n for c, n in by_cls.items() if c in GUTTERABLE)
    print("finding anchorability: %d XmlValidator rules over %d BPMN documents "
          "(%d of them bridged from YAML fixtures at run time) -- "
          "%d gutter-able (%s), %d not (%s)."
          % (len(ANCHOR), len(docs), bridged, gut,
             ", ".join("%s %d" % (c, n) for c, n in sorted(by_cls.items())
                       if c in GUTTERABLE),
             len(ANCHOR) - gut,
             ", ".join("%s %d" % (c, n) for c, n in sorted(by_cls.items())
                       if c not in GUTTERABLE)))
    for sev in ("ERROR", "WARN", "INFO"):
        g = sum(1 for r, c in ANCHOR.items() if sev_of[r] == sev and c in GUTTERABLE)
        n = sum(1 for r, c in ANCHOR.items() if sev_of[r] == sev and c not in GUTTERABLE)
        if g + n:
            print("  %-5s %2d anchorable / %2d not -- a gutter would hide %d%%"
                  % (sev, g, n, round(100.0 * n / (g + n))))
    print("  %d of %d rows verified against real documents, 0 disagreements; "
          "%d never witnessed (%s)."
          % (len(observed), len(ANCHOR), len(never),
             "; ".join("%s: %s" % (r, NEVER_WITNESSED[r]) for r in never)))
    print("OK: every XmlValidator rule is classified, and every classification "
          "the documents can speak to agrees with them")
    return 0


if __name__ == "__main__":
    sys.exit(main())
