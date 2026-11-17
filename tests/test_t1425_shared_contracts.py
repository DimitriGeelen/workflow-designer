#!/usr/bin/env python3
"""T-1425: the current release notes say which of 832's shared-contract artifacts moved, as the tool measures it.

Legs:
  1. the real check: tools/_t1425-shared-contracts.py --check exits 0 on the current notes (2 = NOT CHECKED, a fail);
  2. negative controls on the parser, so the check is shown able to fail (T-560):
     no section; a missing row; a row that says 'no' where the artifact moved; a row that says 'yes' where it did not;
  3. the APP_VERSION line alone does not count as moving the designer page (every release changes it);
  4. the pinned AEF procedure schema still matches its agreed hash prefix where vendored (information that AEF moved
     its side, printed, never a failure: AEF owns those bytes).
"""
import importlib.util
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "tools", "_t1425-shared-contracts.py")


def _tool():
    spec = importlib.util.spec_from_file_location("t1425_shared_contracts", TOOL)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main():
    t = _tool()
    fails = []

    r = subprocess.run([sys.executable, TOOL, "--check"], capture_output=True, text=True)
    print(r.stdout.strip())
    if r.returncode != 0:
        fails.append("the current release notes do not agree with the measured shared-contract moves (rc %d)"
                     % r.returncode)

    rows = [{"n": n, "contract": c, "artifact": "a%d" % n, "moved": n in (2, 3)} for n, c in
            ((1, "P"), (2, "M"), (3, "V"), (4, "R"), (5, "F"))]
    good = "# x\n\n## Shared contracts\n\n" + t.table([dict(r, aef="x", pin=None) for r in rows]) + "\n\n## Next\n"
    if t.disagreements(rows, t.claimed(good)):
        fails.append("control: a correct table was refused: %s" % t.disagreements(rows, t.claimed(good)))
    cases = {
        "no section": good.replace("## Shared contracts", "## Something else"),
        "missing row": "\n".join(l for l in good.splitlines() if not l.startswith("| 4 |")),
        "says no where moved": good.replace("| a2 | yes |", "| a2 | no |"),
        "says yes where not moved": good.replace("| a5 | no |", "| a5 | yes |"),
    }
    for name, text in cases.items():
        if text == good:
            fails.append("control '%s': the fixture edit did not apply" % name)
        elif not t.disagreements(rows, t.claimed(text)):
            fails.append("control '%s': the check passed a wrong table" % name)

    for line, want in (("+const APP_VERSION = '9.9.9';", True), ("-const APP_VERSION = '9.9.8';", True),
                       ("+const OTHER = '1';", False)):
        if bool(t.IGNORED_LINE.match(line)) != want:
            fails.append("APP_VERSION filter wrong on %r" % line)

    # Row 3: the pinned validator-refusal mapping covers our validator's codes and refusal v2's reason_codes exactly.
    rc, lines = t.check_mapping()
    print("\n".join(lines))
    if rc != 0:
        fails.append("row 3 mapping check rc %d" % rc)
    m = {"validator_codes": {"E-A": 1, "W-B": 1}, "reason_codes": {"r1": 1, "r2": 1}}
    if t.mapping_problems(m, {"E-A", "W-B"}, ["r1", "r2"]):
        fails.append("control: an exact mapping was refused")
    for name, codes, reasons in (("new validator code", {"E-A", "W-B", "E-NEW"}, ["r1", "r2"]),
                                 ("retired validator code", {"E-A"}, ["r1", "r2"]),
                                 ("new reason_code", {"E-A", "W-B"}, ["r1", "r2", "r3"]),
                                 ("retired reason_code", {"E-A", "W-B"}, ["r1"])):
        if not t.mapping_problems(m, codes, reasons):
            fails.append("control '%s': the mapping check passed" % name)
    if t.validator_codes("x = 'E-XML-FOO-BAR'; y = \"W-Q\"; z = 'not-a-code'") != {"E-XML-FOO-BAR", "W-Q"}:
        fails.append("validator_codes reads the source wrong")

    # Row 2: pinned mapping and example; our validator passes AEF's example map clean.
    rc2, lines2 = t.check_row2()
    print("\n".join(lines2))
    if rc2 != 0:
        fails.append("row 2 check rc %d" % rc2)
    saved = dict(t.ROW2_FILES)
    t.ROW2_FILES[next(iter(t.ROW2_FILES))] = "0" * 64
    if t.check_row2()[0] == 0:
        fails.append("control: a wrong pin for the row-2 mapping passed")
    t.ROW2_FILES.clear(); t.ROW2_FILES.update(saved)

    for n, name, aef, pin, vendored, mine, paths in t.PAIRS:
        if pin and vendored and os.path.exists(os.path.join(ROOT, vendored)):
            state = "matches" if t.sha(vendored).startswith(pin) else "DIFFERS (AEF moved its side; tell AEF/832)"
            print("info: row %d AEF artifact %s %s pin %s" % (n, os.path.basename(vendored), state, pin))

    for f in fails:
        print("FAIL: " + f)
    print("%s: %d failure(s)" % ("PASS" if not fails else "FAIL", len(fails)))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
