#!/usr/bin/env python3
"""T-1315: the host-contract notes check reads the NEWEST release notes at or above VERSION.

VERSION moves only inside the release job, so between releases the source can already call an endpoint AEF does not
serve (T-1312: /api/field-catalog) while VERSION still names the last, published release. The check read only
RELEASE-NOTES-<VERSION>.md and so demanded that the published notes name an endpoint that release does not use. It now
reads the next release's notes once they are drafted. Fixture notes dirs, never docs/releases:
  1. a newer notes file naming the endpoint                 -> chosen, nothing unnamed
  2. a newer notes file not naming it                       -> chosen, the endpoint unnamed (the guard still bites)
  3. only VERSION's notes, not naming it                    -> VERSION's chosen, unnamed (today's guard kept)
  4. a LOWER version's notes are never read; semver order (0.30.0 beats 0.4.0, 0.29.0)
  5. no notes for VERSION or above                          -> None (the check fails "no release notes")
Exit 0 = all passed.
"""
import importlib.util
import os
import shutil
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("t1289notes", os.path.join(ROOT, "tests", "test_t1289_host_contract_notes.py"))
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
results = []


def check(name, ok, detail=""):
    results.append(ok)
    print(("PASS  " if ok else "FAIL  ") + name + ("" if ok else "\n      %s" % detail))


def fixture(files):
    d = tempfile.mkdtemp(prefix="t1315-")
    for v, text in files.items():
        with open(os.path.join(d, "RELEASE-NOTES-%s.md" % v), "w") as f:
            f.write(text)
    return d


def pick(files, version):
    d = fixture(files)
    try:
        p = getattr(mod, "notes_file", None)
        return os.path.basename(p(d, version)) if p and p(d, version) else (None if p else "NO notes_file()")
    finally:
        shutil.rmtree(d, ignore_errors=True)


def main():
    EP = "/api/field-catalog"
    old, named, unnamed_ = "| /api/validate |", "| /api/validate |\n| %s |" % EP, "| /api/validate |"
    got = pick({"0.29.0": old, "0.30.0": named}, "0.29.0")
    check("1 a newer notes file is chosen", got == "RELEASE-NOTES-0.30.0.md", got)
    check("1 ... and names the endpoint", EP in named and not mod.unnamed([EP], named), "")
    got = pick({"0.29.0": old, "0.30.0": unnamed_}, "0.29.0")
    check("2 a newer file not naming it is still the one checked (guard bites)",
          got == "RELEASE-NOTES-0.30.0.md" and mod.unnamed([EP], unnamed_) == [EP], got)
    got = pick({"0.29.0": old}, "0.29.0")
    check("3 only VERSION's notes: VERSION's are checked", got == "RELEASE-NOTES-0.29.0.md", got)
    got = pick({"0.28.0": named, "0.29.0": old, "0.4.0": named, "0.30.0": unnamed_}, "0.29.0")
    check("4 lower versions never read; semver order (0.30.0 > 0.29.0 > 0.4.0)", got == "RELEASE-NOTES-0.30.0.md", got)
    got = pick({"0.28.0": named}, "0.29.0")
    check("5 nothing at or above VERSION -> None", got is None, got)
    print("\nT-1315 notes pick: %d/%d passed" % (sum(results), len(results)))
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
