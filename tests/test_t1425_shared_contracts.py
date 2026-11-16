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
