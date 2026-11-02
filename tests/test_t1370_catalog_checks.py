#!/usr/bin/env python3
"""T-1370 (T-1363 GO, build B2): the validator checks an io's fields and expectations against the project's field
catalog (contract 832 T-1312), when one is given.

  C1 W-XML-IO-FIELD-UNKNOWN       a fieldRef the catalog has no row for
  C2 W-XML-IO-FIELD-ENTITY        a field of another object than the io's typeRef (a message io is exempt: rule F)
  C3 E-XML-IO-EXPECT-CONTRADICTS  an aef:expect the attribute's own rule forbids (in / pattern / maxLength)
  C4 W-XML-IO-EXPECT-REDUNDANT    an aef:expect that only repeats the attribute's rule (same pattern / same values)

Why: greenfield's own version of C2 found 15 real modelling errors in WT-01 (msg ef1f148e); AEF spec T-4415 C makes a
contradicting expectation an error and a repeating one a warning. All data here is made up.

Legs:
  1-4  each fixture (tests/fixtures/{invalid,warn}/<code>.bpmn) fires its code with its catalog, and none of C1-C4
       without one (no catalog = nothing changes);
  5    C2's exemption: an io typed as something that is no catalog entity (a message carrying several objects);
  6    C3 on an aef:value list and on pattern + maxLength together; a value inside the rule is silent;
  7    C4 on an aef:value list equal to the attribute's allowed values;
  8    a catalog that is not format v1 is refused whole (ValueError), and the CLI exits 2 on it;
  9    the CLI end to end: --field-catalog adds the finding, its absence does not.
Exit 0 = all legs pass.
"""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.environ.get("T1370_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VALIDATOR = os.path.join(ROOT, "tools", "validate-workflow.py")
FIX = os.path.join(ROOT, "tests", "fixtures")
spec = importlib.util.spec_from_file_location("_vw", VALIDATOR)
vw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vw)
NEW = {"W-XML-IO-FIELD-UNKNOWN", "W-XML-IO-FIELD-ENTITY", "E-XML-IO-EXPECT-CONTRADICTS", "W-XML-IO-EXPECT-REDUNDANT"}
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def rules(text, catalog):
    return [f.rule for f in vw.run_xml(text, catalog)]


def catalog_of(code):
    return vw.load_field_catalog(os.path.join(FIX, "catalogs", code + ".json"))


def doc(io_body, typeref="ex:entity-order"):
    """A one-task map whose output carries io_body (same shape as the fixtures)."""
    return open(os.path.join(FIX, "warn", "W-XML-IO-FIELD-UNKNOWN.bpmn"), encoding="utf-8").read() \
        .replace('typeRef="ex:entity-order"', 'typeRef="%s"' % typeref) \
        .replace('<aef:field fieldRef="ex:attr-order-missing" role="write"/>', io_body)


def main():
    cases = [("1", "warn", "W-XML-IO-FIELD-UNKNOWN"), ("2", "warn", "W-XML-IO-FIELD-ENTITY"),
             ("3", "invalid", "E-XML-IO-EXPECT-CONTRADICTS"), ("4", "warn", "W-XML-IO-EXPECT-REDUNDANT")]
    for tag, d, code in cases:
        text = open(os.path.join(FIX, d, code + ".bpmn"), encoding="utf-8").read()
        with_cat, without = rules(text, catalog_of(code)), rules(text, None)
        leg(with_cat.count(code) == 1 and not (NEW & set(without)) and not ((NEW - {code}) & set(with_cat)),
            "%s %s fires once with its catalog, none of C1-C4 without one" % (tag, code), "%s / %s" % (with_cat, without))

    cat = catalog_of("W-XML-IO-FIELD-ENTITY")
    msg = doc('<aef:field fieldRef="ex:attr-order-id" role="write"/><aef:field fieldRef="ex:attr-account-name" role="write"/>',
              typeref="ex:message-order-sync")
    got = rules(msg, cat)
    leg("W-XML-IO-FIELD-ENTITY" not in got, "5 an io typed as a message (no catalog entity) is exempt from C2", str(got))

    c3 = catalog_of("E-XML-IO-EXPECT-CONTRADICTS")
    vals = doc('<aef:field fieldRef="ex:attr-order-status" role="write"/><aef:expect fieldRef="ex:attr-order-status">'
               '<aef:value>Open</aef:value><aef:value>Lost</aef:value></aef:expect>')
    both = doc('<aef:field fieldRef="ex:attr-order-id" role="write"/>'
               '<aef:expect fieldRef="ex:attr-order-id" const="ord-0000000000000000000"/>')
    fine = doc('<aef:field fieldRef="ex:attr-order-status" role="write"/><aef:expect fieldRef="ex:attr-order-status" const="Open"/>')
    f_vals = [f for f in vw.run_xml(vals, c3) if f.rule == "E-XML-IO-EXPECT-CONTRADICTS"]
    f_both = [f for f in vw.run_xml(both, c3) if f.rule == "E-XML-IO-EXPECT-CONTRADICTS"]
    leg(len(f_vals) == 1 and '"Lost"' in f_vals[0].message and len(f_both) == 1
        and "pattern" in f_both[0].message and "maxLength 18" in f_both[0].message
        and "E-XML-IO-EXPECT-CONTRADICTS" not in rules(fine, c3) and f_vals[0].severity == "ERROR",
        "6 C3: an aef:value outside the values; a const failing pattern and maxLength; an allowed const is silent",
        "%s | %s" % ([f.message for f in f_vals], [f.message for f in f_both]))

    red = doc('<aef:field fieldRef="ex:attr-order-status" role="write"/><aef:expect fieldRef="ex:attr-order-status">'
              '<aef:value>Cancelled</aef:value><aef:value>Open</aef:value><aef:value>Complete</aef:value></aef:expect>')
    got = rules(red, c3)
    leg(got.count("W-XML-IO-EXPECT-REDUNDANT") == 1 and "E-XML-IO-EXPECT-CONTRADICTS" not in got,
        "7 C4: an aef:value list equal to the allowed values (any order) is redundant, not a contradiction", str(got))

    with tempfile.TemporaryDirectory() as tmp:
        bad = os.path.join(tmp, "bad.json")
        json.dump({"version": 2, "attributes": []}, open(bad, "w"))
        try:
            vw.load_field_catalog(bad); refused = False
        except ValueError:
            refused = True
        fx = os.path.join(FIX, "invalid", "E-XML-IO-EXPECT-CONTRADICTS.bpmn")
        r = subprocess.run([sys.executable, VALIDATOR, fx, "--field-catalog", bad], capture_output=True, text=True)
        leg(refused and r.returncode == 2 and "not format v1" in r.stderr,
            "8 a catalog that is not format v1 is refused whole; the CLI exits 2", r.stderr.strip()[:200])

        good = os.path.join(FIX, "catalogs", "E-XML-IO-EXPECT-CONTRADICTS.json")
        a = subprocess.run([sys.executable, VALIDATOR, fx, "--field-catalog", good, "--json"], capture_output=True, text=True)
        b = subprocess.run([sys.executable, VALIDATOR, fx, "--json"], capture_output=True, text=True)
        ra = [f["rule"] for f in json.loads(a.stdout)["findings"]]
        rb = [f["rule"] for f in json.loads(b.stdout)["findings"]]
        leg("E-XML-IO-EXPECT-CONTRADICTS" in ra and a.returncode == 2 and not (NEW & set(rb)) and b.returncode != 2,
            "9 CLI: --field-catalog adds the finding (exit 2), without it nothing new", "%s / %s" % (ra, rb))

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
