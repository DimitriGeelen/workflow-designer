#!/usr/bin/env python3
"""_t365-normative-fixture-guard.py — every fixture path the STANDARDS name normatively
must resolve on disk.

T-365. The fixture directory `tests/fixtures/aef-bpmn/` is not an internal detail: it is
named inside the frozen two-party standard (`aef-bpmn-mapping-v1.md`, Part I) and inside
the forward-compile contract (§5, whose heading IS the path). A rename here strands a
reference in a document this project may not edit under agent control.

WHAT THIS GUARDS, AND WHAT IT DELIBERATELY DOES NOT
  It guards the seam contract: a path the standards promise exists, exists. It does NOT
  guard the directory's NAME. The name asserts scope, not authorship — that claim lives
  in PROVENANCE.md and is not mechanically checkable.

WHY IT READS THE STANDARDS RATHER THAN LISTING PATHS
  A guard that hard-codes `inception-gonogo.bpmn` restates the standard instead of
  following it: revise the standard and the guard still passes on the old promise. This
  extracts the paths FROM the documents, so the checked set moves when they move. That
  also means a standard revision which renames the corpus makes this guard demand the
  NEW path — which is the correct direction.

EXIT
  0  every normatively-named fixture path resolves
  1  a named path does not resolve (a rename stranded the standard, or a fixture was
     deleted while the standard still promises it)
  2  cannot answer — no standards found, or none of them names a fixture path. Never
     the same code as "clean": a regex that silently stops matching would otherwise
     report zero findings and read as a pass.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STANDARDS = sorted((ROOT / "docs" / "standards").glob("aef-bpmn-*.md"))

# `tests/fixtures/<dir>/<file>.bpmn` and bare `tests/fixtures/<dir>/` corpus references.
FILE_RE = re.compile(r'tests/fixtures/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+\.bpmn')
DIR_RE = re.compile(r'tests/fixtures/[A-Za-z0-9._-]+/(?:\*\.bpmn|`|\s|$)')

checks = 0
fails = 0


def check(ok: bool, msg: str) -> None:
    global checks, fails
    checks += 1
    if ok:
        print(f"  ok    {msg}")
    else:
        print(f"  FAIL  {msg}", file=sys.stderr)
        fails += 1


if not STANDARDS:
    print("ABSTAINED — no docs/standards/aef-bpmn-*.md found. Cannot answer.",
          file=sys.stderr)
    sys.exit(2)

print("=== T-365: do the fixture paths the standards NAME actually resolve? ===")
for std in STANDARDS:
    text = std.read_text()
    files = sorted(set(FILE_RE.findall(text)))
    dirs = sorted({m.rsplit("/", 1)[0] + "/"
                   for m in re.findall(r'tests/fixtures/[A-Za-z0-9._-]+/\*\.bpmn', text)})
    if not files and not dirs:
        continue
    print(f"\n{std.relative_to(ROOT)}")
    for rel in files:
        p = ROOT / rel
        # Report the Part the reference sits in — a Part I reference is frozen and a
        # break there is a contract break, not an internal inconsistency.
        idx = text.index(rel)
        part2 = text.find("# Part II")
        part = "Part I (FROZEN)" if 0 <= part2 and idx < part2 else "Part II/unpartitioned"
        check(p.is_file(), f"{rel}  [{part}]")
    for rel in dirs:
        p = ROOT / rel
        check(p.is_dir() and any(p.glob("*.bpmn")),
              f"{rel}*.bpmn  (corpus non-empty: "
              f"{len(list(p.glob('*.bpmn'))) if p.is_dir() else 0} files)")

print()
# T-430 abstention guard — a regex that stops matching must not read as clean.
if checks == 0:
    print("ABSTAINED — the standards were read but named NO fixture path. Either the\n"
          "  references were removed, or the extraction stopped matching. This is not a\n"
          "  pass.", file=sys.stderr)
    sys.exit(2)

print(f"  checks={checks} fails={fails}")
if fails:
    print("FAIL — a path the standards promise does not resolve. If this followed a\n"
          "  rename, the rename stranded a two-party contract; revert it or take the\n"
          "  standard delta route (T-365 option D).", file=sys.stderr)
    sys.exit(1)
print("PASS — every normatively-named fixture path resolves.")
