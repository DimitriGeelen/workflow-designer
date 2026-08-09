#!/usr/bin/env python3
"""memory-application-census.py — what proportion of project memory says how to APPLY it (T-411).

THE QUESTION. AEF asked at rail 491, and re-asked at 501, what proportion of our learnings
carry an `application` field. Answering with field presence would have been the misleading
answer: presence is 100%, because NO HUMAN OR AGENT EVER WRITES IT.

    agents/context/lib/learning.sh:100,112   ->  application: TBD
    agents/healing/lib/resolve.sh:133        ->  application: "Apply when encountering
                                                 similar <pattern-slug> issues"

Both emitters fill the field at record-creation time. `fw context add-learning` writes the
literal string TBD; the healing loop writes a template with the pattern slug substituted in.
So every learning is BORN with the field populated, and a consumer counting `'application'
in record` gets 100% coverage of a field nobody has decided anything about.

That is AEF's L-560 pointed inward — *a detector's scope note reads as coverage downstream* —
one level over: a SCHEMA's field presence reads as content downstream. This tool exists so the
number we quote is the one that means something.

THREE CLASSES, and the split is the whole deliverable:

  PLACEHOLDER  literal `TBD`, empty, or null. The field exists and says nothing.
  MACHINE      matches an emitter template. Real text, zero decisions — it is the tool
               talking, not the author. Counting these as coverage is how 2.3% becomes 3.8%.
  AUTHORED     anything else. Someone decided what to do with the learning and wrote it down.

WHY MACHINE IS SPLIT OUT RATHER THAN COUNTED AS CONTENT. The healing template is grammatical,
specific-looking, and carries the pattern name — it reads exactly like an authored line in a
report. It is the same carrier-versus-citation discipline AEF held us to at rail 496 §2:
a count that does not separate the two is not a measurement, it is a total.

THE TEMPLATE PATTERN IS DERIVED FROM THE EMITTER, NOT GUESSED. `--verify-emitters` re-reads
the emitter source and fails if the literal this classifier keys on is no longer there — so
the classifier cannot silently drift into calling machine text authored after someone edits
resolve.sh. It is a small guard against the failure mode where a test and the thing it tests
are two independent copies of the same assumption.

Usage:
  memory-application-census.py                  census, exit 0
  memory-application-census.py --verify-emitters  also check the emitter literals still exist

Exit 0 = census produced over a non-empty population. 2 = vacuity or harness error.
"""
import argparse
import os
import re
import sys

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not available", file=sys.stderr)
    sys.exit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEM = os.path.join(ROOT, ".context", "project")

# Registers, and the top-level key holding the record list. `None` = scan every list value.
REGISTERS = [("learnings.yaml", "learnings"),
             ("decisions.yaml", "decisions"),
             ("patterns.yaml", None)]

# Emitters that populate `application` without anyone deciding anything. Each entry is
# (source path relative to the framework, literal that must still be present, description).
EMITTERS = [
    (".agentic-framework/agents/context/lib/learning.sh",
     "application: TBD", "fw context add-learning writes the placeholder"),
    (".agentic-framework/agents/healing/lib/resolve.sh",
     "Apply when encountering similar", "healing resolve writes a slug template"),
]

PLACEHOLDERS = ("tbd", "n/a", "none", "-", "?")
# The healing template, with the slug left free.
RE_MACHINE = re.compile(r"^apply when encountering similar .* issues$", re.I)


def classify(rec):
    """-> (class, value). Judges the application field only."""
    if "application" not in rec:
        return "ABSENT", None
    v = rec["application"]
    if v is None:
        return "PLACEHOLDER", None
    s = str(v).strip()
    if not s or s.lower() in PLACEHOLDERS:
        return "PLACEHOLDER", s
    if RE_MACHINE.match(s):
        return "MACHINE", s
    return "AUTHORED", s


def records(path, key):
    with open(path, encoding="utf-8") as fh:
        doc = yaml.safe_load(fh) or {}
    if key:
        return [r for r in (doc.get(key) or []) if isinstance(r, dict)]
    out = []
    for v in doc.values():
        if isinstance(v, list):
            out += [r for r in v if isinstance(r, dict)]
    return out


def verify_emitters():
    """Fail loudly if the literals this classifier keys on have moved."""
    bad = []
    for rel, literal, why in EMITTERS:
        p = os.path.join(ROOT, rel)
        if not os.path.exists(p):
            bad.append("%s is missing (%s)" % (rel, why))
            continue
        if literal not in open(p, encoding="utf-8", errors="replace").read():
            bad.append("%s no longer contains %r (%s) — the MACHINE class may now be "
                       "miscounted as AUTHORED" % (rel, literal, why))
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify-emitters", action="store_true")
    args = ap.parse_args()

    if args.verify_emitters:
        bad = verify_emitters()
        if bad:
            print("EMITTER DRIFT:", file=sys.stderr)
            for b in bad:
                print("  " + b, file=sys.stderr)
            return 2
        print("emitters ok: %d literal(s) still present" % len(EMITTERS))

    grand = 0
    authored_rows = []
    for fname, key in REGISTERS:
        path = os.path.join(MEM, fname)
        if not os.path.exists(path):
            print("ERROR: %s missing" % path, file=sys.stderr)
            return 2
        recs = records(path, key)
        grand += len(recs)
        counts = {}
        for r in recs:
            k, v = classify(r)
            counts[k] = counts.get(k, 0) + 1
            if k == "AUTHORED":
                authored_rows.append((fname, r.get("id"), r.get("task"), v))
        n = len(recs) or 1
        print("\n%-16s %4d record(s)" % (fname, len(recs)))
        for k in ("AUTHORED", "MACHINE", "PLACEHOLDER", "ABSENT"):
            if k in counts:
                print("   %-12s %4d  (%5.1f%%)" % (k, counts[k], 100.0 * counts[k] / n))

    # ANTI-VACUITY (PL-084): 0% over zero records reads exactly like a measured result.
    if grand == 0:
        print("\nVACUOUS: project memory holds no records, so any proportion reported here "
              "would be a statement about an empty population.", file=sys.stderr)
        return 2

    print("\nAUTHORED values, verbatim — the claim 'N are real' has to be checkable:")
    if not authored_rows:
        print("  (none)")
    for fname, rid, task, v in authored_rows:
        print("  %s %s (%s):\n    %s" % (fname, rid, task, v))

    print("\npopulation: %d record(s) across %d register(s)" % (grand, len(REGISTERS)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
