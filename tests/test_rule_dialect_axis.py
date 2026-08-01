#!/usr/bin/env python3
"""T-325 (T-309 IW-1b) — every validator rule is classified UNIVERSAL /
DIALECT-RELATIVE / PRESENTATIONAL, and the classification is DERIVED from the
frozen standard rather than asserted.

WHY THIS EXISTS
---------------
`W-XML-GW-AMBIGUOUS` fires on 47 of AEF's 48 live gateways and on 0 of ours.
It is not measuring gateway correctness; it is measuring which toolchain wrote
the file. A rule like that cannot be surfaced to an author as-is: it would show
47 warnings on a map that is correct by the conventions it was written under,
and by AEF's L-527 a rule that gets tuned out is weaker than no rule, because
its silence stops meaning anything.

So before findings can reach the designer (T-309), each rule needs to say which
kind of claim it is making.

THE DISCRIMINATOR, AND WHY IT IS NOT A CORPUS COUNT
---------------------------------------------------
T-323 is the cautionary tale directly upstream of this file. The T-320 census
classified rules OUT-OF-SCOPE on the evidence that no file in the corpus carried
the construct — and was wrong, because absence from a corpus is not
inexpressibility. The corrected rule: **a corpus count is PRIORITY, never
CLASSIFICATION.** The same trap is available here, one level up, and it is more
tempting because a firing-rate table looks so much like evidence.

The classification is therefore derived from `docs/standards/aef-bpmn-mapping-v1.md`:

  - **PRESENTATIONAL** — every carrier the predicate reads is in the standard's
    Presentational class (§1). §1 is normative: "A change to a presentational
    attribute alone MUST be a no-op for the task graph." A rule reading only
    those carriers therefore cannot be reporting a task-graph defect, whatever
    else it is usefully reporting.

  - **DIALECT-RELATIVE** — the predicate fires on the ABSENCE of a carrier the
    standard does not mandate. Absence is conformant, so firing separates
    authoring convention from correctness. The load-bearing case: mapping-v1 §5
    defines an exclusiveGateway's branches as "outgoing edges = branches; edge
    label = condition", and forward-compile §3.1 admits "branch label /
    `conditionExpression`". Both carriers are standard-admitted. A rule that
    demands `conditionExpression` therefore fires on documents that satisfy the
    frozen standard — that is a defect in the rule, not a quirk of the peer.

  - **UNIVERSAL** — everything else: the predicate rests on structure any
    conformant document must satisfy, or it constrains a carrier only WHEN
    PRESENT, or the carrier is MUST-emit (in which case absence is itself the
    violation — PL-035).

POLARITY IS THE HINGE, and it is mechanical. `W-GW-AMBIGUOUS` fires when
`condition` is ABSENT (REQUIRES) and is dialect-relative. `W-PGW-CONDITION`
reads the same carrier but fires when it is PRESENT on a parallel branch
(CONSTRAINS) and is universal — a map that never writes a condition can never
trip it. Same carrier, opposite polarity, opposite class.

WHAT THIS DOES NOT PROVE, stated because a guard that overstates its reach is
the failure this arc keeps finding. The per-rule carrier declaration is checked
behaviourally only for the rules that carry a polarity probe. For the rest, that
a rule really reads the carrier it claims rests on having read the code. A
mis-declaration among the unprobed rules would be caught only if it happened to
land on a carrier of a different class -- and the classification would then be
wrong while the guard stayed green. The probed set is exactly the set whose
class is not UNIVERSAL, plus same-carrier controls; widening it is cheap and
should follow any new rule over an optional carrier.

Runnable standalone (exit 0 = pass) and under pytest. Wired into
tests/run-bridge-tests.sh.
"""
import importlib.util
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STANDARD = os.path.join(ROOT, "docs", "standards", "aef-bpmn-mapping-v1.md")

# ---- the axis --------------------------------------------------------------
UNIVERSAL = "UNIVERSAL"
DIALECT_RELATIVE = "DIALECT-RELATIVE"
PRESENTATIONAL = "PRESENTATIONAL"

# ---- carrier classes (derived from the standard, see _standard_partition) ---
SEMANTIC_MUST = "semantic-must"          # standard says MUST emit; absence IS the violation
SEMANTIC_OPTIONAL = "semantic-optional"  # governance-bearing, but conformant to omit
PRESENTATION = "presentational"          # standard §1 Presentational class
STRUCTURE = "structure"                  # no aef: carrier -- plain BPMN/YAML graph shape

# ---- predicate polarity ----------------------------------------------------
STRUCTURAL = "structural"    # reads graph shape only
REQUIRES = "requires"        # fires when the carrier is ABSENT / insufficient
CONSTRAINS = "constrains"    # fires when the carrier is PRESENT but malformed


# --------------------------------------------------------------------------
# Carrier -> class.
#
# Entries marked UNRATIFIED are carriers §1 does not actually place in either
# of its two classes, even though §1 opens by asserting "Every `aef:` datum is
# exactly one of two classes". That is a real hole in the frozen standard, not
# a modelling convenience here: it is COUNTED and PRINTED every run (see
# EXPECTED_UNRATIFIED) so it stays visible until ratified, rather than being
# quietly absorbed by whichever class made the arithmetic work.
# --------------------------------------------------------------------------
CARRIER_CLASS = {
    # -- structure: no aef: datum is read at all ---------------------------
    "document":                 STRUCTURE,
    "lanes":                    STRUCTURE,
    "nodes":                    STRUCTURE,
    "nodes/@type":              STRUCTURE,
    "nodes/@lane":              STRUCTURE,
    "edges":                    STRUCTURE,
    "element/@id":              STRUCTURE,
    "flow-node element":        STRUCTURE,
    "sequenceFlow":             STRUCTURE,
    "flowNodeRef":              STRUCTURE,
    # T-330: the XML form's spelling of the YAML carrier "lanes" above. Named
    # for the element rather than reusing "lanes" because every other XML-form
    # carrier in this table is named for its element (sequenceFlow,
    # flowNodeRef); a carrier key that silently spans both forms would hide
    # which form a classification was actually measured on.
    "bpmn:lane":                STRUCTURE,

    # -- semantic, MUST-emit -----------------------------------------------
    # §4: "Every node and edge MUST carry a stable `aef:uid`."
    "aef:uid":                  SEMANTIC_MUST,
    # §3 / O-3 (v1.1): the lane's authority is the sole authority-of-record and
    # an inception's go/no-go boundary MUST sit in a sovereignty lane. Not in
    # §1's enumeration (see UNRATIFIED below) but normatively mandated in §3.
    "aef:laneMeta/@authority":  SEMANTIC_MUST,

    # -- semantic, conformant to omit --------------------------------------
    # mapping-v1 §5 defines the branch condition carrier as the EDGE LABEL;
    # forward-compile §3.1 admits "branch label / conditionExpression". Two
    # standard-admitted carriers, so demanding this one is a dialect demand.
    "edge condition":           SEMANTIC_OPTIONAL,
    "conditionExpression":      SEMANTIC_OPTIONAL,
    # §1 semantic class, but nothing mandates their presence on a node.
    "aef:io":                   SEMANTIC_OPTIONAL,
    "aef:constituents":         SEMANTIC_OPTIONAL,
    # §2: an editor metaKey explicitly OUTSIDE the frozen v1 contract, which
    # "MAY change without a standard bump".
    "aef:meta/@scopeOf":        SEMANTIC_OPTIONAL,

    # -- presentational (§1) ------------------------------------------------
    "aef:position":             PRESENTATION,

    # -- UNRATIFIED: §1 places these in neither class -----------------------
    "aef:laneMeta/@height":     PRESENTATION,      # UNRATIFIED
    "aef:laneMeta/@abbr":       SEMANTIC_OPTIONAL,  # UNRATIFIED
}

# Carriers whose class above is this file's reading rather than the standard's
# ruling. Printed every run; the count is asserted, so a new one cannot join
# silently. `aef:laneMeta/@authority` is deliberately NOT here: §1 omits it but
# §3/O-3 mandates it in normative language, so the standard does rule on it.
UNRATIFIED_CARRIERS = {
    "aef:laneMeta/@height": "§1 lists neither laneMeta nor its attributes; read "
                            "as layout because the forward compile never reads it",
    "aef:laneMeta/@abbr":   "§1 lists neither; read as governance-bearing because "
                            "it is an identity key the compile surfaces",
}
EXPECTED_UNRATIFIED = 2


# --------------------------------------------------------------------------
# Per-rule: (carrier(s), polarity). The classification is COMPUTED from these
# by classify() -- it is deliberately not written down per rule, so that a
# wrong classification has to come from a wrong carrier or a wrong polarity,
# both of which are checkable claims about the code.
# --------------------------------------------------------------------------
RULE_CARRIERS = {
    # ---- YAML form -------------------------------------------------------
    "E-NOT-MAPPING":            (("document",), STRUCTURAL),
    "E-TOPLEVEL-MISSING":       (("document",), STRUCTURAL),
    "E-LANES-EMPTY":            (("lanes",), STRUCTURAL),
    "E-LANE-FIELD":             (("lanes",), STRUCTURAL),
    "E-AUTHORITY":              (("aef:laneMeta/@authority",), CONSTRAINS),
    "E-ABBR-DUP":               (("aef:laneMeta/@abbr",), CONSTRAINS),
    "E-NODE-FIELD":             (("nodes",), STRUCTURAL),
    "E-NODE-TYPE":              (("nodes/@type",), STRUCTURAL),
    "E-NODE-LANE":              (("nodes/@lane",), STRUCTURAL),
    "E-UID-DUP":                (("aef:uid",), CONSTRAINS),
    "E-EDGE-FIELD":             (("edges",), STRUCTURAL),
    "E-EDGE-DANGLING":          (("edges",), STRUCTURAL),
    "E-GW-OUTGOING":            (("edges",), STRUCTURAL),
    "W-GW-AMBIGUOUS":           (("edge condition",), REQUIRES),
    "W-PGW-CONDITION":          (("edge condition",), CONSTRAINS),
    "W-PGW-NOOP":               (("edges",), STRUCTURAL),
    "W-PGW-UNBALANCED":         (("edges",), STRUCTURAL),
    "E-CONST-SHAPE":            (("aef:constituents",), CONSTRAINS),
    "E-CONST-DUP":              (("aef:constituents",), CONSTRAINS),
    "W-CONST-FIELD":            (("aef:constituents",), CONSTRAINS),
    "E-SCOPEOF-SELF":           (("aef:meta/@scopeOf",), CONSTRAINS),
    "E-SCOPEOF-DANGLING":       (("aef:meta/@scopeOf",), CONSTRAINS),
    "W-SCOPEOF-TYPE":           (("aef:meta/@scopeOf",), CONSTRAINS),
    "W-UNREACHABLE":            (("edges",), STRUCTURAL),
    "W-DEADEND":                (("edges",), STRUCTURAL),
    # fires when a node's REQUIRED input has no upstream `io.outputs` entry
    # matching by name -- i.e. it demands an optional carrier be present on
    # nodes OTHER than the one being checked. Conformant to omit, so a corpus
    # that declares io only where it is consumed lights up.
    "W-IO-INPUT":               (("aef:io",), REQUIRES),
    # PL-035: authority is MUST-emit, so its ABSENCE is the violation and this
    # is universal despite firing on absence.
    "E-INCEPTION-NOT-SOVEREIGN": (("aef:laneMeta/@authority",), REQUIRES),
    "W-TYPE-LANE-MISMATCH":     (("aef:laneMeta/@authority",), CONSTRAINS),

    # ---- XML form --------------------------------------------------------
    "E-XML-STRUCTURE":          (("document",), STRUCTURAL),
    "E-XML-ID-DUP":             (("element/@id",), STRUCTURAL),
    "E-XML-UID-DUP":            (("aef:uid",), CONSTRAINS),
    "E-XML-NODE-TYPE":          (("flow-node element",), STRUCTURAL),
    "E-XML-FLOW-DANGLING":      (("sequenceFlow",), STRUCTURAL),
    "E-XML-LANEREF-DANGLING":   (("flowNodeRef",), STRUCTURAL),
    # T-330. Same carrier class and same polarity as the YAML form's
    # E-LANES-EMPTY above ("lanes", STRUCTURAL) -- deliberately, because the
    # two rules are the same claim about the same construct expressed on two
    # forms. A divergence here would mean the pair T-328 now reports as
    # AGREE agrees on the verdict while disagreeing on what kind of claim it is.
    "E-XML-LANES-EMPTY":        (("bpmn:lane",), STRUCTURAL),
    "E-XML-GW-OUTGOING":        (("sequenceFlow",), STRUCTURAL),
    "W-XML-GW-AMBIGUOUS":       (("conditionExpression",), REQUIRES),
    "W-XML-NODE-UNASSIGNED":    (("flowNodeRef",), STRUCTURAL),
    "W-XML-PGW-CONDITION":      (("conditionExpression",), CONSTRAINS),
    "W-XML-PGW-NOOP":           (("sequenceFlow",), STRUCTURAL),
    "W-XML-PGW-UNBALANCED":     (("sequenceFlow",), STRUCTURAL),
    "W-XML-UNREACHABLE":        (("sequenceFlow",), STRUCTURAL),
    "W-XML-DEADEND":            (("sequenceFlow",), STRUCTURAL),
    "W-XML-LANE-GEOMETRY":      (("aef:position",), CONSTRAINS),
    "I-XML-LANE-GEOMETRY-SKIP": (("aef:position",), REQUIRES),
    "W-XML-LANE-CAPACITY":      (("aef:position", "aef:laneMeta/@height"), CONSTRAINS),
    "I-XML-LANE-CAPACITY-SKIP": (("aef:position", "aef:laneMeta/@height"), REQUIRES),
}


def classify(carriers, polarity):
    """The whole discriminator, in one place, with no corpus term in it."""
    classes = [CARRIER_CLASS[c] for c in carriers]
    # §1 is normative: a change to presentational data alone MUST be a no-op for
    # the task graph, so a rule reading only those cannot report a graph defect.
    if all(c == PRESENTATION for c in classes):
        return PRESENTATIONAL
    # fires on the absence of something the standard does not mandate
    if polarity == REQUIRES and any(c == SEMANTIC_OPTIONAL for c in classes):
        return DIALECT_RELATIVE
    return UNIVERSAL


# --------------------------------------------------------------------------
# the standard, read as the source of the partition
# --------------------------------------------------------------------------
def _bullet(src, label):
    """Text of the §1 bullet introduced by `label`, anchored on the bold run.

    Anchored on `**<label>:**` -- a structural literal, not a loose word match.
    The bullet ends at the next top-level bullet or heading.
    """
    m = re.search(r"^- \*\*%s[^*]*\*\*(.*?)(?=^- \*\*|^#)" % re.escape(label),
                  src, re.S | re.M)
    if not m:
        raise RuntimeError(
            "could not locate the '%s' bullet in %s. §1 is the source of the "
            "carrier partition; if it has been renamed or restructured this "
            "guard cannot derive anything, and an empty carrier set would make "
            "every rule look universal -- which reads as a clean bill of health."
            % (label, STANDARD))
    return m.group(1)


def _standard_partition():
    """-> (semantic_tokens, presentational_tokens, must_meta_keys) from §1/§2."""
    if not os.path.isfile(STANDARD):
        raise RuntimeError(
            "frozen standard missing at %s -- unevaluable, not clean" % STANDARD)
    src = open(STANDARD, encoding="utf-8").read()
    sem = set(re.findall(r"`(aef:[A-Za-z]+)`", _bullet(src, "Semantic")))
    pres = set(re.findall(r"`(aef:[A-Za-z]+)`", _bullet(src, "Presentational")))
    block = re.search(r"```conformance-governance-meta-keys\n(.*?)```", src, re.S)
    if not block:
        raise RuntimeError(
            "the ```conformance-governance-meta-keys fenced block is gone from "
            "%s -- it is the machine-readable list of MUST-emit meta keys" % STANDARD)
    must = {l.strip() for l in block.group(1).splitlines() if l.strip()}
    if not sem or not pres or not must:
        raise RuntimeError(
            "parsed %d semantic / %d presentational tokens and %d must-keys from "
            "the standard -- a zero on any of these trivially satisfies the drift "
            "checks below" % (len(sem), len(pres), len(must)))
    return sem, pres, must


def _root_token(carrier):
    """`aef:laneMeta/@height` -> `aef:laneMeta`; non-aef carriers -> None."""
    if not carrier.startswith("aef:"):
        return None
    return carrier.split("/")[0]


# --------------------------------------------------------------------------
def failures(quiet=False):
    fails = []

    # rule enumeration is single-sourced from the parity guard's extractor, so
    # the two axes can never disagree about WHICH rules exist.
    spec = importlib.util.spec_from_file_location(
        "_t325_parity", os.path.join(ROOT, "tests", "test_rule_form_parity.py"))
    parity = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(parity)
    y, x = parity.extract_rules()
    emitted = dict(y)
    emitted.update(x)

    sem_tokens, pres_tokens, must_keys = _standard_partition()

    # (1) completeness, both ways. An emitted rule with no carrier declaration
    #     is a rule whose claim-kind nobody decided; a declaration for a rule
    #     nobody emits is dead weight that skews the counts below.
    for rid in sorted(set(emitted) - set(RULE_CARRIERS)):
        fails.append(
            "rule '%s' is emitted by the validator but declares no carrier in "
            "RULE_CARRIERS. Until it does, nothing knows whether surfacing it to "
            "an author states a correctness fact or a house convention." % rid)
    for rid in sorted(set(RULE_CARRIERS) - set(emitted)):
        fails.append(
            "RULE_CARRIERS declares '%s' but no validator emits it -- renamed or "
            "removed; drop the entry (it currently skews the class counts)" % rid)

    # (2) every declared carrier must have a class. A carrier missing from
    #     CARRIER_CLASS would raise in classify(); catching it here names the
    #     rule instead of dying with a KeyError.
    for rid, (carriers, _pol) in sorted(RULE_CARRIERS.items()):
        for c in carriers:
            if c not in CARRIER_CLASS:
                fails.append(
                    "rule '%s' declares carrier %r, which has no class in "
                    "CARRIER_CLASS" % (rid, c))

    # (3) the carrier map must agree with the frozen standard, BOTH ways.
    #     One direction alone is the T-321 trap: agreement with one side is not
    #     agreement.
    mapped_pres = {_root_token(c) for c, cls in CARRIER_CLASS.items()
                   if cls == PRESENTATION and _root_token(c)}
    for tok in sorted(pres_tokens & {_root_token(c) for c in CARRIER_CLASS
                                     if _root_token(c)}):
        if tok not in mapped_pres:
            fails.append(
                "standard §1 lists %s as Presentational, but CARRIER_CLASS "
                "classifies it otherwise -- the standard rules on this, not "
                "this file" % tok)
    for tok in sorted(mapped_pres):
        if tok in sem_tokens:
            fails.append(
                "CARRIER_CLASS calls %s presentational but standard §1 lists it "
                "as Semantic (governance-bearing)" % tok)
        elif tok not in pres_tokens and tok not in {
                _root_token(c) for c in UNRATIFIED_CARRIERS}:
            fails.append(
                "CARRIER_CLASS calls %s presentational but standard §1 lists it "
                "in neither class, and it is not declared UNRATIFIED. §1 claims "
                "the partition is total; an uncovered carrier must be declared, "
                "not absorbed" % tok)
    # ...and semantic carriers the standard explicitly names must not be
    # demoted here either.
    for c, cls in sorted(CARRIER_CLASS.items()):
        tok = _root_token(c)
        if tok and tok in sem_tokens and cls == PRESENTATION:
            fails.append("CARRIER_CLASS demotes %s to presentational; §1 lists "
                         "it as Semantic" % c)

    # (4) the MUST-emit meta keys parsed from the standard must actually be
    #     treated as mandatory wherever a rule reads them.
    for c, cls in sorted(CARRIER_CLASS.items()):
        m = re.match(r"aef:meta/@(\w+)$", c)
        if m and m.group(1) in must_keys and cls != SEMANTIC_MUST:
            fails.append(
                "carrier %s is in the standard's frozen MUST-emit meta-key block "
                "but CARRIER_CLASS calls it %s -- a MUST carrier's absence is the "
                "violation (PL-035), so no rule reading it can be dialect-relative"
                % (c, cls))

    # (5) counted tolerance for carriers §1 does not place in either class.
    #     Printed every run; one more fails the build.
    declared_unratified = set(UNRATIFIED_CARRIERS)
    if len(declared_unratified) != EXPECTED_UNRATIFIED:
        fails.append(
            "UNRATIFIED_CARRIERS holds %d entries, expected %d. These are places "
            "the frozen standard's supposedly-total partition does not actually "
            "rule; a new one is a standard question, not a bookkeeping update."
            % (len(declared_unratified), EXPECTED_UNRATIFIED))
    if not quiet:
        for c in sorted(declared_unratified):
            print("NOTE (unratified, T-325): carrier %s -- %s"
                  % (c, UNRATIFIED_CARRIERS[c]))

    # (6) polarity is a behavioural claim, not a label. Only runnable once the
    #     declarations above are complete and coherent -- running it on a
    #     half-declared table produces confusing secondary failures.
    if not fails:
        fails.extend(probe_failures())

    return fails


# --------------------------------------------------------------------------
# POLARITY PROBES -- the part that makes the classification checkable.
#
# Everything above derives a class from a declared (carrier, polarity) pair.
# Those two declarations are still hand-written, and a hand-written label that
# nothing tests is exactly the unfalsifiable-PAIRED trap T-323 had to repair:
# the guard would faithfully compute a wrong class from a wrong premise and
# report it green.
#
# So polarity is made falsifiable BEHAVIOURALLY, against the tree's real
# fixtures. For a REQUIRES rule, ADDING the carrier must silence it. For a
# CONSTRAINS rule, REMOVING the carrier must silence it. Swap the two labels
# and both probes fail.
#
# SCOPE, stated rather than implied (G-013): probes cover all 3 rules the axis
# calls DIALECT-RELATIVE, plus 2 CONSTRAINS rules reading the SAME carrier on
# both forms -- the pairs that prove polarity discriminates rather than the
# carrier alone. The remaining CONSTRAINS rules over optional carriers
# (constituents x3, scopeOf x3, abbr) are classified but NOT behaviourally
# probed. A new DIALECT-RELATIVE rule cannot join unprobed -- that is asserted.
# --------------------------------------------------------------------------
POLARITY_PROBES = {
    "W-GW-AMBIGUOUS": (
        "warn/W-GW-AMBIGUOUS.yaml",
        "- {uid: e_b, source: n_g, target: n_b}",
        '- {uid: e_b, source: n_g, target: n_b, condition: "yes"}'),
    "W-PGW-CONDITION": (
        "warn/W-PGW-CONDITION.yaml",
        ', condition: "${x == true}"',
        ""),
    "W-IO-INPUT": (
        "warn/W-IO-INPUT.yaml",
        "- {uid: n_a, type: startEvent, name: Start, lane: framework, x: 100, y: 100}",
        "- {uid: n_a, type: startEvent, name: Start, lane: framework, x: 100, y: 100,"
        " io: {outputs: [{name: bundle, type: ref}]}}"),
    "W-XML-GW-AMBIGUOUS": (
        "warn/W-XML-GW-AMBIGUOUS.xml",
        '<bpmn:sequenceFlow id="f1" name="code" sourceRef="n_g" targetRef="n_a"/>\n'
        '    <bpmn:sequenceFlow id="f2" name="design" sourceRef="n_g" targetRef="n_b"/>',
        '<bpmn:sequenceFlow id="f1" name="code" sourceRef="n_g" targetRef="n_a">'
        '<bpmn:conditionExpression>${t == "code"}</bpmn:conditionExpression>'
        '</bpmn:sequenceFlow>\n'
        '    <bpmn:sequenceFlow id="f2" name="design" sourceRef="n_g" targetRef="n_b">'
        '<bpmn:conditionExpression>${t == "design"}</bpmn:conditionExpression>'
        '</bpmn:sequenceFlow>'),
    "W-XML-PGW-CONDITION": (
        "warn/W-XML-PGW-CONDITION.xml",
        '<bpmn:sequenceFlow id="f1" sourceRef="n_f" targetRef="n_a">\n'
        '      <bpmn:conditionExpression>${x == true}</bpmn:conditionExpression>\n'
        '    </bpmn:sequenceFlow>',
        '<bpmn:sequenceFlow id="f1" sourceRef="n_f" targetRef="n_a"/>'),
}


def _validator():
    path = os.path.join(ROOT, "tools", "validate-workflow.py")
    if not os.path.isfile(path):
        raise RuntimeError("validator missing at %s -- unevaluable" % path)
    spec = importlib.util.spec_from_file_location("_t325_validator", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# Text form of each probe-able carrier, for counting how the transform moved it.
# Counted on a COMMENT-STRIPPED copy: W-XML-GW-AMBIGUOUS.xml explains itself by
# naming `bpmn:conditionExpression` in its header comment, and a count that
# includes prose is the G-009 class -- here it would be satisfied by the
# explanation rather than by the bytes.
CARRIER_TOKEN = {
    "edge condition":      "condition:",
    "conditionExpression": "conditionExpression",
    "aef:io":              "io:",
}


def _strip_comments(text, is_xml):
    if is_xml:
        return re.sub(r"<!--.*?-->", "", text, flags=re.S)
    return "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("#"))


def _fires(mod, text, rule_id, is_xml):
    findings = mod.run_xml(text) if is_xml else mod.run_yaml(text)
    return any(f.rule == rule_id for f in findings)


def probe_failures():
    fails = []
    mod = _validator()
    cls = classification()

    # every dialect-relative rule must be probed -- a new one may not arrive
    # carrying only an assertion.
    for rid, c in sorted(cls.items()):
        if c == DIALECT_RELATIVE and rid not in POLARITY_PROBES:
            fails.append(
                "rule '%s' is classified DIALECT-RELATIVE but has no polarity "
                "probe. That classification is the one that decides whether a "
                "finding is shown to an author, so it may not rest on a label."
                % rid)

    for rid, (rel, before, after) in sorted(POLARITY_PROBES.items()):
        path = os.path.join(ROOT, "tests", "fixtures", rel)
        if not os.path.isfile(path):
            fails.append("probe fixture %s is missing -- probe unevaluable" % rel)
            continue
        original = open(path, encoding="utf-8").read()
        if before not in original:
            fails.append(
                "probe for '%s': the anchor text is no longer present in %s. "
                "The transform would be a no-op, and a no-op transform produces "
                "output indistinguishable from a passing probe (T-321)." % (rid, rel))
            continue
        mutated = original.replace(before, after, 1)
        if mutated == original:
            fails.append("probe for '%s': transform did not change %s" % (rid, rel))
            continue

        is_xml = rel.endswith(".xml")
        carriers, polarity = RULE_CARRIERS[rid]

        # The transform's DIRECTION must be the one the declared polarity
        # implies -- REQUIRES is silenced by ADDING the carrier, CONSTRAINS by
        # REMOVING it. Without this the probe would pass under either label and
        # the polarity would be believed rather than checked, which is the whole
        # defect this file exists to avoid.
        token = next((CARRIER_TOKEN[c] for c in carriers if c in CARRIER_TOKEN), None)
        if token is None:
            fails.append(
                "probe for '%s': no carrier of %s has a text token in "
                "CARRIER_TOKEN, so the transform direction cannot be checked"
                % (rid, list(carriers)))
            continue
        n_before = _strip_comments(original, is_xml).count(token)
        n_after = _strip_comments(mutated, is_xml).count(token)
        wanted = "more" if polarity == REQUIRES else "fewer"
        got = "more" if n_after > n_before else ("fewer" if n_after < n_before
                                                else "the same")
        if got != wanted:
            fails.append(
                "probe for '%s': declared polarity %s implies the silencing "
                "transform %s the carrier %r, so the mutated document should "
                "carry %s occurrences -- it carries %s (%d -> %d). Either the "
                "polarity label or the transform is wrong."
                % (rid, polarity,
                   "ADDS" if polarity == REQUIRES else "REMOVES",
                   token, wanted, got, n_before, n_after))
            continue

        fired_before = _fires(mod, original, rid, is_xml)
        fired_after = _fires(mod, mutated, rid, is_xml)

        if not fired_before:
            fails.append(
                "probe for '%s': the fixture that exists to demonstrate this rule "
                "does not fire it. Either the rule or the fixture moved; the "
                "probe below would then prove nothing." % rid)
            continue
        if fired_after:
            fails.append(
                "probe for '%s': declared polarity %s, but %s the carrier did NOT "
                "silence it. The declared polarity is what makes this rule %s, so "
                "the classification is wrong or the carrier is misidentified."
                % (rid, polarity,
                   "adding" if polarity == REQUIRES else "removing", cls[rid]))

    return fails


def classification():
    """-> {rule_id: class}. Raises if any carrier is unclassified."""
    return {rid: classify(carriers, pol)
            for rid, (carriers, pol) in RULE_CARRIERS.items()}


# --------------------------------------------------------------------------
# Negative controls -- run every time, not only under a teeth harness.
#
# A control only proves as much as its own discriminator (T-323): each one below
# breaks a DIFFERENT premise, because a control that shares the premise it is
# defending will agree with a wrong rule and report green.
# --------------------------------------------------------------------------
def _control(name, mutate, fails, expect="fails"):
    """Apply `mutate` to module globals, assert the guard reacts, restore."""
    saved = {k: globals()[k] for k in
             ("RULE_CARRIERS", "CARRIER_CLASS", "UNRATIFIED_CARRIERS",
              "EXPECTED_UNRATIFIED", "STANDARD", "POLARITY_PROBES")}
    try:
        mutate()
        if expect == "fails":
            if not failures(quiet=True):
                fails.append(
                    "negative control '%s' did not fail -- the check it targets "
                    "is decorative" % name)
        else:  # expect a raise
            try:
                failures(quiet=True)
            except RuntimeError:
                pass
            else:
                fails.append(
                    "negative control '%s' did not RAISE -- an unevaluable "
                    "premise must be RED, not quiet (T-312)" % name)
    finally:
        globals().update(saved)


def negative_controls():
    fails = []

    def _no_declaration():
        globals()["RULE_CARRIERS"] = {k: v for k, v in RULE_CARRIERS.items()
                                      if k != "E-GW-OUTGOING"}
    _control("an emitted rule with no carrier declaration", _no_declaration, fails)

    def _unclassified_carrier():
        globals()["CARRIER_CLASS"] = {k: v for k, v in CARRIER_CLASS.items()
                                      if k != "edges"}
    _control("a declared carrier with no class", _unclassified_carrier, fails)

    def _demote_standard_token():
        globals()["CARRIER_CLASS"] = dict(CARRIER_CLASS,
                                          **{"aef:position": SEMANTIC_OPTIONAL})
    _control("a §1-Presentational token classified otherwise",
             _demote_standard_token, fails)

    def _absorb_unratified():
        globals()["UNRATIFIED_CARRIERS"] = {}
        globals()["EXPECTED_UNRATIFIED"] = 0
    _control("a carrier §1 does not cover, absorbed silently rather than declared",
             _absorb_unratified, fails)

    def _unprobed_dialect_rule():
        globals()["POLARITY_PROBES"] = {
            k: v for k, v in POLARITY_PROBES.items() if k != "W-GW-AMBIGUOUS"}
    _control("a DIALECT-RELATIVE rule whose polarity is only asserted",
             _unprobed_dialect_rule, fails)

    def _missing_standard():
        globals()["STANDARD"] = os.path.join(ROOT, "docs", "standards", "__none__.md")
    _control("an unreadable frozen standard", _missing_standard, fails, expect="raise")

    return fails


def test_rule_dialect_axis():
    fails = failures(quiet=True)
    assert not fails, "rule dialect-axis drift:\n" + "\n".join(fails)


def test_negative_controls():
    fails = negative_controls()
    assert not fails, "dialect-axis controls:\n" + "\n".join(fails)


def main():
    fails = failures() + negative_controls()
    if fails:
        for f in fails:
            sys.stderr.write("FAIL: %s\n" % f)
        sys.stderr.write("\n%d dialect-axis failure(s)\n" % len(fails))
        return 1
    cls = classification()
    counts = {k: sum(1 for v in cls.values() if v == k)
              for k in (UNIVERSAL, DIALECT_RELATIVE, PRESENTATIONAL)}
    for rid in sorted(cls):
        if cls[rid] != UNIVERSAL:
            print("  %-28s %s" % (rid, cls[rid]))
    # G-013: the summary names its SUBJECT, not just its numbers.
    print("rule dialect axis: %d validator rules classified from the frozen "
          "standard's carrier partition -- %d universal, %d dialect-relative, "
          "%d presentational (%d carriers unratified by §1). %d polarity probes "
          "run against real fixtures, covering %d/%d dialect-relative rules plus "
          "%d same-carrier CONSTRAINS controls; %d CONSTRAINS rules over optional "
          "carriers are classified but not behaviourally probed. No corpus term "
          "participates in this classification."
          % (len(cls), counts[UNIVERSAL], counts[DIALECT_RELATIVE],
             counts[PRESENTATIONAL], len(UNRATIFIED_CARRIERS),
             len(POLARITY_PROBES),
             sum(1 for r in POLARITY_PROBES if cls[r] == DIALECT_RELATIVE),
             counts[DIALECT_RELATIVE],
             sum(1 for r in POLARITY_PROBES if cls[r] != DIALECT_RELATIVE),
             sum(1 for r, (c, p) in RULE_CARRIERS.items()
                 if p == CONSTRAINS and r not in POLARITY_PROBES
                 and any(CARRIER_CLASS[k] == SEMANTIC_OPTIONAL for k in c))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
