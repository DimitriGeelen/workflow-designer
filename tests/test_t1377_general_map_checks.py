#!/usr/bin/env python3
"""T-1377 (T-1375 GO, build 2): six general map rules, which a consumer used to check in its own script, as validator
warnings, and --strict, which raises them to errors.

  G1 W-XML-IO-INCOMPLETE            an object io without typeRef, its system (derived as mapping v1.1 says) or operation
  G2 W-XML-IO-MISSING               a step in a system's lane without io, in a map that carries object io elsewhere
  G3 W-XML-GW-BRANCH-UNCONDITIONED  one decision branch with no condition that is not the default (GW-AMBIGUOUS: two+)
  G4 W-XML-DOC-PREFIX               a documentation line with no known prefix, in documentation that uses them
  G5 W-XML-DATA-UNLINKED            a document with no name, or linked to no step
  G6 W-XML-POSITION-DI              aef:position and the DI bounds disagree by more than 0.5

All fixtures are made up (tests/fixtures/warn/<code>.bpmn, valid/t1377-general-map-rules-clean.bpmn,
t1377/strict-no-io.bpmn); none is a consumer's map.

Legs:
  1-6  each fixture fires its code as a WARN, and under strict the same code as an ERROR;
  7    the clean map draws none of the six, strict included;
  8    io-free maps stay silent by default (the corpus's case), and under strict a map with steps and no io at all is one
       W-XML-IO-MISSING on <process>, free-text documentation is checked, both errors;
  9    G1 derives the system: the step's aef:meta default, then the system the typeRef prefix declares;
  10   G2 counts only object io: a map whose only io is v1.0 (name, type, required) stays silent;
  11   G3 stays silent where W-XML-GW-AMBIGUOUS already reports (two unconditioned branches), and on a default branch;
  12   G4 stops at the Notes line; documentation with no prefix at all is silent by default;
  13   G6's tolerance: 0.4 apart is silent, 0.6 apart fires;
  14   strict raises W-XML-GW-AMBIGUOUS too, and leaves every other WARN a WARN;
  15   the CLI end to end: --strict turns exit 1 into exit 2 on a fixture, and is accepted in --help.
Exit 0 = all legs pass.
"""
import importlib.util
import os
import subprocess
import sys

ROOT = os.environ.get("T1377_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")
FIX = os.path.join(ROOT, "tests", "fixtures")
spec = importlib.util.spec_from_file_location("_vw", VALIDATOR)
vw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vw)
NEW = ["W-XML-IO-INCOMPLETE", "W-XML-IO-MISSING", "W-XML-GW-BRANCH-UNCONDITIONED", "W-XML-DOC-PREFIX",
       "W-XML-DATA-UNLINKED", "W-XML-POSITION-DI"]
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def read(rel):
    return open(os.path.join(FIX, rel), encoding="utf-8").read()


def found(text, strict=False):
    return [(f.rule, f.severity, f.location) for f in vw.run_xml(text, None, strict)]


def of(text, code, strict=False):
    return [(s, loc) for r, s, loc in found(text, strict) if r == code]


def main():
    for i, code in enumerate(NEW, 1):
        text = read("warn/%s.bpmn" % code)
        normal, strict = of(text, code), of(text, code, True)
        leg(normal and all(s == "WARN" for s, _ in normal) and strict and all(s == "ERROR" for s, _ in strict)
            and len(normal) == len(strict),
            "%d %s fires as WARN, and as ERROR under strict" % (i, code), "%s / %s" % (normal, strict))

    clean = read("valid/t1377-general-map-rules-clean.bpmn")
    got = [r for r, _, _ in found(clean) + found(clean, True) if r in NEW]
    leg(not got, "7 the clean map draws none of the six, strict included", str(got))

    bare = read("t1377/strict-no-io.bpmn")
    normal = [r for r, _, _ in found(bare) if r in NEW]
    strict = [(r, s, loc) for r, s, loc in found(bare, True) if r in NEW]
    leg(not normal and ("W-XML-IO-MISSING", "ERROR", "<process>") in strict
        and any(r == "W-XML-DOC-PREFIX" and s == "ERROR" for r, s, _ in strict),
        "8 an io-free map is silent by default; strict: no io at all and free-text documentation are errors",
        "%s / %s" % (normal, strict))

    inc = read("warn/W-XML-IO-INCOMPLETE.bpmn")
    by_meta = inc.replace('<aef:output name="ticket" typeRef="Ticket" operation="create"/>',
                          '<aef:output name="ticket" typeRef="Ticket" operation="create"/></aef:io>'
                          '<aef:meta targetSystem="sys:desk"/><aef:io>')
    by_prefix = inc.replace('typeRef="Ticket"', 'typeRef="ex:Ticket"')
    m = [loc for _, loc in of(by_meta, "W-XML-IO-INCOMPLETE")]
    p = [loc for _, loc in of(by_prefix, "W-XML-IO-INCOMPLETE")]
    leg(not any("output" in l for l in m) and not any("output" in l for l in p) and any("input" in l for l in m + p),
        "9 G1 takes the system from the step's aef:meta, else from the typeRef prefix's declared system",
        "%s / %s" % (m, p))

    v1 = read("warn/W-XML-IO-MISSING.bpmn").replace(
        '<aef:input name="order" typeRef="ex:Order" operation="read"><aef:field fieldRef="ex:Order.Number" role="read"/>'
        '</aef:input>', '<aef:input name="order" type="string" required="true"/>')
    leg('typeRef' not in v1.split("<bpmn:serviceTask", 1)[1] and not of(v1, "W-XML-IO-MISSING"),
        "10 G2 counts only object io: a v1.0-only map is silent", str(of(v1, "W-XML-IO-MISSING")))

    br = read("warn/W-XML-GW-BRANCH-UNCONDITIONED.bpmn")
    two = br.replace('<bpmn:conditionExpression>amount &gt; 1000</bpmn:conditionExpression>', '')
    dflt = br.replace('<bpmn:exclusiveGateway id="g" name="Big?"/>',
                      '<bpmn:exclusiveGateway id="g" name="Big?" default="f_small"/>')
    leg(not of(two, "W-XML-GW-BRANCH-UNCONDITIONED") and of(two, "W-XML-GW-AMBIGUOUS")
        and not of(dflt, "W-XML-GW-BRANCH-UNCONDITIONED"),
        "11 G3 leaves two unconditioned branches to GW-AMBIGUOUS, and a default branch alone",
        "%s / %s" % (of(two, "W-XML-GW-BRANCH-UNCONDITIONED"), of(dflt, "W-XML-GW-BRANCH-UNCONDITIONED")))

    dp = read("warn/W-XML-DOC-PREFIX.bpmn")
    msgs = [f.message for f in vw.run_xml(dp) if f.rule == "W-XML-DOC-PREFIX"]
    free = dp.replace("Instruction: check the order\n", "")
    leg(len(msgs) == 1 and "phones the buyer" in msgs[0] and not of(free, "W-XML-DOC-PREFIX"),
        "12 G4 checks up to Notes only; documentation without any prefix is silent by default", str(msgs))

    pd = read("warn/W-XML-POSITION-DI.bpmn")
    near = pd.replace('<aef:position x="200.0" y="60.0"/>', '<aef:position x="200.0" y="40.4"/>')
    far = pd.replace('<aef:position x="200.0" y="60.0"/>', '<aef:position x="200.6" y="40.0"/>')
    leg(not of(near, "W-XML-POSITION-DI") and of(far, "W-XML-POSITION-DI"),
        "13 G6's tolerance: 0.4 apart is silent, 0.6 apart fires")

    s = found(two, True)
    others = [(r, sev) for r, sev, _ in s if r not in vw.XmlValidator.STRICT_RULES and sev == "ERROR"]
    base_errors = [(r, sev) for r, sev, _ in found(two) if sev == "ERROR"]
    leg(any(r == "W-XML-GW-AMBIGUOUS" and sev == "ERROR" for r, sev, _ in s) and others == base_errors,
        "14 strict raises W-XML-GW-AMBIGUOUS too, and no rule outside its list", str(others))

    fx = os.path.join(FIX, "warn", "W-XML-DATA-UNLINKED.bpmn")
    a = subprocess.run([sys.executable, VALIDATOR, fx], capture_output=True, text=True)
    b = subprocess.run([sys.executable, VALIDATOR, fx, "--strict"], capture_output=True, text=True)
    h = subprocess.run([sys.executable, VALIDATOR, "--help"], capture_output=True, text=True)
    leg(a.returncode == 1 and b.returncode == 2 and "--strict" in h.stdout,
        "15 CLI: --strict turns exit 1 into exit 2, and --help lists it", "%d / %d" % (a.returncode, b.returncode))

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
