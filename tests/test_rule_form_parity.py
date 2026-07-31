#!/usr/bin/env python3
"""T-320 — rule-form parity guard.

`tools/validate-workflow.py` carries two validators: `Validator` (canonical YAML
form) and `XmlValidator` (BPMN form). A rule present on one form and absent on
the other means files on the unguarded form can sit in `fixtures/valid/`
asserting a cleanliness nothing ever evaluated. T-317 found that the expensive
way. This guard keeps the class from growing silently.

Three properties, in descending order of how easy they are to get wrong:

1. Every rule id emitted by either validator carries a parity CLASSIFICATION.
   Ids are extracted from the emit sites, never hand-listed, so the table cannot
   drift away from the code. A new rule with no decision fails, naming itself.

2. OUT_OF_SCOPE classifications are RE-MEASURED every run. "The other form does
   not carry this construct" was a measurement on a particular day; the day a
   file starts carrying it, the classification is false and this must go red.
   A classification that was true when written and is false now is exactly the
   shape that makes a stale census worse than no census.

3. GAP entries print a NOTE every run and their count is asserted -- a counted
   tolerance, living somewhere that still executes. T-317's tolerance counter had
   been written into a COMPLETED task's Verification block, which never runs
   again; the half that made it a tolerance rather than a suppression list had
   quietly stopped being enforced while the tolerance kept presenting as counted.

Unevaluable is RED throughout: if a validator class cannot be located, or yields
no rules, or the corpus is empty, this raises rather than passing quiet (the
T-312 vacuity class -- "could not evaluate" and "evaluated clean" must be
different outputs).

Census and evidence: docs/reports/T-320-rule-form-parity-census.md
"""
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")

AEF_NS = "http://agentic-engineering.org/schema/1.0"

PAIRED = "PAIRED"
OUT_OF_SCOPE = "OUT-OF-SCOPE"
GAP = "GAP"


# --------------------------------------------------------------------------
# construct probes -- used to RE-MEASURE out-of-scope classifications
# --------------------------------------------------------------------------
def _bpmn_corpus():
    """Authored BPMN. .editor-versions/ is version churn, not authored content."""
    out = []
    for p in glob.glob(os.path.join(ROOT, "**", "*.bpmn"), recursive=True):
        if any(seg in p for seg in ("/.editor-versions/", "/node_modules/",
                                    "/.git/", "/.agentic-framework")):
            continue
        out.append(p)
    return sorted(out)


def _probe_scope_of(paths):
    """Files carrying aef:scopeOf, as attribute or element."""
    hits = []
    for p in paths:
        try:
            root = ET.parse(p).getroot()
        except Exception:
            continue
        for el in root.iter():
            if "scopeOf" in el.attrib or el.tag.endswith("}scopeOf"):
                hits.append(os.path.relpath(p, ROOT))
                break
    return hits


# --------------------------------------------------------------------------
# the parity table
# --------------------------------------------------------------------------
# Each entry: rule id -> (classification, note).
# PAIRED       -- a counterpart rule exists on the other form; note names it.
# OUT_OF_SCOPE -- the other form does not carry the construct. MUST have a probe
#                 in OUT_OF_SCOPE_PROBES; the guard re-measures it every run.
# GAP          -- the other form DOES carry the construct and no rule describes
#                 it. Printed as a NOTE every run; the count is asserted below.
PARITY = {
    # ---- YAML form -------------------------------------------------------
    "E-NOT-MAPPING":        (PAIRED, "E-XML-STRUCTURE"),
    "E-TOPLEVEL-MISSING":   (PAIRED, "E-XML-STRUCTURE"),
    "E-LANE-FIELD":         (PAIRED, "E-XML-STRUCTURE"),
    "E-LANES-EMPTY":        (PAIRED, "E-XML-STRUCTURE"),
    "E-NODE-FIELD":         (PAIRED, "E-XML-STRUCTURE"),
    "E-EDGE-FIELD":         (PAIRED, "E-XML-STRUCTURE"),
    "E-NODE-LANE":          (PAIRED, "E-XML-LANEREF-DANGLING"),
    "E-EDGE-DANGLING":      (PAIRED, "E-XML-FLOW-DANGLING"),
    "E-GW-OUTGOING":        (PAIRED, "E-XML-GW-OUTGOING"),
    "E-UID-DUP":            (PAIRED, "E-XML-UID-DUP"),
    "E-AUTHORITY":          (PAIRED, "E-INCEPTION-NOT-SOVEREIGN / laneMeta authority"),
    "W-DEADEND":            (PAIRED, "W-XML-DEADEND"),
    "W-UNREACHABLE":        (PAIRED, "W-XML-UNREACHABLE"),
    "W-GW-AMBIGUOUS":       (PAIRED, "W-XML-GW-AMBIGUOUS (T-317)"),
    "W-PGW-CONDITION":      (PAIRED, "W-XML-PGW-CONDITION"),
    "W-PGW-NOOP":           (PAIRED, "W-XML-PGW-NOOP"),
    "W-PGW-UNBALANCED":     (PAIRED, "W-XML-PGW-UNBALANCED"),

    "E-SCOPEOF-SELF":       (OUT_OF_SCOPE, "aef:scopeOf: 0 of N authored bpmn"),
    "E-SCOPEOF-DANGLING":   (OUT_OF_SCOPE, "aef:scopeOf: 0 of N authored bpmn"),
    "W-SCOPEOF-TYPE":       (OUT_OF_SCOPE, "aef:scopeOf: 0 of N authored bpmn"),

    "E-CONST-DUP":          (GAP, "aef:constituents carried by 23/96 bpmn; no XML rule"),
    "E-CONST-SHAPE":        (GAP, "aef:constituents carried by 23/96 bpmn; no XML rule"),
    "W-CONST-FIELD":        (GAP, "aef:constituents carried by 23/96 bpmn; no XML rule"),
    "W-IO-INPUT":           (GAP, "declared io carried by 17/96 bpmn; no XML rule"),
    "E-ABBR-DUP":           (GAP, "lane abbr carried by 96/96 bpmn; no XML rule (0 live)"),
    "E-NODE-TYPE":          (GAP, "XML form has NO node-type vocabulary gate: a "
                                  "<bpmn:serviceTaks> typo validates clean, rc=0. "
                                  "Fix is NOT a copy of NODE_TYPES -- the XML "
                                  "vocabulary is a superset (catch/throw/boundary "
                                  "events, 19 occurrences in 8 fixtures)"),

    # ---- XML form --------------------------------------------------------
    "E-XML-STRUCTURE":      (PAIRED, "E-NOT-MAPPING / E-TOPLEVEL-MISSING / *-FIELD"),
    "E-XML-LANEREF-DANGLING": (PAIRED, "E-NODE-LANE"),
    "E-XML-FLOW-DANGLING":  (PAIRED, "E-EDGE-DANGLING"),
    "E-XML-GW-OUTGOING":    (PAIRED, "E-GW-OUTGOING"),
    "E-XML-UID-DUP":        (PAIRED, "E-UID-DUP"),
    "W-XML-DEADEND":        (PAIRED, "W-DEADEND"),
    "W-XML-UNREACHABLE":    (PAIRED, "W-UNREACHABLE"),
    "W-XML-GW-AMBIGUOUS":   (PAIRED, "W-GW-AMBIGUOUS"),
    "W-XML-PGW-CONDITION":  (PAIRED, "W-PGW-CONDITION"),
    "W-XML-PGW-NOOP":       (PAIRED, "W-PGW-NOOP"),
    "W-XML-PGW-UNBALANCED": (PAIRED, "W-PGW-UNBALANCED"),
    "W-XML-NODE-UNASSIGNED": (PAIRED, "E-NODE-LANE (lane membership is required "
                                      "by REQUIRED_NODE_FIELDS on the YAML form)"),

    "E-XML-ID-DUP":         (GAP, "YAML lane/node ids are not checked for "
                                  "collision beyond uid; no YAML rule"),
    "W-TYPE-LANE-MISMATCH": (GAP, "authority+task-type carried by 24/24 yaml "
                                  "maps; no YAML rule (0 live) -- IW-9 governance"),
    "E-INCEPTION-NOT-SOVEREIGN": (GAP, "workflowType=inception carried by 2/24 "
                                       "yaml maps; no YAML rule (0 live) -- IW-9 "
                                       "governance, the sovereignty boundary"),
    "W-XML-LANE-GEOMETRY":  (GAP, "node y carried by 24/24 yaml maps; no YAML "
                                  "rule (0 live). NOT out of scope -- see the "
                                  "correction in the T-320 census: '0 violations "
                                  "today' was collapsed into 'out of scope'"),
    "W-XML-LANE-CAPACITY":  (GAP, "lane height + y carried by 24/24 yaml maps; "
                                  "no YAML rule (0 live)"),
    "I-XML-LANE-GEOMETRY-SKIP": (PAIRED, "skip-note for W-XML-LANE-GEOMETRY; "
                                         "shares its classification"),
    "I-XML-LANE-CAPACITY-SKIP": (PAIRED, "skip-note for W-XML-LANE-CAPACITY; "
                                         "shares its classification"),
}

# Every OUT_OF_SCOPE rule must name a probe here. The guard re-measures it.
# No probe -> the classification is unfalsifiable -> hard error.
OUT_OF_SCOPE_PROBES = {
    "E-SCOPEOF-SELF":     ("aef:scopeOf", _probe_scope_of),
    "E-SCOPEOF-DANGLING": ("aef:scopeOf", _probe_scope_of),
    "W-SCOPEOF-TYPE":     ("aef:scopeOf", _probe_scope_of),
}

# Counted tolerance. Derived by hand from the census, re-derive it there rather
# than nudging this constant: constituents 3 + io 1 + abbr 1 + node-type 1
# + xml-id-dup 1 + type-lane 1 + inception 1 + geometry 1 + capacity 1 = 11.
EXPECTED_GAPS = 11


# --------------------------------------------------------------------------
# rule extraction -- from the emit sites, never hand-listed
# --------------------------------------------------------------------------
EMIT = re.compile(r'self\.(err|warn|info)\(\s*\n?\s*"([A-Z0-9\-]+)"')


def extract_rules():
    """-> (yaml_rules, xml_rules) as {rule_id: severity}. Raises if unevaluable."""
    if not os.path.isfile(VALIDATOR):
        raise RuntimeError(
            "validator not found at %s -- renamed or moved; this guard cannot "
            "evaluate and must not pass" % VALIDATOR)
    src = open(VALIDATOR, encoding="utf-8").read()
    try:
        i = src.index("class Validator:")
        j = src.index("class XmlValidator:")
    except ValueError as exc:
        raise RuntimeError(
            "could not locate both validator classes in %s (%s) -- a rename "
            "makes every rule below invisible, which would read as full parity. "
            "Unevaluable, not clean." % (VALIDATOR, exc))
    if j <= i:
        raise RuntimeError("XmlValidator precedes Validator -- the split above "
                           "would attribute rules to the wrong form")

    def rules(text):
        found = {}
        for sev, rid in EMIT.findall(text):
            found.setdefault(rid, sev)
        return found

    y, x = rules(src[i:j]), rules(src[j:])
    if not y or not x:
        raise RuntimeError(
            "extracted %d YAML and %d XML rules -- zero on either form means the "
            "emit pattern stopped matching, and an empty rule set trivially "
            "satisfies every assertion below" % (len(y), len(x)))
    return y, x


# --------------------------------------------------------------------------
def check(failures, quiet=False):
    y, x = extract_rules()
    emitted = dict(y)
    emitted.update(x)

    # (1) every emitted rule carries a classification
    unclassified = sorted(set(emitted) - set(PARITY))
    for rid in unclassified:
        failures.append(
            "rule '%s' is emitted by the validator but has no parity "
            "classification in PARITY. Adding a rule to one form without "
            "deciding whether the other form needs it is exactly the T-317 "
            "class. Classify it as PAIRED / OUT_OF_SCOPE / GAP." % rid)

    # a classification for a rule that no longer exists is dead weight, and
    # worse, it pads the GAP count that the tolerance below asserts
    stale = sorted(set(PARITY) - set(emitted))
    for rid in stale:
        failures.append(
            "PARITY classifies '%s' but no validator emits it -- rule removed "
            "or renamed; drop the entry (it currently inflates the gap count)"
            % rid)

    # (2) re-measure every OUT_OF_SCOPE classification
    corpus = _bpmn_corpus()
    if not corpus:
        raise RuntimeError(
            "found no authored .bpmn under %s -- the out-of-scope probes below "
            "would all return 'absent' against an empty corpus and pass "
            "vacuously" % ROOT)
    for rid, (cls, _note) in sorted(PARITY.items()):
        if cls != OUT_OF_SCOPE:
            continue
        if rid not in OUT_OF_SCOPE_PROBES:
            failures.append(
                "rule '%s' is classified OUT-OF-SCOPE with no probe in "
                "OUT_OF_SCOPE_PROBES. Out-of-scope is a MEASUREMENT ('the other "
                "form does not carry this construct'), not an opinion; without a "
                "probe it can never be falsified." % rid)
            continue
        construct, probe = OUT_OF_SCOPE_PROBES[rid]
        carriers = probe(corpus)
        if carriers:
            failures.append(
                "rule '%s' is classified OUT-OF-SCOPE because no file on the "
                "other form carries %s -- but %d now do (%s). The "
                "classification was true when written and is false now; it is "
                "a GAP." % (rid, construct, len(carriers),
                            ", ".join(sorted(carriers)[:3])))

    # (3) counted tolerance: print every gap, then assert the count
    gaps = sorted(rid for rid, (cls, _n) in PARITY.items() if cls == GAP)
    if not quiet:
        for rid in gaps:
            print("NOTE (known parity gap, T-320): %s -- %s"
                  % (rid, PARITY[rid][1]))
    if len(gaps) != EXPECTED_GAPS:
        failures.append(
            "parity-gap count is %d, expected %d -- a gap was opened or closed. "
            "Re-derive the arithmetic in docs/reports/"
            "T-320-rule-form-parity-census.md; do not adjust the constant to "
            "match." % (len(gaps), EXPECTED_GAPS))

    return emitted, corpus


# --------------------------------------------------------------------------
def negative_controls(failures):
    """Prove the assertions above can actually fail. Each control mutates the
    table or the input and asserts the guard notices -- reading the code is not
    evidence that it discriminates (PL-061)."""

    # (a) an unclassified rule must be caught
    saved = PARITY.pop("W-DEADEND")
    probe_failures = []
    try:
        check(probe_failures, quiet=True)
    except RuntimeError:
        pass
    finally:
        PARITY["W-DEADEND"] = saved
    if not any("W-DEADEND" in f and "no parity classification" in f
               for f in probe_failures):
        failures.append("negative control (a) FAILED: removing a rule's "
                        "classification did not fail the guard")

    # (b) an OUT_OF_SCOPE entry whose construct HAS appeared must be caught.
    #     Simulated by pointing the probe at a construct the corpus does carry.
    saved_probe = OUT_OF_SCOPE_PROBES["W-SCOPEOF-TYPE"]
    OUT_OF_SCOPE_PROBES["W-SCOPEOF-TYPE"] = (
        "lane abbr (stand-in: a construct the corpus DOES carry)",
        lambda paths: [os.path.relpath(p, ROOT) for p in paths
                       if b"abbr" in open(p, "rb").read()],
    )
    probe_failures = []
    try:
        check(probe_failures, quiet=True)
    except RuntimeError:
        pass
    finally:
        OUT_OF_SCOPE_PROBES["W-SCOPEOF-TYPE"] = saved_probe
    if not any("W-SCOPEOF-TYPE" in f and "is false now" in f
               for f in probe_failures):
        failures.append("negative control (b) FAILED: an out-of-scope "
                        "classification whose construct has appeared in the "
                        "corpus did not go red -- the re-measurement is inert")

    # (c) an OUT_OF_SCOPE entry with no probe must be caught
    PARITY["Z-CONTROL-NOPROBE"] = (OUT_OF_SCOPE, "synthetic control")
    probe_failures = []
    try:
        check(probe_failures, quiet=True)
    except RuntimeError:
        pass
    finally:
        del PARITY["Z-CONTROL-NOPROBE"]
    if not any("Z-CONTROL-NOPROBE" in f and "no probe" in f
               for f in probe_failures):
        failures.append("negative control (c) FAILED: an unfalsifiable "
                        "out-of-scope classification was accepted")

    # (d) unevaluable must be RED, not quiet. Point the extractor at a file
    #     with no validator classes at all.
    global VALIDATOR
    saved_path = VALIDATOR
    VALIDATOR = os.path.abspath(__file__)   # a real file, wrong content
    raised = False
    try:
        extract_rules()
    except RuntimeError:
        raised = True
    finally:
        VALIDATOR = saved_path
    if not raised:
        failures.append("negative control (d) FAILED: a validator with no "
                        "locatable rule classes did not raise -- zero rules "
                        "would satisfy every parity assertion trivially")

    # (e) a missing validator file must be RED
    VALIDATOR = os.path.join(ROOT, "tools", "no-such-validator.py")
    raised = False
    try:
        extract_rules()
    except RuntimeError:
        raised = True
    finally:
        VALIDATOR = saved_path
    if not raised:
        failures.append("negative control (e) FAILED: a missing validator did "
                        "not raise")


def main():
    failures = []
    negative_controls(failures)
    emitted, corpus = check(failures)

    print("rule-form parity: %d rules classified, %d gaps, %d authored bpmn "
          "re-measured" % (len(emitted),
                           sum(1 for c, _ in PARITY.values() if c == GAP),
                           len(corpus)))
    if failures:
        print()
        for f in failures:
            print("FAIL: %s" % f)
        print("\nrule-form parity: %d failure(s)" % len(failures))
        return 1
    print("rule-form parity: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
