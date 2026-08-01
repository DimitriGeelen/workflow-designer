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
import importlib.util
import os
import re
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")

AEF_NS = "http://agentic-engineering.org/schema/1.0"

PAIRED = "PAIRED"
# PAIRED via the SAME rule id on both forms (T-322). Split out from PAIRED
# because this half is mechanically ENFORCEABLE: the guard requires the id to be
# emitted by both validator classes and fails if either side disappears.
# Discovered the hard way -- deleting the whole YAML rule left the plain PAIRED
# entry green, because XmlValidator still emitted the id and the stale-entry
# check only fires when NO validator emits it. A parity claim nothing enforces
# is the same false green this census exists to remove.
PAIRED_SAME_ID = "PAIRED (same id, both forms)"
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


def _aef_vocabulary():
    """The canonical aef: key vocabulary, IMPORTED from the bridge.

    Imported rather than hand-copied so the probe cannot drift from the code
    that decides what actually crosses between the two forms. Any key here is
    emitted into BPMN bytes by tools/yaml-to-bpmn.py, which is precisely what
    "the XML form can express this" means.
    """
    path = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")
    if not os.path.isfile(path):
        raise RuntimeError(
            "cannot resolve the aef vocabulary: %s is missing. Every "
            "expressibility probe below depends on it, and a probe that "
            "silently answered 'not expressible' would turn every gap into a "
            "clean out-of-scope classification." % path)
    spec = importlib.util.spec_from_file_location("_y2b_vocab", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    vocab = getattr(mod, "KNOWN_AEF_KEYS", None)
    if not vocab:
        raise RuntimeError(
            "tools/yaml-to-bpmn.py no longer exposes a non-empty "
            "KNOWN_AEF_KEYS -- renamed or restructured. An empty vocabulary "
            "makes every construct look inexpressible, which reads as "
            "'correctly out of scope' for every rule in the table.")
    return frozenset(vocab)


def _expressible_via_aef_meta(key):
    """Build a probe: can the OTHER form carry this aef: key?

    Returns a callable so the probe table stays uniform. The answer comes from
    the vocabulary, NOT from the corpus -- T-323. A key in the vocabulary rides
    through the bridge into <aef:meta key="..."/>, so the XML form can express
    it whether or not anyone has authored one yet.
    """
    def probe(_corpus):
        return [key] if key in _aef_vocabulary() else []
    return probe


# --------------------------------------------------------------------------
# the parity table
# --------------------------------------------------------------------------
# Each entry: rule id -> (classification, note).
# PAIRED       -- a counterpart rule exists on the other form; note names it.
# OUT_OF_SCOPE -- the other form CANNOT EXPRESS the construct. MUST have a probe
#                 in OUT_OF_SCOPE_PROBES; the guard re-measures it every run.
# GAP          -- the other form CAN express the construct and no rule describes
#                 it. Printed as a NOTE every run; the count is asserted below.
#
# HOW TO CLASSIFY A NEW RULE (T-323 — read this before adding an entry).
# The question is EXPRESSIBILITY, not corpus presence. "Can the other form carry
# this construct?" is answered by the schema / shared key vocabulary, NOT by
# grepping the corpus for a file that happens to carry one today.
#
# T-320 got this wrong and it cost the only OUT-OF-SCOPE call in the table. It
# classified aef:scopeOf out of scope on the strength of "0 of 96 authored bpmn",
# while scopeOf sits in the canonical vocabulary and the bridge emits it. Same
# map, both forms: self-referencing scopeOf is ERROR rc=2 on YAML and VALID rc=0
# on the BPMN bridged from those bytes. The census's own two-axis rule already
# said this — "a gap with zero violations is still a gap" — but it was applied to
# the GAP rows and not to these. The discipline was itself one-form-only.
#
# So: a corpus count is PRIORITY, never CLASSIFICATION. A corpus probe would flip
# a classification only AFTER someone authors a violating file, and knowing the
# rule is missing before that is the whole point of this table.
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

    # T-323: were OUT_OF_SCOPE on a corpus zero. scopeOf is in the canonical
    # vocabulary and the bridge emits it, so the XML form CAN carry it and has
    # no rule for it. 0 authored carriers is why this is low priority, not why
    # it would be out of scope.
    "E-SCOPEOF-SELF":       (GAP, "aef:scopeOf is expressible on the XML form "
                                  "(KNOWN_AEF_KEYS, bridge-emitted) and no XML "
                                  "rule describes it; 0 authored carriers"),
    "E-SCOPEOF-DANGLING":   (GAP, "aef:scopeOf expressible on the XML form; "
                                  "no XML rule (0 authored carriers)"),
    "W-SCOPEOF-TYPE":       (GAP, "aef:scopeOf expressible on the XML form; "
                                  "no XML rule (0 authored carriers)"),

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
    # Closed by T-322 -- both ids now emit from Validator AND XmlValidator off
    # the same module-scope AUTHORITY_OWNER / TYPE_PERFORMER tables, so the
    # both-forms assertion below proves these two rather than taking the note's
    # word for it.
    "W-TYPE-LANE-MISMATCH": (PAIRED_SAME_ID, "IW-9 O-1, both forms (T-322)"),
    "E-INCEPTION-NOT-SOVEREIGN": (PAIRED_SAME_ID, "IW-9 O-3, both forms (T-322)"),
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
# EXPRESSIBILITY probes, one per OUT_OF_SCOPE entry (T-323). Each answers "can
# the other form carry this construct?" from the vocabulary, never the corpus.
#
# Currently EMPTY, and that is the finding, not an oversight: after T-323 no rule
# in this table is out of scope. Every asymmetry left is a gap. The machinery
# stays because the classification must remain available and falsifiable — and
# because it is still exercised, by negative controls (b), (c) and (f), which
# synthesise entries. Without those this whole section would be dead code that
# passes by never running (the T-312 vacuity class).
OUT_OF_SCOPE_PROBES = {}

# Counted tolerance. Derived by hand from the census, re-derive it there rather
# than nudging this constant: constituents 3 + io 1 + abbr 1 + node-type 1
# + xml-id-dup 1 + geometry 1 + capacity 1 = 9, plus scopeOf 3 = 12.
# T-322 closed type-lane and inception (11 -> 9): the IW-9 authority rules now
# emit from both forms. T-323 reclassified the 3 scopeOf rules out-of-scope ->
# GAP (9 -> 12): they were classified on a corpus zero, and scopeOf is in the
# canonical vocabulary. The count went UP because the census got more honest,
# not because anything regressed.
EXPECTED_GAPS = 12


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

    # (1b) a rule emitted by BOTH classes is paired by construction (T-322).
    # Until now PAIRED was the one classification the guard took on trust: an
    # OUT_OF_SCOPE entry had to name a probe, a GAP entry was counted, and a
    # PAIRED entry was believed. This closes the half of that which is
    # mechanically decidable -- same id on both forms cannot be a gap. The other
    # half (PAIRED via a DIFFERENTLY-named counterpart, e.g. E-EDGE-DANGLING <->
    # E-FLOW-DANGLING) is still only a note, and is T-323's to make falsifiable.
    for rid in sorted(set(y) & set(x)):
        cls = PARITY.get(rid, (None, ""))[0]
        if cls is not None and cls not in (PAIRED, PAIRED_SAME_ID):
            failures.append(
                "rule '%s' is emitted by BOTH Validator and XmlValidator but is "
                "classified %s. A counterpart demonstrably exists on the other "
                "form; the classification is stale (a gap that was closed "
                "without updating the table still inflates EXPECTED_GAPS)."
                % (rid, cls))

    # (1c) ...and the converse, which is the half that actually bites: a
    # PAIRED_SAME_ID entry must still be emitted by BOTH forms. Deleting one
    # side reopens the gap in the CODE while the table goes on claiming parity,
    # and nothing else here notices -- the stale-entry check above only fires
    # when NO validator emits the id at all.
    for rid, (cls, _note) in sorted(PARITY.items()):
        if cls != PAIRED_SAME_ID:
            continue
        missing = [form for form, ids in (("YAML", y), ("XML", x))
                   if rid not in ids]
        if missing:
            failures.append(
                "rule '%s' is classified PAIRED-SAME-ID but is no longer emitted "
                "by the %s form. The parity it claims has been deleted from the "
                "code; reclassify it as a GAP (and raise EXPECTED_GAPS) or "
                "restore the rule." % (rid, " and ".join(missing)))

    # (2) re-measure every OUT_OF_SCOPE classification against the VOCABULARY
    # (T-323). The corpus is still gathered, but it is no longer what decides a
    # classification -- it is priority signal, and it keeps the summary line
    # honest about what was actually walked.
    corpus = _bpmn_corpus()
    if not corpus:
        raise RuntimeError(
            "found no authored .bpmn under %s -- an empty corpus means the "
            "priority figures below describe nothing, and a run that measured "
            "nothing must not report clean" % ROOT)
    for rid, (cls, _note) in sorted(PARITY.items()):
        if cls != OUT_OF_SCOPE:
            continue
        if rid not in OUT_OF_SCOPE_PROBES:
            failures.append(
                "rule '%s' is classified OUT-OF-SCOPE with no probe in "
                "OUT_OF_SCOPE_PROBES. Out-of-scope is a MEASUREMENT ('the other "
                "form CANNOT EXPRESS this construct'), not an opinion; without a "
                "probe it can never be falsified." % rid)
            continue
        construct, probe = OUT_OF_SCOPE_PROBES[rid]
        # A probe that cannot resolve its vocabulary RAISES rather than
        # answering "not expressible" -- the silent answer is the one that
        # would turn every gap in the table into a clean out-of-scope call.
        expressible = probe(corpus)
        if expressible:
            failures.append(
                "rule '%s' is classified OUT-OF-SCOPE, but the other form CAN "
                "express %s (%s). Out-of-scope means inexpressible, not "
                "unused: a construct the form can carry with no rule describing "
                "it is a GAP, however many files carry one today (T-323)."
                % (rid, construct, ", ".join(sorted(expressible)[:3])))

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

    # (b) an OUT_OF_SCOPE entry whose construct the other form CAN express must
    #     be caught (T-323 semantics: expressible, not merely present). This is
    #     the control that would have caught the scopeOf misclassification, and
    #     it could not have: the old version asked whether the CORPUS carried
    #     the construct, and the corpus carried none, so the classification was
    #     wrong and the control agreed with it.
    #     'scopeOf' is a real vocabulary key, so a probe built on it must go red.
    PARITY["Z-CONTROL-EXPRESSIBLE"] = (OUT_OF_SCOPE, "synthetic control")
    OUT_OF_SCOPE_PROBES["Z-CONTROL-EXPRESSIBLE"] = (
        "aef:scopeOf (a key the vocabulary really carries)",
        _expressible_via_aef_meta("scopeOf"),
    )
    probe_failures = []
    try:
        check(probe_failures, quiet=True)
    except RuntimeError:
        pass
    finally:
        del PARITY["Z-CONTROL-EXPRESSIBLE"]
        del OUT_OF_SCOPE_PROBES["Z-CONTROL-EXPRESSIBLE"]
    if not any("Z-CONTROL-EXPRESSIBLE" in f and "CAN express" in f
               for f in probe_failures):
        failures.append("negative control (b) FAILED: an out-of-scope "
                        "classification for a construct the other form can "
                        "express did not go red -- the re-measurement is inert")

    # (f) a probe that cannot RESOLVE its vocabulary must raise, not answer
    #     'not expressible'. The silent answer is the dangerous one: it turns
    #     every gap in the table into a clean out-of-scope call, and the guard
    #     would report OK while classifying nothing (T-312 vacuity class).
    saved_root = globals()["ROOT"]
    globals()["ROOT"] = os.path.join(saved_root, "no-such-tree-T-323")
    raised = False
    try:
        _aef_vocabulary()
    except RuntimeError:
        raised = True
    except Exception:
        pass
    finally:
        globals()["ROOT"] = saved_root
    if not raised:
        failures.append("negative control (f) FAILED: an unresolvable "
                        "vocabulary did not raise -- expressibility probes can "
                        "answer 'inexpressible' by accident, which reads as "
                        "'correctly out of scope' for every rule in the table")

    # (b2) a PAIRED_SAME_ID entry whose counterpart has been DELETED from one
    #      form must be caught (T-322). This control exists because the hole was
    #      real: before (1c), deleting the entire YAML half of the IW-9 rules
    #      left the guard green -- XmlValidator still emitted the ids, so the
    #      stale-entry check stayed quiet and the table went on claiming parity.
    #      Simulated by claiming PAIRED_SAME_ID for a rule only one form emits.
    saved_io = PARITY["W-IO-INPUT"]
    PARITY["W-IO-INPUT"] = (PAIRED_SAME_ID, "synthetic control: YAML-only rule")
    probe_failures = []
    try:
        check(probe_failures, quiet=True)
    except RuntimeError:
        pass
    finally:
        # restore the saved tuple, never a re-typed copy: a hand-written note
        # here would silently become the table's text if the real one changed
        PARITY["W-IO-INPUT"] = saved_io
    if not any("W-IO-INPUT" in f and "no longer emitted by the XML form" in f
               for f in probe_failures):
        failures.append("negative control (b2) FAILED: a PAIRED-SAME-ID claim "
                        "with no counterpart on the other form was accepted -- "
                        "the parity assertion is inert")

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

    # Say what each number is ABOUT, not just what it is (G-013): the old line
    # read "N authored bpmn re-measured", which sounded like the corpus decided
    # the classifications. It never does now -- the vocabulary does, and the
    # corpus is walked for priority only.
    print("rule-form parity: %d rules classified, %d gaps, %d out-of-scope "
          "re-measured against a %d-key vocabulary (%d authored bpmn walked "
          "for priority only)"
          % (len(emitted),
             sum(1 for c, _ in PARITY.values() if c == GAP),
             sum(1 for c, _ in PARITY.values() if c == OUT_OF_SCOPE),
             len(_aef_vocabulary()),
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
