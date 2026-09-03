#!/usr/bin/env python3
"""T-671: write Component Fabric cards for the Arc-0 component set.

Consumes the TSV from `_t671-arc0-edge-derive.py` and writes one card per member of
`arc-0-component-set.txt` into `.fabric/components/`.

Two properties this generator holds that hand-writing 28 cards would not:

  purpose is SOURCED    taken from the file's own module docstring / header comment,
                        never invented. A file with no self-description produces a
                        card that says so explicitly rather than a plausible guess.
  edges are DERIVED     both directions come from the TSV, which came from the bytes.
                        Nothing here adds an edge the scan did not find.

Existing cards are REWRITTEN only for members of the Arc-0 set. Cards outside the set
are never touched: this task's scope is the fence, not the tree.

Usage: _t671-arc0-card-gen.py <edges.tsv>   [--dry-run]
"""
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SET_FILE = os.path.join(REPO, "docs", "research", "executable-workflow",
                        "arc-0-component-set.txt")
CARD_DIR = os.path.join(REPO, ".fabric", "components")

TYPE_BY_EXT = {".py": "script", ".sh": "script", ".mjs": "script", ".html": "app"}

# Purpose overrides, for the case where a file's self-description is an ARTIFACT
# rather than a description. Held here, not hand-edited into the card, so that
# regenerating stays idempotent — an edit made directly to a generated card is
# silently destroyed on the next run, which is how generated files drift.
#
# Each entry must say WHY the sourced text was rejected. "I preferred my wording"
# is not a reason; "the source text is a runtime artifact" is.
PURPOSE_OVERRIDES = {
    # <title> renders as "AEF Workflow Designer — <currently-open document>", so the
    # sourced purpose changes with whatever .bpmn was last loaded when the file was
    # saved. It described a document, not the component.
    "src/aef-workflow-designer.html":
        "The Workflow Designer itself: a single self-contained ~10k-line HTML "
        "application providing the BPMN authoring canvas, the aef extension "
        "vocabulary, stable element IDs, and the import/export round-trip that the "
        "EWCR Arc-0 contract inventory is defined over. Anchor component of the "
        "Arc-0 fence — 112 tracked files reference it and it references none.",
}


def card_name(path):
    """Mirror the existing naming convention: dir-basename, dots dropped."""
    d, b = os.path.split(path)
    return f"{d.replace('/', '-')}-{os.path.splitext(b)[0]}.yaml"


def sourced_purpose(path):
    """First paragraph of the file's own self-description. Never invented."""
    with open(os.path.join(REPO, path), encoding="utf-8", errors="replace") as fh:
        head = fh.read(8000)

    ext = os.path.splitext(path)[1]
    if ext == ".py":
        m = re.search(r'^\s*(?:#![^\n]*\n)?(?:#[^\n]*\n)*\s*"""(.*?)"""', head, re.S)
        if m:
            return " ".join(m.group(1).split())
    if ext in (".sh", ".mjs"):
        lines = []
        for line in head.splitlines():
            if line.startswith("#!"):
                continue
            s = line.strip()
            if s.startswith("#"):
                s = s.lstrip("#").strip()
                if not s:
                    if lines:
                        break
                    continue
                lines.append(s)
            elif s.startswith("//"):
                lines.append(s.lstrip("/").strip())
            elif lines:
                break
        if lines:
            return " ".join(lines)
    if ext == ".html":
        m = re.search(r"<title>(.*?)</title>", head, re.S | re.I)
        if m:
            return " ".join(m.group(1).split())
    return None


def yq(s):
    """Quote a scalar for YAML double-quoted style."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    if len(sys.argv) < 2:
        sys.stderr.write("usage: _t671-arc0-card-gen.py <edges.tsv> [--dry-run]\n")
        return 2
    tsv, dry = sys.argv[1], "--dry-run" in sys.argv

    with open(SET_FILE) as fh:
        members = [ln.strip() for ln in fh
                   if ln.strip() and not ln.lstrip().startswith("#")]

    out_edges, in_edges = {m: [] for m in members}, {m: [] for m in members}
    with open(tsv) as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) != 3:
                continue
            s, t, k = parts
            if s in out_edges:
                out_edges[s].append((t, k))
            if t in in_edges:
                in_edges[t].append((s, k))

    written, unsourced = 0, []
    for m in members:
        purpose = PURPOSE_OVERRIDES.get(m) or sourced_purpose(m)
        if purpose is None:
            unsourced.append(m)
            purpose = ("No self-description in the file; purpose not recorded rather "
                       "than guessed (T-671).")
        elif len(purpose) > 400:
            purpose = purpose[:397].rstrip() + "..."

        lines = [
            f"id: {m}",
            f"name: {os.path.splitext(os.path.basename(m))[0]}",
            f"type: {TYPE_BY_EXT.get(os.path.splitext(m)[1], 'script')}",
            "subsystem: ewcr-arc-0",
            f"location: {m}",
            "tags: [ewcr, arc-0, arc:ewcr-governed-delivery]",
            "",
            f"purpose: {yq(purpose)}",
            "",
            "depends_on:",
        ]
        deps = sorted(set(out_edges[m]))
        if deps:
            for t, k in deps:
                lines += [f"  - target: {t}", f"    type: {k}"]
        else:
            lines.append("  []")
        lines += ["", "depended_by:"]
        rdeps = sorted(set(in_edges[m]))
        if rdeps:
            for s, k in rdeps:
                lines += [f"  - target: {s}", f"    type: {k}"]
        else:
            lines.append("  []")
        lines += [
            "",
            "last_verified: 2026-09-03",
            "created_by: T-671",
            "",
            "# Edges on this card are DERIVED, not asserted: tools/_t671-arc0-edge-derive.py",
            "# extracts them from the referring file's own non-comment bytes. Regenerate with",
            "#   python3 tools/_t671-arc0-edge-derive.py > /tmp/.e.tsv \\",
            "#     && python3 tools/_t671-arc0-card-gen.py /tmp/.e.tsv",
            "",
        ]
        body = "\n".join(lines)
        dest = os.path.join(CARD_DIR, card_name(m))
        if not dry:
            with open(dest, "w") as fh:
                fh.write(body)
        written += 1

    sys.stderr.write(f"{'would write' if dry else 'wrote'} {written} card(s)\n")
    if unsourced:
        sys.stderr.write("no self-description (purpose left explicitly unrecorded): %s\n"
                         % ", ".join(unsourced))
    return 0


if __name__ == "__main__":
    sys.exit(main())
