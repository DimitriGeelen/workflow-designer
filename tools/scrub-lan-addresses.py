#!/usr/bin/env python3
"""Replace LAN addresses (192.168.x.y) in 832's own tracked files with placeholders (T-1239).

The GitHub mirror of this repo is public, and 992 tracked files carried estate addresses: handovers, task files,
reports, job files. Operator 2026-10-20: scrub the current files and keep new ones out (no history rewrite).

  .107 -> <dev-host>   .201 -> <git-host>   any other 192.168.x.y -> <lan-host>   (a port after it is kept)

Skipped, and named in the report:
  .agentic-framework/   AEF's vendored code; rewritten here it would diverge and come back on the next upgrade, so
                        AEF scrubs it upstream
  .context/reviews/     append-only ledgers; a rewritten committed row fails the ledger's own integrity check

  python3 tools/scrub-lan-addresses.py --dry-run   # counts per directory, writes nothing
  python3 tools/scrub-lan-addresses.py             # rewrites in place (run by the operator's job: task files may
                                                   # not be shell-written by the agent)
  python3 tools/scrub-lan-addresses.py --stdin     # filter stdin to stdout (the pre-commit gate's rewrite)
Exit 0 = done (or nothing to do); 1 = a file could not be rewritten.
"""
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDR = re.compile(r"\b192\.168\.(\d{1,3})\.(\d{1,3})\b")
SKIP = (".agentic-framework/", ".context/reviews/")
NAMES = {"10.107": "<dev-host>", "10.201": "<git-host>"}


def placeholder(m):
    return NAMES.get("%s.%s" % (m.group(1), m.group(2)), "<lan-host>")


def tracked_with_addresses():
    r = subprocess.run(["git", "grep", "-lIE", r"192\.168\.[0-9]+\.[0-9]+"], cwd=ROOT, capture_output=True, text=True)
    return [p for p in r.stdout.splitlines() if p]


def area(path):
    parts = path.split("/")
    return "/".join(parts[:2]) if parts[0] in (".context", ".tasks", "docs") and len(parts) > 2 else parts[0]


def main():
    if "--stdin" in sys.argv[1:]:   # filter mode, for tools/_t1239-lan-address-gate.sh: stdin -> stdout
        sys.stdout.write(ADDR.sub(placeholder, sys.stdin.read()))
        return 0
    dry = "--dry-run" in sys.argv[1:]
    files, hits, skipped, bad = Counter(), Counter(), Counter(), []
    for rel in tracked_with_addresses():
        if rel.startswith(SKIP):
            skipped[rel.split("/")[0] + ("/reviews" if rel.startswith(".context/reviews/") else "")] += 1
            continue
        p = ROOT / rel
        try:
            text = p.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError) as e:
            bad.append("%s (%s)" % (rel, e.__class__.__name__))
            continue
        new, n = ADDR.subn(placeholder, text)
        if not n:
            continue
        files[area(rel)] += 1
        hits[area(rel)] += n
        if not dry:
            try:
                p.write_text(new, encoding="utf-8")
            except OSError as e:
                bad.append("%s (%s)" % (rel, e))
    print("%s: %d file(s), %d address(es)" % ("would rewrite" if dry else "rewrote", sum(files.values()), sum(hits.values())))
    for a, n in files.most_common():
        print("  %-28s %5d file(s) %7d address(es)" % (a, n, hits[a]))
    for a, n in sorted(skipped.items()):
        print("  SKIPPED %-20s %5d file(s)  (%s)" % (a, n, "AEF's vendored code" if a == ".agentic-framework" else "append-only ledgers"))
    for b in bad:
        print("  COULD NOT REWRITE %s" % b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
