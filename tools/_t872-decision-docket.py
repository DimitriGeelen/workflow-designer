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

# T-933: what KIND of answer the item wants. The `class:` above says why the item is the operator's;
# this says what answering it involves, which is a different question and the one that decides whether
# a sitting can batch it. A ruling needs a position taken; a review needs something looked at; a
# checkable item needs neither and should not be here at all.
#
# DERIVED FROM THE `Expected:` CLAUSE, NOT THE STEPS. An earlier attempt at this classification (under
# T-932) tested the criterion's whole body and flagged 21 items as mechanically delegable — including
# "May five OMG schema files be vendored" and "Whether to take the vendor bump now". Their STEPS
# contain grep commands, because that is how the operator is told to look at the evidence. The verdict
# is sovereign. That regex would have handed 21 rulings to a reviewer, which is precisely the
# relocated authority PD-302 forbids. The Expected clause is what CLAUDE.md specifies and the only
# field that speaks to the verdict.
RULING_RE = re.compile(
    r"\b(decide|decision|ruling|rule on|approve|approval|choose|whether to|go/no-go|"
    r"sign off|accept|you agree|recorded against)\b", re.I)
MECHANICAL_RE = re.compile(
    r"exit(s)? (code )?[0-9]|\bPASS\b|\bFAIL\b|returns 0|non-zero|status [0-9]{3}|"
    r"no findings|\b[0-9]+/[0-9]+\b|prints |contains ", re.I)

# An ACT the operator must perform. A scanner can verify the OUTCOME and cannot perform the ACT, so a
# checkable Expected clause says nothing about delegability here. This is `[RUBBER-STAMP]` semantics
# generalised: "publish", "tick", "set", "apply" are things only a person with the authority does.
#
# ADDED BECAUSE THE CLASSIFIER GOT T-732 WRONG. Writing that criterion a proper Expected clause
# ("prints `True False`") immediately made the item read CHECKABLE — my own improvement flipped an
# operator act into a delegable check, because the outcome became verifiable. The act did not change:
# it still asks the operator to tick a Human AC and set `definition_ratified:` in a file the agent is
# forbidden to write. Verifiable outcome, undelegable act.
ACT_RE = re.compile(
    r"\b(tick|set |apply|publish|deploy|record the|delete|remove|install|click|sign|"
    r"merge|push|bump|approve and|reassign|create the)\b", re.I)

KIND_NOTE = {
    "RULING":      "take a position — nothing can be looked up to settle it",
    "ACT":         "do something only you may do — a scanner can confirm it afterwards, not perform it",
    "REVIEW":      "look at something and judge it",
    "CHECKABLE":   "**mechanically checkable — should not be on this docket**; convert per item with `fw task delegate`",
    "UNSPECIFIED": "the criterion does not say what answering it looks like — that is the first thing to fix",
}


# A class that names an INTRINSIC reason the item is the operator's. delegation.py is authoritative
# about these under PD-302 — "an exception the agent adjudicates per case is relocated authority, not
# delegated authority" — so no heuristic here may call such an item mechanically checkable, whatever
# its Expected clause says.
#
# THIS GUARD EXISTS BECAUSE THE FIRST VERSION DID NOT HAVE IT, and it was wrong on both items it
# flagged. T-596's Expected clause says "the gate exits non-zero and prints BLOCKED", which matched
# MECHANICAL_RE — but the criterion is an `inception-decision` asking for a go/no-go, and
# `fw task delegate` refused it: "stays human". T-586 is `[RUBBER-STAMP]` + `tier0-or-bypass`, an
# act-in-the-world on .claude/settings.json that the agent is structurally blocked from performing at
# all (B-005). Two false positives out of 79, both caught by the sanctioned verb rather than by me.
INTRINSIC_CLASSES = {"inception-decision", "sovereignty-field", "tier0-or-bypass",
                     "render-surface", "taste", "release-surface", "act-in-the-world"}


def answer_kind(title, expected, cls=""):
    """What answering this involves. Order matters, and the classifier outranks the regex.

    1. An intrinsic class means the item is the operator's for a reason the predicate established.
       It can still be a RULING or a REVIEW, but never CHECKABLE.
    2. A ruling dressed in a mechanical Expected clause is still a ruling.
    3. Only then may an Expected clause earn CHECKABLE — and only where no intrinsic class was found.
    """
    intrinsic = cls in INTRINSIC_CLASSES
    if RULING_RE.search(title) or RULING_RE.search(expected or ""):
        return "RULING"
    if cls == "inception-decision":
        return "RULING"          # a go/no-go is a position taken, whatever the wording
    if ACT_RE.search(title) or cls == "act-in-the-world":
        return "ACT"             # verifiable outcome, undelegable act
    if not (expected or "").strip():
        return "UNSPECIFIED"
    if MECHANICAL_RE.search(expected) and not intrinsic:
        return "CHECKABLE"
    return "REVIEW"


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
                "kind": answer_kind(" ".join(c.title.split()),
                                    " ".join((c.expected or "").split()),
                                    cl.cls),
            })

    entries.sort(key=lambda e: (-e["score"], e["task"]))
    from pathlib import Path
    surface = d.surface_scan(Path(ROOT))
    reported = surface.get("by_delegation", {}).get(d.OPERATOR_ONLY, "?")

    # The SECOND encoding. Read through a subprocess rather than imported, because it is a separate
    # implementation and the point is to compare it, not to share code with it. A failure to read it
    # leaves b_oo None and the docket SAYS so — never silently reports agreement it did not check.
    b_oo = None
    try:
        import json as _json
        import subprocess as _sp
        _r = _sp.run([sys.executable, os.path.join(ROOT, "tools", "_t770-delegation-boundary.py"),
                      "--json"], capture_output=True, text=True, timeout=120, cwd=ROOT)
        if _r.returncode == 0 and _r.stdout.strip():
            _rows = _json.loads(_r.stdout)
            b_oo = sum(1 for r in _rows
                       if r.get("section") == "Human" and r.get("bucket") == "OPERATOR-ONLY")
    except Exception:
        b_oo = None

    print("# Operator decision docket\n")
    print("**Generated** — do not hand-edit. Regenerate with:\n")
    print("```\npython3 tools/_t872-decision-docket.py > docs/reports/operator-decision-docket.md\n```\n")
    print(f"**{len(entries)} open decisions** across "
          f"{len({e['task'] for e in entries})} tasks.\n")
    print("This does **not** reduce the backlog — the count is unchanged. It removes the")
    print("gathering cost: answering these otherwise means opening ~69 task files and")
    print("reconstructing each context. Ordered by what each one releases.\n")
    # What kind of answer each item wants — the number that decides whether a sitting can batch them.
    from collections import Counter
    kc = Counter(e["kind"] for e in entries)
    print("**What these actually ask for**\n")
    print("| kind | count | what answering involves |")
    print("|---|---|---|")
    # Iterate the NOTES, not a hand-typed tuple. An earlier version listed the kinds inline, a fifth
    # kind (ACT) was added to the classifier and not to that list, and 4 items silently vanished from
    # a table that still claimed 79 above it. The table is now self-checking: any kind the classifier
    # can emit has a note, and the counts are asserted to sum.
    for k in KIND_NOTE:
        if kc[k]:
            print(f"| `{k}` | {kc[k]} | {KIND_NOTE[k]} |")
    _unnoted = sorted(set(kc) - set(KIND_NOTE))
    if _unnoted:
        print(f"| **UNNOTED** | {sum(kc[k] for k in _unnoted)} | "
              f"**classifier emitted {', '.join(_unnoted)} with no note — the table is incomplete** |")
    if sum(kc.values()) != len(entries):
        print(f"| **MISCOUNT** | — | **kinds sum to {sum(kc.values())} but there are "
              f"{len(entries)} items — do not trust this table** |")
    print()
    print("The dominant kind is what makes this backlog what it is. Rulings cannot be delegated to a")
    print("reviewer, converted by a classifier, or discharged by running anything — someone has to take")
    print("a position. Measured twice independently (T-872 on 2026-09-26, T-932 on 2026-09-29) with the")
    print("same result, the second time after wrongly assuming the opposite.\n")

    print("**Reconciliation, against BOTH encodings of the boundary**\n")
    print(f"- `fw reviewer surface` (the path that ENFORCES) reports operator-only {reported}; "
          f"this docket lists {len(entries)}. "
          + ("Counts agree." if str(reported) == str(len(entries))
             else "**Counts differ — investigate before trusting either.**"))
    if b_oo is None:
        print("- `tools/_t770-delegation-boundary.py` (the path that REPORTS) could not be read, so its"
              " agreement is UNKNOWN — not assumed. Run `bash tools/_t932-boundary-agreement.sh`.")
    else:
        print(f"- `tools/_t770-delegation-boundary.py` (the path that REPORTS) classifies {b_oo} open"
              " Human criteria as operator-only"
              + (". Both encodings agree." if b_oo == len(entries) else
                 f", i.e. {abs(b_oo - len(entries))} more than this docket lists. The two encodings of"
                 " one ruling disagree (G-052); this docket follows the enforcing path and does not"
                 " pick a winner. `bash tools/_t932-boundary-agreement.sh` for the breakdown."))
    print("\nReconciling against one encoding and printing \"counts agree\" would assert an agreement"
          " nobody checked — which is what this docket did until 2026-09-29.\n")
    print("---\n")

    for i, e in enumerate(entries, 1):
        arcs = ", ".join(sorted(e["arcs"])) or "no arc"
        flag = " **[product arc]**" if e["arcs"] & PRODUCT_ARCS else ""
        print(f"## {i}. {e['task']} — {e['name'][:88]}")
        print(f"*{arcs}{flag} · class: `{e['cls']}` — {CLASS_NOTE.get(e['cls'], '')} "
              f"· unblock score {e['score']}*")
        print(f"*wants: `{e['kind']}` — {KIND_NOTE[e['kind']]}*\n")
        print(f"**Asks:** {e['title']}\n")
        if e["expected"]:
            print(f"**Expected:** {e['expected']}\n")
        else:
            print("**Expected:** *(none stated — the criterion does not say what "
                  "answering it looks like)*\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
