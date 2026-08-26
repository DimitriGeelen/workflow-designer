#!/usr/bin/env python3
"""T-598 — the source-end direction cue must exist, point forward, and stay smaller.

The load-bearing assertion is orient="auto". The destination markers use
"auto-start-reverse", which is correct for marker-end but would make a marker-start point
BACK at its own source — the exact opposite of the flow cue this is for. A future edit
that "tidies" all four markers to one orientation would silently reverse both source
arrows, and nothing else in the tree would notice.
"""
import re
import sys

SRC = "src/aef-workflow-designer.html"
s = open(SRC, encoding="utf-8").read()

def attrs(mid):
    m = re.search(r'<marker id="%s"([^>]*)>\s*<path[^>]*fill="var\((--[\w-]+)\)"' % re.escape(mid), s)
    if not m:
        print(f"FAIL  marker #{mid} not found"); sys.exit(1)
    a = dict(re.findall(r'(\w+)="([^"]+)"', m.group(1)))
    a["fill"] = m.group(2)
    return a

fail = 0
dst, dsts = attrs("arrow"), attrs("arrow-selected")
src, srcs = attrs("arrow-source"), attrs("arrow-source-selected")

for label, a in (("arrow-source", src), ("arrow-source-selected", srcs)):
    if a.get("orient") != "auto":
        print(f'FAIL  #{label} orient={a.get("orient")!r} — a start marker with '
              f'auto-start-reverse points BACK at the source'); fail = 1
    else:
        print(f"PASS  #{label} orient=auto — points along the path toward the destination")

for label, a, d in (("arrow-source", src, dst), ("arrow-source-selected", srcs, dsts)):
    if int(a["markerWidth"]) >= int(d["markerWidth"]):
        print(f'FAIL  #{label} width {a["markerWidth"]} not smaller than {d["markerWidth"]}'); fail = 1
    else:
        print(f'PASS  #{label} smaller than its destination head ({a["markerWidth"]} < {d["markerWidth"]})')

for label, a, d in (("arrow-source", src, dst), ("arrow-source-selected", srcs, dsts)):
    if a["fill"] != d["fill"]:
        print(f'FAIL  #{label} fill {a["fill"]} != {d["fill"]}'); fail = 1
    else:
        print(f'PASS  #{label} fill matches its destination counterpart ({a["fill"]})')

pair = ("'marker-start': isSelected ? 'url(#arrow-source-selected)' : 'url(#arrow-source)'")
if pair not in s:
    print("FAIL  marker-start is not assigned from the same isSelected ternary"); fail = 1
else:
    print("PASS  marker-start and marker-end switch together on selection")

if s.count("marker-start") != 1:
    print(f"FAIL  expected exactly one marker-start application, found {s.count('marker-start')}"); fail = 1
else:
    print("PASS  exactly one marker-start application")

print("9/9 T-598 source-marker legs passed" if not fail else "T-598 source-marker legs FAILED")
sys.exit(fail)
