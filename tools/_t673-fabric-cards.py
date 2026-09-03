#!/usr/bin/env python3
"""T-673: card the unregistered watch-set files with REAL purposes and DERIVED edges.

The recurring audit warn ("N registered, M unregistered") has fired on 13 consecutive
audits. The mitigation the audit prints is `fw fabric scan`, which registers a stub per
file. THAT IS THE WRONG FIX AND THIS TASK EXISTS BECAUSE IT IS: it would move
`registered` 105 -> 361 while every one of the 256 new stubs landed in the *separate*
"cards have no edges" warn. One number improves, another degrades by the same act, and
the aggregate reads as progress. T-671 built a three-word fence precisely to make that
visible; this is the same discipline applied to the whole watch set instead of 28 files.

So this generator holds the two properties a stub scan cannot:

  purpose is SOURCED   from the file's own docstring / header comment / <title>, via
                       T-671's `sourced_purpose`. A file with no self-description gets
                       a card that SAYS SO, not a plausible sentence. Never "TODO".
  edges are DERIVED    from the referring file's own non-comment bytes, via T-671's
                       extractor, whose comment stripper follows the referring file's
                       LANGUAGE (T-669: mention is not invocation; a `#`-only stripper
                       is silently inert on .mjs/.html and lets false edges through
                       exactly where it cannot reach).

WHY ONE FORWARD PASS OVER EVERYTHING, rather than T-671's forward+reverse pair. T-671
scoped forward to its 28 members and added a reverse pass so their `depended_by` could
see callers outside the set. Ranging over the whole tree, that asymmetry dissolves:
scanning every file forward yields every edge once, and B's `depended_by` is just the
set of A->B edges already found. The reverse pass would re-derive what the forward pass
already has, and two derivations of one fact are two things to keep in agreement.

Edgeless is REPORTED, NEVER PAPERED OVER. A file nothing references and which references
nothing gets an honest empty card and is counted in the summary. Inventing a decorative
edge to clear the edgeless warn would be the same false green in the other direction.

Usage:  _t673-fabric-cards.py [--dry-run] [--report-only]
"""
import importlib.util
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARD_DIR = os.path.join(REPO, ".fabric", "components")
WATCH = os.path.join(REPO, ".fabric", "watch-patterns.yaml")
EXPAND = os.path.join(REPO, ".agentic-framework", "agents", "fabric", "lib",
                      "expand_patterns.py")

SCAN_EXT = (".py", ".sh", ".mjs", ".html")
SUBSYSTEM_BY_DIR = {"tools": "instruments", "tests": "tests",
                    "scripts": "scripts", "src": "product"}


def _load(name, filename):
    """Import a sibling tool whose filename is not a valid Python identifier."""
    spec = importlib.util.spec_from_file_location(
        name, os.path.join(REPO, "tools", filename))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


T671 = _load("t671_derive", "_t671-arc0-edge-derive.py")
GEN = _load("t671_cardgen", "_t671-arc0-card-gen.py")


def watched_paths():
    out = subprocess.run([sys.executable, EXPAND, WATCH, REPO],
                         capture_output=True, text=True, check=True).stdout
    return set(out.split())


def carded_locations():
    """location: values of every existing card, so we never clobber one we did not make."""
    import yaml
    seen = {}
    for f in sorted(os.listdir(CARD_DIR)):
        if not f.endswith(".yaml"):
            continue
        try:
            with open(os.path.join(CARD_DIR, f)) as fh:
                c = yaml.safe_load(fh) or {}
        except Exception:  # noqa: BLE001 - a malformed card is not this task's to fix
            continue
        if c.get("location"):
            seen[c["location"]] = f
    return seen


def derive_all(tracked, uniq):
    """Forward pass over every scanned file. Returns {src: [(target, kind)]}."""
    scan = [p for p in sorted(tracked)
            if p.startswith(("src/", "tools/", "tests/", "scripts/"))
            and os.path.splitext(p)[1] in SCAN_EXT]
    fwd = {}
    for p in scan:
        fp = os.path.join(REPO, p)
        if not os.path.exists(fp):
            continue
        with open(fp, encoding="utf-8", errors="replace") as fh:
            text = fh.read()
        refs = T671.literal_refs(text, tracked, p, uniq) | T671.import_refs(text, tracked, p)
        fwd[p] = sorted((r, T671.KIND_BY_TARGET.get(os.path.splitext(r)[1], "reads"))
                        for r in refs)
    return fwd, scan


def main():
    dry = "--dry-run" in sys.argv
    report_only = "--report-only" in sys.argv

    tracked = T671.tracked_paths()
    uniq = T671.unique_basenames(tracked)
    watched = watched_paths()
    existing = carded_locations()

    fwd, scan = derive_all(tracked, uniq)
    rev = {}
    for s, targets in fwd.items():
        for t, k in targets:
            rev.setdefault(t, []).append((s, k))

    # Target set: watched, unregistered, and reachable by the extractor. A watched file
    # whose extension the extractor cannot read is NOT carded — a card we cannot derive
    # edges for is the stub this task refuses to write.
    todo = sorted(p for p in watched
                  if p not in existing
                  and os.path.splitext(p)[1] in SCAN_EXT
                  and os.path.exists(os.path.join(REPO, p)))
    unreachable = sorted(p for p in watched
                         if p not in existing and os.path.splitext(p)[1] not in SCAN_EXT)

    written, unsourced, edgeless = 0, [], []
    for p in todo:
        purpose = GEN.sourced_purpose(p)
        if purpose is None:
            unsourced.append(p)
            purpose = ("No self-description in the file; purpose recorded as absent "
                       "rather than guessed (T-671 discipline).")
        elif len(purpose) > 400:
            purpose = purpose[:397].rstrip() + "..."

        deps = sorted(set(fwd.get(p, [])))
        rdeps = sorted(set(rev.get(p, [])))
        if not deps and not rdeps:
            edgeless.append(p)

        top = p.split("/")[0]
        lines = [
            f"id: {p}",
            f"name: {os.path.splitext(os.path.basename(p))[0]}",
            f"type: {GEN.TYPE_BY_EXT.get(os.path.splitext(p)[1], 'script')}",
            f"subsystem: {SUBSYSTEM_BY_DIR.get(top, top)}",
            f"location: {p}",
            "tags: [derived]",
            "",
            f"purpose: {GEN.yq(purpose)}",
            "",
            "depends_on:",
        ]
        lines += [x for t, k in deps for x in (f"  - target: {t}", f"    type: {k}")] \
            or ["  []"]
        lines += ["", "depended_by:"]
        lines += [x for s, k in rdeps for x in (f"  - target: {s}", f"    type: {k}")] \
            or ["  []"]
        lines += [
            "",
            "last_verified: 2026-09-03",
            "created_by: T-673",
            "",
            "# Purpose is SOURCED from this file's own header; edges are DERIVED from",
            "# non-comment bytes. Neither is asserted. Regenerate (idempotent) with:",
            "#   python3 tools/_t673-fabric-cards.py",
            "",
        ]
        if not (dry or report_only):
            with open(os.path.join(CARD_DIR, GEN.card_name(p)), "w") as fh:
                fh.write("\n".join(lines))
        written += 1

    verb = "would write" if (dry or report_only) else "wrote"
    print(f"watch set        {len(watched)}")
    print(f"already carded   {len(watched & set(existing))}")
    print(f"{verb:<16} {written}")
    print(f"  sourced purpose  {written - len(unsourced)}")
    print(f"  no self-descr.   {len(unsourced)}  (recorded as absent, never 'TODO')")
    print(f"  edgeless         {len(edgeless)}  (honest: nothing references them and "
          f"they reference nothing)")
    if unreachable:
        print(f"NOT carded       {len(unreachable)} watched file(s) the extractor cannot "
              f"read; a card without derivable edges is the stub this refuses to write")
    print(f"scanned          {len(scan)} file(s) forward")
    return 0


if __name__ == "__main__":
    sys.exit(main())
