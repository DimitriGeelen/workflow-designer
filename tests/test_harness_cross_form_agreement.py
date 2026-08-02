#!/usr/bin/env python3
"""T-328 — do PAIRED validator rules AGREE, or do both forms merely NAME them?

`tests/test_rule_form_parity.py` classifies a rule PAIRED when both validator
classes emit the same-or-counterpart rule id. It establishes that by regex over
each class's source span (`extract_rules`, :255) and **never validates a
document**. So two predicates reading the same carrier by different tests stay
green forever. Teeth prove a guard FIRES; parity proves a rule EXISTS; neither
proves it is RIGHT (PL-070, PL-072).

This guard closes that: it drives the SAME document through both forms --
fixture -> `tools/yaml-to-bpmn.py` -> BPMN -> both validators -- and compares
VERDICTS.

THREE outcomes, not two. The two-outcome version ("the forms must agree") is
wrong and was filed that way before the surface was measured: for
`E-TOPLEVEL-MISSING` the bridge REPAIRS the defect, synthesising
`<bpmn:process id="Pool_t">` from `workflowMeta.id`, so the bridged document is
genuinely clean and XML silence is CORRECT. A two-outcome harness reports
working code as broken -- a probe that fails when the claim is right, which is
costlier than a false pass because it is indistinguishable from a real finding.

  AGREE           both forms fire, or both are legitimately silent
  DISAGREE        the bridged doc still CARRIES the defect and XML is silent
  BRIDGE_REPAIRED the bridged doc no longer carries it -- DECLARED per pair with
                  the repair named, never inferred from "XML said nothing".
                  Inferring it is how a real hole gets absorbed as a repair.

Exit 0 = all pass; exit 1 = any failure (P-011 / the gating runner read this).
"""
import importlib.util
import os
import subprocess
import sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")
BRIDGE = os.path.join(ROOT, "tools", "yaml-to-bpmn.py")
PARITY_GUARD = os.path.join(HERE, "test_rule_form_parity.py")


def _load(path, name):
    if not os.path.isfile(path):
        raise RuntimeError(
            "%s not found at %s -- renamed or moved. This guard cannot evaluate "
            "and must not pass: an unloadable dependency would silently empty "
            "every comparison below." % (name, path))
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# --------------------------------------------------------------------------
# AC1: the pair table is DECLARED here, never parsed out of PARITY's prose.
#
# PARITY's counterpart field is free text -- `E-XML-STRUCTURE` stands in for six
# YAML rules as "E-NOT-MAPPING / E-TOPLEVEL-MISSING / *-FIELD", and entries carry
# parentheticals like "W-XML-GW-AMBIGUOUS (T-317)". Parsing that would anchor a
# structural check on prose, the defect this arc has hit four times. The key SET
# is drift-guarded against PARITY below (AC2); the counterparts are ours.
# --------------------------------------------------------------------------
PAIRS = {
    "E-TOPLEVEL-MISSING":   {"E-XML-STRUCTURE"},
    "E-LANE-FIELD":         {"E-XML-STRUCTURE"},
    # T-330 built the counterpart. This was the ONE of that task's three filed
    # holes that survived measurement: the bridge carries `lanes: []` through as
    # a <bpmn:laneSet> with zero children, so the defect really does reach the
    # XML form. Its two siblings are in BRIDGE_REPAIRED below.
    "E-LANES-EMPTY":        {"E-XML-LANES-EMPTY"},
    "E-NODE-FIELD":         {"E-XML-STRUCTURE"},
    "E-NOT-MAPPING":        {"E-XML-STRUCTURE"},
    # T-328 CORRECTION, not a tolerance. PARITY's prose pairs E-EDGE-FIELD with
    # E-XML-STRUCTURE; the measurement shows the XML form DOES catch it, under
    # E-XML-FLOW-DANGLING. The defect is detected on both forms -- the recorded
    # counterpart was simply the wrong one. Correcting it turns a false
    # "disagreement" into the AGREE it always was.
    "E-EDGE-FIELD":         {"E-XML-FLOW-DANGLING"},
    "E-NODE-LANE":          {"E-XML-LANEREF-DANGLING", "W-XML-NODE-UNASSIGNED"},
    "E-EDGE-DANGLING":      {"E-XML-FLOW-DANGLING"},
    "E-GW-OUTGOING":        {"E-XML-GW-OUTGOING"},
    "E-UID-DUP":            {"E-XML-UID-DUP"},
    # T-329 built the direct counterpart. E-INCEPTION-NOT-SOVEREIGN reads the
    # same attribute but asks whether the inception boundary is sovereignty-
    # laned; an out-of-enum value sailed past it. Touching the same carrier is
    # not being a counterpart.
    "E-AUTHORITY":          {"E-XML-AUTHORITY"},
    # PAIRED_SAME_ID (T-322): IW-9 O-3 is emitted under one id by BOTH forms, so
    # its counterpart is itself. Added because the AC2 drift guard caught its
    # absence on this guard's first run -- which is the drift guard working, not
    # a nuisance: without it this rule would have been reported as agreeing by a
    # comparison that never included it.
    "E-INCEPTION-NOT-SOVEREIGN": {"E-INCEPTION-NOT-SOVEREIGN"},
    "E-NODE-TYPE":          {"E-XML-NODE-TYPE"},
    "W-DEADEND":            {"W-XML-DEADEND"},
    "W-UNREACHABLE":        {"W-XML-UNREACHABLE"},
    "W-GW-AMBIGUOUS":       {"W-XML-GW-AMBIGUOUS"},
    "W-PGW-CONDITION":      {"W-XML-PGW-CONDITION"},
    "W-PGW-NOOP":           {"W-XML-PGW-NOOP"},
    "W-PGW-UNBALANCED":     {"W-XML-PGW-UNBALANCED"},
    "W-TYPE-LANE-MISMATCH": {"W-TYPE-LANE-MISMATCH"},
    "W-LANE-NO-OWNER": {"W-LANE-NO-OWNER"},                     # T-331
}

# AC4: untestable in PRINCIPLE -- no cross-form document exists to compare.
# Declared with the reason, printed every run, count-asserted below.
UNTESTABLE = {
    "E-NOT-MAPPING": "fires on YAML that is not a mapping at all; there is no "
                     "such document to bridge, so no BPMN counterpart can exist",
}
EXPECTED_UNTESTABLE = 1

# AC3: BRIDGE_REPAIRED -- declared, with the repair NAMED. Never inferred at
# runtime from "the XML form reported nothing", because that inference is
# exactly how a genuine coverage hole gets absorbed as a repair.
#
# Two kinds of repair live here and they are not equally benign:
#   repair-by-RECOVERY  -- the missing datum is reconstructed from elsewhere in
#                          the document (E-TOPLEVEL-MISSING).
#   repair-by-DEFAULT   -- the missing datum is INVENTED (E-LANE-FIELD,
#                          E-NODE-FIELD). The bridged document is well-formed,
#                          so XML silence is still correct, but the author's
#                          underspecification is now invisible on the BPMN form
#                          and the YAML form is the only place it can be seen.
# Both belong in this class; the distinction is recorded because only the second
# kind loses information, and a future decision to stop defaulting would move
# those two entries into KNOWN_DISAGREEMENTS rather than out of the harness.
BRIDGE_REPAIRED = {
    "E-TOPLEVEL-MISSING": "RECOVERY: yaml-to-bpmn.py synthesises <bpmn:process "
                          "id=\"Pool_t\" name=\"t\"> from workflowMeta.id when "
                          "`pool:` is absent, so the bridged document is "
                          "genuinely well-formed and XML silence is correct "
                          "rather than blind",
    "E-LANE-FIELD":       "DEFAULT (T-330): a lane missing `height` bridges to "
                          "<aef:laneMeta abbr=\"agt\" authority=\"initiative\" "
                          "height=\"120\"/> -- the laneMeta is emitted COMPLETE "
                          "with a defaulted height, so no defect reaches the XML "
                          "form. Filed as a coverage hole by T-328 on the "
                          "strength of the YAML rule alone; the bridged bytes "
                          "say otherwise",
    "E-NODE-FIELD":       "DEFAULT (T-330): a node missing `x` bridges to "
                          "<aef:position x=\"0\" y=\"100\"/> -- and 0 is the "
                          "T-312 unpositioned SENTINEL, so the map degrades into "
                          "the honest-degradation path the geometry rule already "
                          "skips rather than into an invalid document",
}
EXPECTED_REPAIRED = 3

# Known DISAGREEMENTS: the bridged document still CARRIES the defect and the XML
# form is silent. Each is a real coverage hole on the form the designer authors
# and AEF consumes. Counted and PRINTED every run, T-324 discipline: a tolerance
# that is not counted is a suppression. A NEW disagreement fails the build.
#
# Every entry MUST cite an open task. When the hole is closed the entry is
# DELETED, not decremented to zero -- a 0-count placeholder measures the next
# hole against an expectation instead of failing it.
#
# AC4 (T-330): each entry carries an executable CARRIES-probe, not just prose.
# The probe asserts the BRIDGED document still carries the defect. Without it a
# declared tolerance is unfalsifiable in the direction "this tolerance should
# not exist": the harness sees yaml-fires / xml-silent, finds the entry in this
# table, and reports it as expected -- which is precisely how E-LANE-FIELD and
# E-NODE-FIELD sat here as coverage holes when the bridge had repaired both.
# The BRIDGE_REPAIRED class was already answerable to the tree (a stale repair
# claim fails); this table was answerable only to itself.
def _carries_out_of_enum_authority(vw, root):
    for meta in root.iter("{%s}laneMeta" % vw.AEF_NS):
        value = meta.get("authority")
        if value is not None and value not in vw.AUTHORITIES:
            return True
    return False


#
# EMPTY as of T-329, and empty is the load-bearing state: every remaining
# cross-form difference is now either a DECLARED repair or DECLARED untestable.
# An empty collection satisfies every assertion written over it (the T-328
# `PAIRS = {}` lesson), so the NEW-disagreement branch below must still fail the
# build with nothing in this table -- proven by a teeth leg, not by inspection.
KNOWN_DISAGREEMENTS = {}
EXPECTED_DISAGREEMENTS = 0


# AC8: LATENT divergence -- the predicates differ, but the document that would
# separate them is one no emitter currently produces. Declared rather than left
# implicit, because the honest sentence is neither "they agree" nor "they
# disagree" but a named FLIP CONDITION. Printed every run and count-asserted:
# undeclared, this is invisible to every instrument we have.
LATENT = {
    ("W-GW-AMBIGUOUS", "W-XML-GW-AMBIGUOUS"):
        "same carrier, different test: YAML is falsy-based "
        "(`not e.get('condition')`, validate-workflow.py:417) and XML is "
        "existence-based (`find(conditionExpression) is None`, :949). An EMPTY "
        "condition is unconditioned on one form and conditioned on the other. "
        "FLIP CONDITION: neither emitter can currently produce one -- both are "
        "truthiness-gated (yaml-to-bpmn.py:342, aef-workflow-designer.html:9539) "
        "-- and 0 empty conditionExpression elements exist across the 100 files "
        "that carry one. Goes live the moment either emitter emits an empty "
        "element. NOTE the designer's IMPORT already normalises toward it "
        "(condEl present -> condition='', :9856) while export drops it.",
}
EXPECTED_LATENT = 1


def fixture_for(rule):
    for sub in ("invalid", "warn", "valid"):
        p = os.path.join(HERE, "fixtures", sub, rule + ".yaml")
        if os.path.isfile(p):
            return p
    return None


def _rule_ids(findings):
    return {f.rule for f in findings}


def classify(vw, yrule, xrules, path):
    """-> (outcome, yaml_fires, xml_fires, all_xml_rules, bridged_xml).

    Raises on tooling failure. The bridged text is returned rather than
    discarded so a KNOWN_DISAGREEMENT's CARRIES-probe can be run against the
    document the XML form actually saw -- not against the YAML source, which
    always carries the defect and would make every probe trivially true.
    """
    text = open(path, encoding="utf-8").read()
    yfound = _rule_ids(vw.run_yaml(text))
    proc = subprocess.run([sys.executable, BRIDGE, path],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        raise RuntimeError("bridge failed rc=%d on %s: %s"
                           % (proc.returncode, path,
                              proc.stderr.decode("utf-8", "replace")[:200]))
    bridged = proc.stdout.decode("utf-8")
    xfound = _rule_ids(vw.run_xml(bridged))
    yfires, xfires = yrule in yfound, bool(xrules & xfound)
    return (("AGREE" if yfires == xfires else "DISAGREE"),
            yfires, xfires, xfound, bridged)


def failures():
    out = []
    vw = _load(VALIDATOR, "validate_workflow")
    parity = _load(PARITY_GUARD, "rule_form_parity")

    # -- AC2: bidirectional drift guard against PARITY -----------------------
    paired_in_parity = {
        rid for rid, (kind, _note) in parity.PARITY.items()
        if kind in (parity.PAIRED, parity.PAIRED_SAME_ID)
        and not rid.startswith(("E-XML", "W-XML", "I-XML"))
    }
    missing = sorted(paired_in_parity - set(PAIRS))
    extra = sorted(set(PAIRS) - paired_in_parity)
    for rid in missing:
        out.append(
            "%s is PAIRED in test_rule_form_parity.py but absent from PAIRS here. "
            "A rule added to the parity table without a behavioural decision would "
            "be reported as agreeing by a guard that never compared it." % rid)
    for rid in extra:
        out.append(
            "%s is in PAIRS here but is not PAIRED in test_rule_form_parity.py. "
            "The two tables have drifted; this guard would be asserting agreement "
            "for a pairing the census does not recognise." % rid)

    # -- AC6: the (0) branch. An empty comparison set satisfies everything ----
    if not PAIRS:
        out.append("PAIRS is empty -- every assertion below is trivially "
                   "satisfied. Unevaluable, not clean.")
        return out
    if not paired_in_parity:
        out.append("extracted ZERO paired rules from test_rule_form_parity.py -- "
                   "the PARITY structure changed shape. The drift guard above is "
                   "vacuous and this guard must not pass.")
        return out

    # -- AC3/AC4: compare verdicts ------------------------------------------
    rows, compared = [], 0
    for yrule in sorted(PAIRS):
        if yrule in UNTESTABLE:
            rows.append((yrule, "UNTESTABLE", UNTESTABLE[yrule]))
            continue
        path = fixture_for(yrule)
        if path is None:
            out.append(
                "%s has no fixture, and is not DECLARED untestable. A rule with "
                "no document silently drops out of the comparison; that is an "
                "absence, and an absence must be declared with its reason."
                % yrule)
            continue
        try:
            outcome, yf, xf, xall, bridged = classify(
                vw, yrule, PAIRS[yrule], path)
        except Exception as exc:                                # noqa: BLE001
            out.append("%s: comparison could not run (%s). Unevaluable, not "
                       "clean." % (yrule, exc))
            continue
        compared += 1

        if yrule in BRIDGE_REPAIRED:
            # Declared repaired: the CLAIM is that the bridged doc no longer
            # carries the defect, so XML silence is correct. If the XML form
            # DOES fire, the declaration is stale and must be re-read.
            if xf:
                out.append(
                    "%s is declared BRIDGE_REPAIRED but the XML form now FIRES "
                    "(%s). The declared repair no longer describes the bridge; "
                    "a stale repair declaration hides the next real hole."
                    % (yrule, ", ".join(sorted(PAIRS[yrule] & xall))))
            rows.append((yrule, "BRIDGE_REPAIRED", BRIDGE_REPAIRED[yrule]))
            continue

        if outcome == "DISAGREE":
            if yrule not in KNOWN_DISAGREEMENTS:
                out.append(
                    "NEW DISAGREEMENT %s: yaml fires=%s, xml fires=%s (xml "
                    "reported: %s). The two implementations of this rule do not "
                    "agree, and test_rule_form_parity.py is green because both "
                    "forms merely NAME it."
                    % (yrule, yf, xf, ", ".join(sorted(xall)) or "(nothing)"))
                rows.append((yrule, "DISAGREE", "UNDECLARED"))
                continue
            note, carries = KNOWN_DISAGREEMENTS[yrule]
            # AC4: the tolerance must be answerable to the bridged bytes.
            try:
                still_carried = carries(vw, ET.fromstring(bridged))
            except Exception as exc:                            # noqa: BLE001
                out.append("%s: its CARRIES-probe could not run (%s). "
                           "Unevaluable, not clean." % (yrule, exc))
                still_carried = True
            if not still_carried:
                out.append(
                    "%s is declared a KNOWN_DISAGREEMENT -- a coverage hole -- "
                    "but its CARRIES-probe reports the bridged document does "
                    "NOT carry the defect. Then the XML form is silent because "
                    "there is nothing to find, and this belongs in "
                    "BRIDGE_REPAIRED with the repair named. Declaring a repair "
                    "as a hole invents work; the reverse hides it." % yrule)
            rows.append((yrule, "DISAGREE", note))
        else:
            rows.append((yrule, "AGREE", "yaml=%s xml=%s" % (yf, xf)))

    # A known disagreement that started agreeing must be DELETED, not left
    # standing -- otherwise it exempts the pair for whatever breaks it next.
    still = {r for r, o, _ in rows if o == "DISAGREE"}
    for rid in sorted(set(KNOWN_DISAGREEMENTS) - still):
        out.append(
            "%s is declared a KNOWN_DISAGREEMENT but the forms now AGREE. Delete "
            "the entry (do not decrement it to zero): a stale exemption measures "
            "the next divergence against an expectation instead of failing it."
            % rid)

    # -- AC4: counted tolerances --------------------------------------------
    n_dis = len(still)
    n_unt = sum(1 for _, o, _ in rows if o == "UNTESTABLE")
    n_rep = sum(1 for _, o, _ in rows if o == "BRIDGE_REPAIRED")
    if n_dis != EXPECTED_DISAGREEMENTS:
        out.append("expected %d known disagreements, found %d -- the tolerance "
                   "count moved; re-read it rather than adjusting the number."
                   % (EXPECTED_DISAGREEMENTS, n_dis))
    if n_unt != EXPECTED_UNTESTABLE:
        out.append("expected %d untestable pairs, found %d."
                   % (EXPECTED_UNTESTABLE, n_unt))
    if n_rep != EXPECTED_REPAIRED:
        out.append("expected %d bridge-repaired pairs, found %d."
                   % (EXPECTED_REPAIRED, n_rep))
    if compared == 0:
        out.append("ZERO pairs were actually compared -- every row fell through "
                   "to a declaration. A guard that declares everything and "
                   "measures nothing is not a guard.")

    # -- AC8: latent divergences are declared, and their pairs must still exist
    if len(LATENT) != EXPECTED_LATENT:
        out.append("expected %d latent divergence(s), found %d."
                   % (EXPECTED_LATENT, len(LATENT)))
    for (yrule, xrule) in LATENT:
        if PAIRS.get(yrule) != {xrule}:
            out.append(
                "latent divergence is declared for (%s, %s) but PAIRS no longer "
                "maps them to each other. A latent note pinned to a pairing that "
                "moved is a note about nothing." % (yrule, xrule))

    _report(rows, compared)
    return out


def _report(rows, compared):
    order = {"DISAGREE": 0, "BRIDGE_REPAIRED": 1, "UNTESTABLE": 2, "AGREE": 3}
    for rule, outcome, note in sorted(rows, key=lambda r: (order[r[1]], r[0])):
        if outcome == "AGREE":
            continue
        print("%-16s %-22s %s" % (outcome, rule, note))
    for (yrule, xrule), why in sorted(LATENT.items()):
        print("%-16s %-22s %s" % ("LATENT", yrule + "/" + xrule.split("-")[-1], why))
    agree = sum(1 for _, o, _ in rows if o == "AGREE")
    print("cross-form agreement: %d pairs compared, %d AGREE, %d known "
          "DISAGREE (declared, each citing an open task), %d bridge-repaired, "
          "%d untestable"
          % (compared, agree,
             sum(1 for _, o, _ in rows if o == "DISAGREE"),
             sum(1 for _, o, _ in rows if o == "BRIDGE_REPAIRED"),
             sum(1 for _, o, _ in rows if o == "UNTESTABLE")))


def main():
    try:
        fails = failures()
    except Exception as exc:                                    # noqa: BLE001
        print("cross-form agreement: UNEVALUABLE -- %s" % exc)
        return 1
    if fails:
        print("\ncross-form agreement: FAILED (%d)" % len(fails))
        for f in fails:
            print("  - %s" % f)
        return 1
    print("cross-form agreement: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
