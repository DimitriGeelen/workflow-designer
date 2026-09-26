#!/usr/bin/env python3
"""T-872 — generate one ordered docket of every open operator decision.

WHY THIS EXISTS, and what it deliberately does NOT do.

The operator-only queue has now been measured twice and is not what it looks
like. It is not rubber-stamping: only 6 of 83 open Human criteria were ever
`[RUBBER-STAMP]`. It is not misfiled: of the 38 the classifier leaves
`unclassified`, exactly ONE lacks an `Expected:` clause — the rest have one and
it says things like "a decision recorded against T-209", "you agree the semantic
should outrank the geometry", "one of A / B / C recorded as a decision". They are
requests for rulings, and `delegation.py` is right to leave them human.

So no classifier change reaches them, and `fw task delegate` is already saturated
at reviewer-closeable 0. What remains is 77 genuine decisions spread across 69
task files.

THE COST IS THE GATHERING, NOT THE DECIDING. Answering these today means opening
69 files and reconstructing each context. This collapses that into one document.

IT DOES NOT REDUCE THE BACKLOG, and saying so is part of the job: the count is
unchanged, only its cost of access moves. An earlier task here measured the same
population, found a median AC age of 42 days, and concluded that agents generate
these faster than any human issues them — "we are asking too much, and that is
ours to fix rather than theirs". A docket does not fix that. It makes the size of
it legible while the real remedy is decided.

REGENERATE, never hand-edit:
    python3 tools/_t872-decision-docket.py > docs/reports/operator-decision-docket.md

A hand-kept summary of a moving corpus is stale the day after it is written, and
stale in the direction that looks authoritative.
"""

import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, ".agentic-framework", "lib"))
import delegation as d  # noqa: E402

# Arcs whose completion is the project's stated objective, as against framework
# upkeep. A decision that unblocks product work is worth answering before one
# that unblocks housekeeping, and that is a ranking input rather than a verdict.
PRODUCT_ARCS = {"designer-authoring-surface", "ewcr-governed-delivery",
                "arc-001", "arc-002"}

CLASS_NOTE = {
    "inception-decision": "a go/no-go on an exploration — nothing else can settle it",
    "sovereignty-field":  "writes a field whose whole point is that a human set it",
    "tier0-or-bypass":    "the tier the operator owns by definition",
    "render-surface":     "no test settles layout (T-1766)",
    "taste":              "genuine judgement — tone, feel, wording",
    "unclassified":       "asks for a ruling; no deterministic signal to delegate on",
}


def load():
    tasks = {}
    for f in sorted(glob.glob(os.path.join(ROOT, ".tasks", "active", "*.md"))):
        txt = open(f, encoding="utf-8").read()
        fm = d.frontmatter(txt)
        tid = fm.get("id")
        if not tid:
            continue
        tasks[tid] = {"fm": fm, "txt": txt, "path": f}
    return tasks


def unblock_score(tid, tasks, arcs):
    """How much answering this releases. Heuristic, and stated as one.

    Two inputs, both cheap and both defensible: how many other live tasks name
    this one (a decision nothing depends on is worth less than one several
    things wait behind), and whether it sits in a product arc.
    """
    refs = 0
    for other, t in tasks.items():
        if other == tid:
            continue
        if re.search(rf"\b{re.escape(tid)}\b", t["txt"]):
            refs += 1
    return refs * 2 + (5 if arcs & PRODUCT_ARCS else 0)


def main():
    tasks = load()
    entries = []
    for tid, t in tasks.items():
        fm, txt = t["fm"], t["txt"]
        wt = str(fm.get("workflow_type") or "")
        arcs = set()
        if fm.get("arc_id"):
            arcs.add(str(fm["arc_id"]))
        for tg in (fm.get("tags") or []):
            if isinstance(tg, str) and tg.startswith("arc:"):
                arcs.add(tg[4:])
        for c in d.human_criteria(txt):
            if c.ticked:
                continue
            cl = d.classify(c, workflow_type=wt)
            if cl.delegation_class != d.OPERATOR_ONLY:
                continue
            entries.append({
                "task": tid, "cls": cl.cls, "arcs": arcs,
                "title": " ".join(c.title.split()),
                "expected": " ".join((c.expected or "").split()),
                "score": unblock_score(tid, tasks, arcs),
                "name": " ".join(str(fm.get("name") or "").split()),
            })

    entries.sort(key=lambda e: (-e["score"], e["task"]))
    from pathlib import Path
    surface = d.surface_scan(Path(ROOT))
    reported = surface.get("by_delegation", {}).get(d.OPERATOR_ONLY, "?")

    print("# Operator decision docket\n")
    print("**Generated** — do not hand-edit. Regenerate with:\n")
    print("```\npython3 tools/_t872-decision-docket.py > docs/reports/operator-decision-docket.md\n```\n")
    print(f"**{len(entries)} open decisions** across "
          f"{len({e['task'] for e in entries})} tasks.\n")
    print("This does **not** reduce the backlog — the count is unchanged. It removes the")
    print("gathering cost: answering these otherwise means opening ~69 task files and")
    print("reconstructing each context. Ordered by what each one releases.\n")
    print("Reconciliation against `fw reviewer surface`: "
          f"docket {len(entries)}, surface reports operator-only {reported}. "
          + ("Counts agree.\n" if str(reported) == str(len(entries))
             else "**Counts differ — investigate before trusting either.**\n"))
    print("---\n")

    for i, e in enumerate(entries, 1):
        arcs = ", ".join(sorted(e["arcs"])) or "no arc"
        flag = " **[product arc]**" if e["arcs"] & PRODUCT_ARCS else ""
        print(f"## {i}. {e['task']} — {e['name'][:88]}")
        print(f"*{arcs}{flag} · class: `{e['cls']}` — {CLASS_NOTE.get(e['cls'], '')} "
              f"· unblock score {e['score']}*\n")
        print(f"**Asks:** {e['title']}\n")
        if e["expected"]:
            print(f"**Expected:** {e['expected']}\n")
        else:
            print("**Expected:** *(none stated — the criterion does not say what "
                  "answering it looks like)*\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
