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
  python3 tools/scrub-lan-addresses.py             # stages the scrubbed COMMITTED content of each file and scrubs
                                                   # its worktree copy (run by the operator's job: task files may
                                                   # not be shell-written by the agent); then commit the index
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
    """Paths whose COMMITTED content (HEAD) carries an address. The working tree is not the source: it can hold
    unrelated uncommitted edits, which this tool must neither commit nor lose."""
    r = subprocess.run(["git", "grep", "-lIE", r"192\.168\.[0-9]+\.[0-9]+", "HEAD"], cwd=ROOT, capture_output=True, text=True)
    return [p.split(":", 1)[1] for p in r.stdout.splitlines() if ":" in p]


def git(*args, data=None):
    return subprocess.run(["git", *args], cwd=ROOT, input=data, capture_output=True, check=True).stdout


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
        try:
            text = git("show", "HEAD:" + rel).decode("utf-8")
        except (UnicodeDecodeError, subprocess.CalledProcessError) as e:
            bad.append("%s (%s)" % (rel, e.__class__.__name__))
            continue
        new, n = ADDR.subn(placeholder, text)
        if not n:
            continue
        files[area(rel)] += 1
        hits[area(rel)] += n
        if dry:
            continue
        try:
            # The index gets the scrubbed COMMITTED content, so the commit holds the scrub and nothing else; the
            # worktree copy is scrubbed in place, keeping any unrelated uncommitted edit uncommitted.
            mode = git("ls-files", "-s", "--", rel).decode().split()[0]
            blob = git("hash-object", "-w", "--stdin", data=new.encode("utf-8")).decode().strip()
            git("update-index", "--cacheinfo", "%s,%s,%s" % (mode, blob, rel))
            p = ROOT / rel
            if p.is_file():
                p.write_text(ADDR.sub(placeholder, p.read_text(encoding="utf-8")), encoding="utf-8")
        except (subprocess.CalledProcessError, OSError, UnicodeDecodeError, IndexError) as e:
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
