#!/usr/bin/env python3
"""_t936-stray-capture-scan.py — find accidental screen captures written into the tree.

WHAT HAPPENED, THREE TIMES IN SIX DAYS (OBS-448). A `python3 - <<'PY'` heredoc body leaked to the
shell, and its first line — `import yaml,glob,sys`, `import importlib.util` — was resolved not to
Python but to ImageMagick's `import(1)`, which CAPTURES THE SCREEN and writes PostScript named after
the following token. Exit 0. No error. 37MB at the repository root, for six days, unnoticed:

    0                 0 bytes          2026-09-22T22:12Z   (capture interrupted)
    importlib.util    7,962,637 bytes  2026-09-25T11:08Z   1431 x 915   (a window)
    yaml,glob,sys     28,916,814 bytes 2026-09-28T13:29Z   3440 x 1383  (a whole desktop)

The only thing that kept them out of the git index was T-571 — never `git add -A`, stage explicit
paths — which is a convention, not a hook.

WHY CONTENT AND NOT NAME. A check keyed on filename or extension would have missed all three: they
were called `0`, `importlib.util` and `yaml,glob,sys`, no extension between them. Two separate checks
in this corpus were measured today testing LOCATION where they claimed to test substance (C-001's
research artifact, T-919; the ownership field, T-931). This one reads the first bytes.

WHAT IT DELIBERATELY DOES NOT DO. It never opens the raster, renders the image, or describes what is
in it. These are pictures of the operator's screen. The PostScript header is text, bounded and
sufficient — size and canvas are enough to judge exposure, and judging the contents is not the
agent's job. The read is capped at HEADER_BYTES for that reason and not merely for speed.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

# Enough for the %%HiResBoundingBox line, nowhere near the raster. The cap is the privacy boundary.
HEADER_BYTES = 2048

PS_MAGIC = b"%!PS-Adobe"
CAPTURE_CREATORS = (b"ImageMagick", b"GraphicsMagick", b"import")
_BBOX_RE = re.compile(rb"%%HiResBoundingBox:\s*[\d.]+\s+[\d.]+\s+([\d.]+)\s+([\d.]+)")

# Where a capture is ALWAYS a mistake. A .ps or .eps deliberately committed under docs/ is a
# document; one at the repository root, or in a working directory, is an accident.
STRAY_ROOTS = (".", ".context/working", "tools", "docs/reports")

# Directories that legitimately hold PostScript as content rather than accident.
SKIP_DIRS = {".git", "node_modules", "build", "dist", ".venv", "__pycache__",
             "examples", "fixtures", ".editor-versions"}


def _inspect(path):
    """Return a finding dict when the file's first bytes are a screen capture, else None."""
    try:
        with open(path, "rb") as fh:
            head = fh.read(HEADER_BYTES)
    except (OSError, IOError):
        return None
    if not head.startswith(PS_MAGIC):
        return None
    if not any(c in head for c in CAPTURE_CREATORS):
        return None            # PostScript, but not produced by a capture tool

    w = h = None
    m = _BBOX_RE.search(head)
    if m:
        try:
            w, h = int(float(m.group(1))), int(float(m.group(2)))
        except ValueError:
            pass
    try:
        size = os.path.getsize(path)
    except OSError:
        size = -1
    return {"path": path, "bytes": size, "width": w, "height": h,
            "canvas": ("%dx%d" % (w, h)) if w and h else "unknown"}


def scan(root="."):
    findings = []
    for base in STRAY_ROOTS:
        d = os.path.join(root, base)
        if not os.path.isdir(d):
            continue
        for name in sorted(os.listdir(d)):
            p = os.path.join(d, name)
            if not os.path.isfile(p):
                continue
            f = _inspect(p)
            if f:
                f["path"] = os.path.relpath(p, root)
                findings.append(f)
    return findings


def main():
    ap = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[0])
    ap.add_argument("--root", default=".")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--facts", action="store_true",
                    help="one TSV line for the audit rail: count, total bytes, largest canvas")
    args = ap.parse_args()

    f = scan(args.root)

    if args.facts:
        total = sum(x["bytes"] for x in f if x["bytes"] > 0)
        big = max(f, key=lambda x: (x["width"] or 0) * (x["height"] or 0), default=None)
        print("%d\t%d\t%s\t%s" % (len(f), total,
                                  big["canvas"] if big else "-",
                                  ", ".join(x["path"] for x in f[:4]) or "-"))
        return 0

    if args.json:
        print(json.dumps(f, indent=2))
        return 0

    if not f:
        print("no stray screen captures found in: %s" % ", ".join(STRAY_ROOTS))
        return 0
    for x in f:
        print("STRAY CAPTURE  %-24s %10d bytes  canvas %s" % (x["path"], x["bytes"], x["canvas"]))
    print("\n%d finding(s). These are images of the operator's screen — this tool reads the "
          "PostScript header only\nand never the raster. Look at them or delete them; that is "
          "not the agent's call (OBS-448)." % len(f))
    return 1


if __name__ == "__main__":
    sys.exit(main())
