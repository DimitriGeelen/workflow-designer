#!/usr/bin/env python3
"""T-317: W-XML-GW-AMBIGUOUS — branch-ambiguity parity between the two validators.

The designer speaks BPMN. `Validator` (YAML) carried `W-GW-AMBIGUOUS`;
`XmlValidator` (BPMN) did not. Surfacing "the validator" in the editor (T-309)
would therefore have surfaced the weaker of the two rule sets, and would
specifically have failed to answer the gateway question that prompted the
inception.

The gap was demonstrated before it was closed: stripping all 5
`conditionExpression` elements out of a corpus map left the validator reporting
`VALID -- no findings`. A rule whose absence was never demonstrated is a rule
nobody has reason to trust.

WHAT THIS PINS THAT THE FIXTURE SUITE DOES NOT. The `<RULE-ID>.<ext>` fixtures
pin "fires" and "stays silent". This module pins the things a fixture cannot:
that the threshold is exactly one and not zero, that the two validator classes
have not drifted apart again, and that the corpus census is a measured number
rather than an assumed one.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")
SRC = os.path.join(ROOT, "tools", "validate-workflow.py")

RULE = "W-XML-GW-AMBIGUOUS"
YAML_RULE = "W-GW-AMBIGUOUS"

# The single map in everything we hold that carries this finding, recorded as a
# literal. Deliberately NOT derived from `git show HEAD~1`: that comparison is
# right exactly once, and every run after silently compares something against
# itself.
EXPECTED_HITS = {
    "tests/fixtures/aef-overlay/draft-knowledge-leveling-v3.bpmn": 1,
}

failures = []


def findings(path):
    r = subprocess.run([sys.executable, VALIDATOR, path, "--json"],
                       capture_output=True, text=True)
    if not r.stdout.strip():
        return []
    return json.loads(r.stdout).get("findings", [])


def rule_hits(path, rule=RULE):
    return [f for f in findings(path) if f["rule"] == rule]


# -- 1. the rule exists on the XML path, and on the XML path specifically -----
# Anchored on the emit form, not a bare token: the rule id also appears in this
# file's own docstring and in comments, and a bare-token grep would be satisfied
# by the prose explaining the rule. Fourth time this class has come up in the
# arc, so it is now the default way these checks get written.
src = open(SRC, encoding="utf-8").read()
i_yaml = src.find("class Validator")
i_xml = src.find("class XmlValidator")
if not (0 < i_yaml < i_xml):
    failures.append("cannot locate the two validator classes — this check "
                    "cannot evaluate and must not pass")
else:
    yaml_part, xml_part = src[i_yaml:i_xml], src[i_xml:]
    if ('"%s"' % RULE) not in xml_part:
        failures.append("%s is not emitted by XmlValidator" % RULE)
    if ('"%s"' % YAML_RULE) not in yaml_part:
        failures.append("%s vanished from the YAML Validator — the parity this "
                        "module pins is between TWO rules, and one of them is "
                        "gone" % YAML_RULE)
    # Severity parity: both must be WARN. At ERROR this would hard-fail
    # promoted peer bytes we are forbidden to edit — the T-312 lesson, which
    # was vindicated on day one.
    m = re.search(r'self\.(warn|err)\(\s*\n?\s*"%s"' % RULE, xml_part)
    if not m:
        failures.append("cannot determine the severity of %s" % RULE)
    elif m.group(1) != "warn":
        failures.append("%s is emitted as %s; must be WARN so it cannot "
                        "hard-fail AEF's un-editable bytes"
                        % (RULE, m.group(1).upper()))

# -- 2. the boundary is exactly one, in both directions ----------------------
# A rule written as ">= 1 unconditioned" instead of "> 1" would flag every
# well-formed gateway in the corpus, and the warn fixture would keep passing
# while it did. Only the silent side pins the threshold.
boundary = os.path.join(ROOT, "tests", "fixtures", "valid", "gw-single-default.xml")
warns = os.path.join(ROOT, "tests", "fixtures", "warn", "W-XML-GW-AMBIGUOUS.xml")
for path, expect, why in (
        (boundary, 0, "exactly one unconditioned outgoing edge is the DEFAULT "
                      "branch and is well-formed"),
        (warns, 1, "three unconditioned outgoing edges leave the runtime no "
                   "defined choice")):
    if not os.path.isfile(path):
        failures.append("boundary fixture missing: %s" % path)
        continue
    got = len(rule_hits(path))
    if got != expect:
        failures.append("%s: expected %d %s finding(s) (%s), got %d"
                        % (os.path.basename(path), expect, RULE, why, got))

# -- 3. the two-branch case, which is the one the designer will actually hit --
# Built in memory from the warn fixture rather than stored as a third file: the
# distinction being pinned is 1 vs 2, and a fixture per integer is how a suite
# grows without gaining coverage.
two = open(warns, encoding="utf-8").read().replace(
    '<bpmn:sequenceFlow id="f3" name="environment" sourceRef="n_g" targetRef="n_c"/>',
    '<bpmn:sequenceFlow id="f3" name="environment" sourceRef="n_g" targetRef="n_c">'
    '<bpmn:conditionExpression>${t == "env"}</bpmn:conditionExpression>'
    '</bpmn:sequenceFlow>')
if two == open(warns, encoding="utf-8").read():
    failures.append("two-branch case: the substitution matched nothing, so this "
                    "check is vacuous — the warn fixture's f3 flow changed shape")
else:
    import tempfile
    with tempfile.NamedTemporaryFile("w", suffix=".xml", delete=False) as fh:
        fh.write(two)
        tmp = fh.name
    try:
        hits = rule_hits(tmp)
        if len(hits) != 1:
            failures.append("two unconditioned branches: expected 1 %s, got %d"
                            % (RULE, len(hits)))
        elif "2 outgoing flows" not in hits[0]["message"]:
            failures.append("two unconditioned branches: message does not name "
                            "the count: %s" % hits[0]["message"])
    finally:
        os.unlink(tmp)

# -- 4. corpus census, measured -----------------------------------------------
import glob
swept = 0
actual = {}
for pattern in ("examples/aef-processes/rendered/*.bpmn",
                "tests/fixtures/aef-bpmn/*.bpmn",
                "tests/fixtures/aef-overlay/*.bpmn"):
    for path in sorted(glob.glob(os.path.join(ROOT, pattern))):
        swept += 1
        n = len(rule_hits(path))
        if n:
            actual[os.path.relpath(path, ROOT)] = n
if swept == 0:
    failures.append("corpus sweep matched no maps — the globs are wrong and "
                    "this census is vacuous")
if actual != EXPECTED_HITS:
    failures.append("corpus census changed: expected %r, got %r. A new hit is a "
                    "real finding to report, not a number to update."
                    % (EXPECTED_HITS, actual))

# -- 5. the YAML path is untouched --------------------------------------------
# The whole point is parity, so a change that quietly moved the YAML rule while
# adding the XML one would satisfy every check above and still be a regression.
yaml_hits = 0
for path in sorted(glob.glob(os.path.join(ROOT, "examples", "aef-processes",
                                          "*.workflow.yaml"))):
    yaml_hits += len(rule_hits(path, YAML_RULE))
if yaml_hits != 0:
    failures.append("YAML corpus now reports %d %s finding(s); it reported 0 "
                    "before this rule was added, so the YAML path moved"
                    % (yaml_hits, YAML_RULE))

if failures:
    for f in failures:
        print("FAIL: %s" % f)
    sys.exit(1)
print("OK: %s — parity with %s, boundary pinned at exactly one, %d map(s) swept, "
      "1 true positive (AEF's pinned v3, fw_gw_ready), YAML path unmoved"
      % (RULE, YAML_RULE, swept))
