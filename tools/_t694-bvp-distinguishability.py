#!/usr/bin/env python3
"""T-694: measure whether the BVP estimator's output DISTINGUISHES tasks.

The question is not "are the scores right" — that needs a ground truth nobody has.
It is the weaker and answerable one: **does the instrument produce different readings
for different inputs at all?** An instrument that returns the same number regardless
of what you point it at has no discriminating power, and a ranking built from it is
an ordering of ties.

This matters because `fw bvp` sorts the backlog into quadrants (hv-lc / hv-hc /
lv-lc / lv-hc) and the quadrant is what selects work. If most of the backlog shares
one vector, the quadrant boundary is drawn through a cluster of identical points and
which side a task lands on is not a fact about the task.

WHY A TOOL AND NOT A HAND COUNT. The collision was first noticed by eye, scoring
fifteen tasks in a row and seeing the same nine numbers scroll past. Eye-count is
what this measurement exists to replace: it cannot state a denominator, it cannot be
re-run after a change, and it cannot go red.

Usage:
    _t694-bvp-distinguishability.py                    # measure .tasks/active
    _t694-bvp-distinguishability.py --root DIR         # measure a throwaway tree
    _t694-bvp-distinguishability.py --json             # machine-readable

Exit codes: 0 = measured and reported. 2 = could not measure (no tasks, parse error).
Note this tool does NOT exit non-zero on a bad distinguishability ratio. It reports;
it does not judge. Ratifying a threshold is a ranking-semantics decision and belongs
to the operator (T-694 AC 5).
"""
import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

FM = re.compile(r"\A---\n(.*?)\n---\n", re.S)

# The template ships these two pre-filled with a value and an explanatory comment.
# A task that still carries BOTH the value and the comment has not been scored on
# them by anyone — the field is present, so a presence-check passes, while the
# content is the template's own suggestion. (PL-266: a pre-filled required field
# converts a gate for presence into a gate that cannot fail.)
TEMPLATE_DEFAULTS = {
    "voi_score": "0.5",
    "target_blast_radius": "3",
}


def _frontmatter(text):
    m = FM.match(text)
    return m.group(1) if m else ""


def _latest_proposed_vector(fm_text):
    """Return the most recent bvp_scores_proposed vector as a canonical tuple.

    Parsed with a line scanner rather than a YAML load on purpose: several task files
    in this tree carry frontmatter that a strict loader rejects (unquoted colons in
    names), and this measurement must cover the whole population including those.
    A parse that skips the awkward files would understate the denominator, which is
    the one direction of error that would make the finding look smaller than it is.
    """
    entries = []
    in_block = False
    cur = None
    in_scores = False
    for raw in fm_text.split("\n"):
        if re.match(r"^bvp_scores_proposed:\s*$", raw):
            in_block = True
            continue
        if in_block:
            # A new top-level key ends the block.
            if raw and not raw[0].isspace() and not raw.startswith("#"):
                in_block = False
                if cur:
                    entries.append(cur)
                    cur = None
                continue
            if re.match(r"^\s{2}-\s", raw):
                if cur:
                    entries.append(cur)
                cur = {}
                in_scores = False
            m = re.match(r"^\s+scores:\s*$", raw)
            if m:
                in_scores = True
                continue
            if in_scores:
                ms = re.match(r"^\s+([A-Za-z0-9_-]+):\s*(-?\d+)\s*$", raw)
                if ms and cur is not None:
                    cur[ms.group(1)] = int(ms.group(2))
                elif raw.strip() and not raw.strip().startswith("#"):
                    # left the scores mapping (rationale:, rubric_sha:, ts:, …)
                    if not re.match(r"^\s+[A-Za-z0-9_-]+:\s*$", raw):
                        in_scores = False
    if cur:
        entries.append(cur)
    if not entries:
        return None
    last = entries[-1]
    if not last:
        return None
    return tuple(sorted(last.items()))


def _field(fm_text, key):
    m = re.search(rf"^{re.escape(key)}:\s*(\S+)", fm_text, re.M)
    return m.group(1) if m else None


def _still_template_default(fm_text, key):
    """True when the field carries the template's value AND its explanatory comment."""
    m = re.search(rf"^{re.escape(key)}:\s*(\S+)\s*(#.*)?$", fm_text, re.M)
    if not m:
        return None  # field absent entirely — a different state, not a default
    value, comment = m.group(1), m.group(2)
    return value == TEMPLATE_DEFAULTS[key] and bool(comment)


def measure(root: Path):
    tasks = sorted(root.glob("*.md"))
    rows = []
    for p in tasks:
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError as e:
            print(f"WARN: unreadable {p.name}: {e}", file=sys.stderr)
            continue
        fm = _frontmatter(text)
        if not fm:
            continue
        tid = _field(fm, "id") or p.stem
        rows.append({
            "id": tid,
            "type": _field(fm, "workflow_type"),
            "vector": _latest_proposed_vector(fm),
            "voi_default": _still_template_default(fm, "voi_score"),
            "tbr_default": _still_template_default(fm, "target_blast_radius"),
        })
    return rows


def self_test():
    """Watch the instrument report BOTH verdicts before trusting either.

    A distinguishability meter that has only ever printed 'they are the same' has
    not been shown to be able to print anything else. This plants one deliberately
    distinct vector into a throwaway tree and requires the distinct count to rise by
    exactly one — not merely to change, and not merely to be greater.

    Runs entirely under a TemporaryDirectory: no ledger, fixture or baseline in the
    repository is written to (T-694 §4).
    """
    import tempfile

    body = (
        "---\n"
        "id: {tid}\n"
        "workflow_type: build\n"
        "bvp_scores_proposed:\n"
        "  - ts: '2026-01-01T00:00:00Z'\n"
        "    estimator: self-test\n"
        "    scores:\n"
        "{scores}"
        "    rubric_sha: deadbeef\n"
        "---\n\n# body\n"
    )

    def write(d, tid, vec):
        sc = "".join(f"      {k}: {v}\n" for k, v in vec)
        (d / f"{tid}-selftest.md").write_text(body.format(tid=tid, scores=sc))

    same = (("D1", 4), ("D2", 0), ("D3", 2))
    diff = (("D1", 5), ("D2", 0), ("D3", 5))

    failures = []
    with tempfile.TemporaryDirectory() as td:
        d = Path(td)
        for tid in ("T-901", "T-902", "T-903"):
            write(d, tid, same)
        before = measure(d)
        n_before = len({r["vector"] for r in before if r["vector"]})
        if n_before != 1:
            failures.append(f"baseline: expected 1 distinct vector, got {n_before}")

        write(d, "T-904", diff)
        after = measure(d)
        n_after = len({r["vector"] for r in after if r["vector"]})
        if n_after != n_before + 1:
            failures.append(
                f"planted control: expected {n_before + 1} distinct, got {n_after} "
                "— the instrument cannot see a difference it was handed")

        # And the converse: a task with NO proposed vector must not be counted as
        # scored. Otherwise the denominator silently inflates and every ratio moves.
        (d / "T-905-unscored.md").write_text("---\nid: T-905\nworkflow_type: build\n---\n")
        rows = measure(d)
        if len([r for r in rows if r["vector"]]) != 4:
            failures.append("an unscored task was counted in the scored denominator")

    for f in failures:
        print(f"SELF-TEST FAIL: {f}", file=sys.stderr)
    if failures:
        return 1
    print("SELF-TEST PASS: 3 checks — baseline tie, planted distinct (+1), "
          "unscored excluded from denominator")
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".tasks/active")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--self-test", action="store_true",
                    help="prove the instrument can report DISTINGUISHABLE, not just tied")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = Path(args.root)
    if not root.is_dir():
        print(f"ERROR: not a directory: {root}", file=sys.stderr)
        return 2

    rows = measure(root)
    if not rows:
        print(f"ERROR: no task files with frontmatter under {root}", file=sys.stderr)
        return 2

    scored = [r for r in rows if r["vector"]]
    vectors = Counter(r["vector"] for r in scored)
    distinct = len(vectors)

    inceptions = [r for r in rows if r["type"] == "inception"]
    voi_defaulted = [r for r in inceptions if r["voi_default"]]
    tbr_defaulted = [r for r in inceptions if r["tbr_default"]]

    result = {
        "root": str(root),
        "tasks_total": len(rows),
        "tasks_scored": len(scored),
        "distinct_vectors": distinct,
        "modal_vector_count": vectors.most_common(1)[0][1] if vectors else 0,
        "modal_vector": dict(vectors.most_common(1)[0][0]) if vectors else {},
        "inceptions_total": len(inceptions),
        "inceptions_voi_still_template_default": len(voi_defaulted),
        "inceptions_tbr_still_template_default": len(tbr_defaulted),
        "top_vectors": [
            {"count": c, "vector": dict(v)} for v, c in vectors.most_common(5)
        ],
    }

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0

    print(f"=== BVP distinguishability — {root} ===")
    print(f"tasks with frontmatter        : {result['tasks_total']}")
    print(f"tasks carrying a proposed vec : {result['tasks_scored']}")
    print(f"DISTINCT vectors among them   : {distinct}")
    if scored:
        share = 100.0 * result["modal_vector_count"] / len(scored)
        print(f"modal vector covers           : {result['modal_vector_count']} "
              f"task(s) ({share:.1f}% of scored)")
    print()
    print("top vectors by task count:")
    for v, c in vectors.most_common(5):
        compact = " ".join(f"{k}={n}" for k, n in v)
        print(f"  {c:>3}x  {compact}")
    print()
    print("--- inception value inputs (the composite's own operands) ---")
    print(f"inception tasks                        : {len(inceptions)}")
    print(f"  voi_score still template default     : {len(voi_defaulted)}")
    print(f"  target_blast_radius still default    : {len(tbr_defaulted)}")
    print()
    print("Reported, not judged: no threshold is asserted here. See T-694 AC 5.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
