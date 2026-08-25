#!/usr/bin/env python3
"""T-585 — census of Human ACs that exist in a task file but are invisible to the queue.

THE DEFECT. `/approvals` and `fw review-queue` both decide "does this task need the
operator?" by calling `count_unchecked_human_acs` (web/shared.py). That predicate
anchors on `^## Acceptance Criteria\\s*$` and scopes `### Human` to the block it opens.
An unchecked Human AC written anywhere else returns 0 — the same value a task with no
Human ACs returns. T-344 sat that way for weeks: a real unchecked `[REVIEW]` under
`## Measurements`, and both surfaces silently agreed there was nothing to decide.

WHY NO EXISTING CHECK CATCHES IT. The observable of this failure is an EMPTY QUEUE, and
an empty queue is also the observable of a healthy one. There is no red state to notice.
The operator found T-344 by complaining that the page showed nothing; no instrument was
involved. T-2075 centralised the predicate to stop `/approvals` and the CLI drifting
apart — which worked, and made them agree on the wrong answer. A shared predicate makes
two readers consistent; it does not make them correct, and it removes the disagreement
that was the only visible symptom (PL-259).

WHAT THIS MEASURES. Two populations over the same files, both PRINTED, never just counted:

  GATE   what the queue surfaces — `count_unchecked_human_acs(body) > 0`, imported from
         the live module. Not reimplemented: a local copy would drift from the surface
         under test and this tool would end up measuring itself.
  WIDE   unchecked `- [ ]` lines under ANY `### Human` heading anywhere in the body,
         HTML comments stripped first.

A task in WIDE but not in GATE is a finding. The classes below are reported separately,
each naming the predicate step that drops the AC, because collapsing them into one
"invisible" bucket would hide which anchor needs fixing:

  OUT-OF-SECTION  `### Human` block lives outside the `## Acceptance Criteria` section.
                  Dropped by: the section scope. (T-344's class.)
  ANCHOR-SUFFIX   the AC heading carries trailing text (`## Acceptance Criteria (v2)`),
                  so the strict `\\s*$` anchor never matches and the WHOLE task returns 0.
                  Dropped by: the `^## Acceptance Criteria\\s*$` anchor.
  HEADER-SUFFIX   `### Human` carries trailing text inside an otherwise fine AC section.
                  Dropped by: the `^### Human\\s*$` sub-anchor.
  NO-AC-SECTION   Human ACs exist but the file has no `## Acceptance Criteria` heading
                  at all. Dropped by: the section lookup returning None.
  RESIDUAL        gate is 0 and something else disagrees, in a way the classes above do
                  not explain. Reported rather than dropped — a census that silently
                  bins what it cannot classify reports a clean corpus by omission, which
                  is this task's own defect one level up.

THE CONTROL RUNS FIRST AND ABORTS. The real-tree result is an ABSENCE assertion — "no
task carries an invisible Human AC" — and absence is exactly what a broken detector
reports. So six hermetic fixtures run before any repo file is opened: three that MUST be
flagged (one per class) and three that MUST NOT (a correctly sectioned task, a fully
checked one, and a task carrying only the template's commented `[REVIEW]` example). That
last negative is not decoration: nearly every task in the tree contains that comment
block, so a scanner that failed to strip HTML comments would flag the entire corpus and
be dismissed as noise. If any fixture fails, the sweep does not run and the tool says so
in those words, because "0 findings" printed by an unproven detector is worse than red.

POPULATION IS THE QUEUE'S POPULATION. `_load_pending_human_acs` filters to
`_location == "active"`, so the census scopes there too. The completed/ count is printed
anyway rather than assumed away — a task finishing with unchecked Human ACs is a
different defect (T-505's territory) and this tool should not be read as covering it.

EXIT CODES
  0  control passed and no finding
  1  control passed and at least one task carries a Human AC the queue cannot see
  2  the CONTROL FAILED — nothing was measured; a 0 here would have been meaningless
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Overridable so a mutated COPY of this file can still reach the real predicate and the
# real task tree. Proving these fixtures bite means running a deliberately broken copy,
# and mutating the shipping file in place is how T-576's probe would have destroyed the
# evidence for its own diagnosis. The predicate import below is NOT overridable — the
# whole point is that the tool measures the live surface, not a copy of it.
REPO = os.environ.get("T585_REPO") or REPO
sys.path.insert(0, os.path.join(REPO, ".agentic-framework"))

try:
    from web.shared import count_unchecked_human_acs, parse_frontmatter
    from web.blueprints.tasks import _parse_acceptance_criteria
except Exception as exc:  # pragma: no cover - import failure is a hard stop
    print(f"CONTROL FAILED: cannot import the live predicate ({type(exc).__name__}: {exc})")
    print("Nothing was measured. A reimplemented copy would not be the surface under test.")
    sys.exit(2)

ACTIVE = os.path.join(REPO, ".tasks", "active")
COMPLETED = os.path.join(REPO, ".tasks", "completed")

STRICT_AC = re.compile(r"^## Acceptance Criteria\s*$", re.MULTILINE)
LOOSE_AC = re.compile(r"^##\s+Acceptance Criteria\b", re.MULTILINE)
STRICT_HUMAN = re.compile(r"^### Human\s*$", re.MULTILINE)
LOOSE_HUMAN = re.compile(r"^###\s+Human\b.*$", re.MULTILINE)
UNCHECKED = re.compile(r"^\s*-\s*\[ \]", re.MULTILINE)
NEXT_HEADING = re.compile(r"^#{1,4} ", re.MULTILINE)
COMMENT = re.compile(r"<!--.*?-->", re.DOTALL)


def strip_comments(text):
    """Remove HTML comment blocks, including one left unterminated at EOF."""
    text = COMMENT.sub("", text)
    open_at = text.find("<!--")
    return text[:open_at] if open_at != -1 else text


def human_blocks(body):
    """Every `### Human` block in the body, however the heading is spelled.

    Returns [(start_offset_of_heading, comment_stripped_block_text)]. The block runs
    to the next heading of level 1-4, so a `### Agent` sibling or a following `## `
    section ends it — the same boundary the gate's own inner regex uses, widened to
    catch the headings the gate's anchors reject.
    """
    out = []
    for m in LOOSE_HUMAN.finditer(body):
        rest = body[m.end():]
        nxt = NEXT_HEADING.search(rest)
        block = rest[:nxt.start()] if nxt else rest
        out.append((m.start(), strip_comments(block)))
    return out


def strict_ac_span(body):
    """(start, end) of the block the gate scopes to, or None if its anchor misses."""
    m = STRICT_AC.search(body)
    if not m:
        return None
    rest = body[m.end():]
    nxt = re.search(r"^## ", rest, re.MULTILINE)
    end = m.end() + (nxt.start() if nxt else len(rest))
    return (m.end(), end)


def display_unchecked_human(body):
    """What the /approvals DISPLAY parser sees, which is a different predicate.

    `_parse_acceptance_criteria` matches `startswith('## Acceptance Criteria')` and
    `startswith('### Human')` — both looser than the gate's anchored regexes. The gate
    decides whether the row appears; this decides what the row says. They can disagree
    inside one request, and that disagreement is a finding, not a rendering detail.
    """
    try:
        acs = _parse_acceptance_criteria(body)
    except Exception:
        return None
    return sum(1 for a in acs if a.get("section") == "human" and not a.get("checked"))


def classify(body):
    """Return (class, wide_count, detail) for one body, or None when nothing is wrong.

    Only bodies the gate scores 0 reach a class — a task the queue already surfaces is
    visible regardless of how its headings are spelled.
    """
    gate = count_unchecked_human_acs(body)
    blocks = human_blocks(body)
    wide = sum(len(UNCHECKED.findall(b)) for _, b in blocks)
    disp = display_unchecked_human(body)

    if gate > 0:
        return None
    if wide == 0 and not disp:
        return None

    span = strict_ac_span(body)
    has_loose = bool(LOOSE_AC.search(body))

    if span is None and has_loose:
        heading = LOOSE_AC.search(body)
        line = body[heading.start():body.find("\n", heading.start())]
        return ("ANCHOR-SUFFIX", wide,
                f"AC heading is {line!r}; the gate anchors on '^## Acceptance Criteria$' "
                f"and returns 0 for the entire task")
    if span is None and not has_loose:
        return ("NO-AC-SECTION", wide,
                "no '## Acceptance Criteria' heading exists; the gate's section lookup "
                "returns None before it ever looks for '### Human'")

    lo, hi = span
    outside = [(p, b) for p, b in blocks if not (lo <= p < hi) and UNCHECKED.search(b)]
    if outside:
        where = body.rfind("\n## ", 0, outside[0][0])
        sect = body[where + 1:body.find("\n", where + 1)] if where != -1 else "<top of file>"
        return ("OUT-OF-SECTION", wide,
                f"'### Human' block sits under {sect!r}, outside the Acceptance Criteria "
                f"section the gate scopes to")

    inside = [(p, b) for p, b in blocks if lo <= p < hi and UNCHECKED.search(b)]
    if inside and not STRICT_HUMAN.search(body[lo:hi]):
        head = body[inside[0][0]:body.find("\n", inside[0][0])]
        return ("HEADER-SUFFIX", wide,
                f"human heading is {head!r}; the gate anchors on '^### Human$'")

    return ("RESIDUAL", wide,
            f"gate=0 but wide={wide} and display-parser={disp}; none of the known "
            f"anchor classes explain it — inspect by hand rather than trusting the 0")


# ── CONTROL ─────────────────────────────────────────────────────────────────────
# Runs before any repo file is opened. Every fixture is a literal body string, so
# these legs are hermetic: they cannot go red because a server is down or a path moved.

AC = "## Acceptance Criteria"

FIXTURES = [
    ("POS out-of-section", "OUT-OF-SECTION", f"""
{AC}

### Agent
- [x] done

## Measurements

### Human
- [ ] [REVIEW] Approve the watch scope
"""),
    ("POS anchor-suffix", "ANCHOR-SUFFIX", f"""
{AC} (revised)

### Human
- [ ] [REVIEW] Sign off on the revision
"""),
    ("POS header-suffix", "HEADER-SUFFIX", f"""
{AC}

### Human (operator)
- [ ] [REVIEW] Sign off
"""),
    ("NEG correctly sectioned", None, f"""
{AC}

### Human
- [ ] [REVIEW] Sign off
"""),
    ("NEG all checked", None, f"""
{AC}

### Human
- [x] [REVIEW] Signed off already
"""),
    ("NEG template comment only", None, f"""
{AC}

### Agent
- [x] done

### Human
<!-- Remove this section if all criteria are agent-verifiable.
     [REVIEW] example:
       - [ ] [REVIEW] Dashboard renders correctly
       - [ ] [REVIEWER] Block message names both bypass mechanisms
-->
"""),
]


def run_control():
    print("CONTROL — six hermetic fixtures, run before any repo file is opened")
    ok = True
    for name, want, body in FIXTURES:
        got = classify(body)
        got_cls = got[0] if got else None
        mark = "ok  " if got_cls == want else "FAIL"
        if got_cls != want:
            ok = False
        print(f"  [{mark}] {name:28s} expected={want or 'no finding':16s} got={got_cls or 'no finding'}")
    print()
    return ok


def gate_ids():
    """One task id per line, for the tasks the queue predicate surfaces.

    Exists so an outside caller can compare this tool's GATE population against an
    independent surface (`fw review-queue`) without scraping the human-readable report.
    The point of the comparison is AC 2: this census must be reading the LIVE predicate,
    not a copy that agrees with it today. If a local reimplementation were substituted,
    the two lists would part company the first time the real one changed.
    """
    for fn in sorted(f for f in os.listdir(ACTIVE) if f.endswith(".md")):
        try:
            _, body = parse_frontmatter(open(os.path.join(ACTIVE, fn)).read())
        except Exception:
            continue
        if body and count_unchecked_human_acs(body) > 0:
            print(fn.split("-")[0] + "-" + fn.split("-")[1])
    return 0


ANSI = re.compile(r"\x1b\[[0-9;]*m")


def cross_check():
    """Compare this tool's GATE population against `fw review-queue`'s own listing.

    Both are supposed to be the same predicate. This is what makes "the census imports
    the live predicate" a CHECKED property rather than a stated one: a local copy would
    agree today and part company the first time web/shared.py changed, and this leg is
    where that shows up. Set equality, not counts — two lists of the same length can
    still disagree about membership, and that disagreement is the whole subject.

    Parses the ID COLUMN only. Task names routinely mention other task ids ("(T-244 GO,
    partial)"), so a grep over the whole line invents four members that are not rows.
    """
    import subprocess

    mine = set()
    for fn in sorted(f for f in os.listdir(ACTIVE) if f.endswith(".md")):
        try:
            _, body = parse_frontmatter(open(os.path.join(ACTIVE, fn)).read())
        except Exception:
            continue
        if body and count_unchecked_human_acs(body) > 0:
            mine.add(fn.split("-")[0] + "-" + fn.split("-")[1])

    fw = os.path.join(REPO, ".agentic-framework", "bin", "fw")
    try:
        out = subprocess.run([fw, "review-queue"], capture_output=True, text=True,
                             timeout=120, cwd=REPO).stdout
    except Exception as exc:
        print(f"CANNOT CROSS-CHECK: `fw review-queue` did not run ({type(exc).__name__}: {exc}).")
        print("Declining to report agreement between a surface that ran and one that did not.")
        return 2

    theirs, in_section = set(), False
    for line in ANSI.sub("", out).splitlines():
        if "Human ACs awaiting verification" in line:
            in_section = True
            continue
        if in_section:
            if line.strip().startswith("VERDICT"):
                continue
            if line.strip() and not line.startswith(" ") and "  " not in line:
                break
            parts = line.split()
            if len(parts) >= 3 and re.fullmatch(r"T-\d+", parts[2]):
                theirs.add(parts[2])

    if not theirs:
        print("CANNOT CROSS-CHECK: parsed 0 rows out of `fw review-queue`'s Human-AC")
        print("section. An empty parse is not agreement — the output format moved.")
        return 2

    print(f"census GATE population : {len(mine)}")
    print(f"fw review-queue rows   : {len(theirs)}")
    only_mine, only_theirs = sorted(mine - theirs), sorted(theirs - mine)
    if not only_mine and not only_theirs:
        print("IDENTICAL — both surfaces name exactly the same tasks.")
        return 0
    print(f"DISAGREE — census only: {only_mine or '<none>'}")
    print(f"           CLI only   : {only_theirs or '<none>'}")
    return 1


def main():
    if "--gate-ids" in sys.argv:
        return gate_ids()
    if "--cross-check" in sys.argv:
        return cross_check()
    if not run_control():
        print("CONTROL FAILED — the detector cannot separate a mis-sectioned Human AC")
        print("from a correctly sectioned one. The repo sweep asserts ABSENCE, which a")
        print("broken detector reports perfectly, so it was NOT run. Nothing has been")
        print("measured and this tool's silence is not evidence.")
        return 2

    if not os.path.isdir(ACTIVE):
        print(f"CONTROL FAILED: {ACTIVE} does not exist — no population to census.")
        return 2

    active = sorted(f for f in os.listdir(ACTIVE) if f.endswith(".md"))
    completed = sorted(f for f in os.listdir(COMPLETED) if f.endswith(".md")) \
        if os.path.isdir(COMPLETED) else []

    gate_pop, wide_pop, findings, unreadable = [], [], [], []

    for fn in active:
        path = os.path.join(ACTIVE, fn)
        try:
            _, body = parse_frontmatter(open(path).read())
        except Exception as exc:
            unreadable.append((fn, f"{type(exc).__name__}: {exc}"))
            continue
        if not body:
            unreadable.append((fn, "empty body after frontmatter strip"))
            continue

        tid = fn.split("-")[0] + "-" + fn.split("-")[1]
        if count_unchecked_human_acs(body) > 0:
            gate_pop.append(tid)
        if any(UNCHECKED.search(b) for _, b in human_blocks(body)):
            wide_pop.append(tid)
        verdict = classify(body)
        if verdict:
            findings.append((tid, fn, verdict))

    print("POPULATION (both sides, named — a count alone would be the same defect one level up)")
    print(f"  active tasks scanned      : {len(active)}")
    print(f"  completed/ (out of scope) : {len(completed)}  "
          f"— the queue filters to active; printed so the scoping is visible, not assumed")
    print(f"  unreadable                : {len(unreadable)}")
    for fn, why in unreadable:
        print(f"      ! {fn}: {why}")
    print()
    print(f"  GATE — surfaced by count_unchecked_human_acs ({len(gate_pop)}):")
    print(f"      {', '.join(gate_pop) if gate_pop else '<none>'}")
    print(f"  WIDE — unchecked AC under any '### Human' heading ({len(wide_pop)}):")
    print(f"      {', '.join(wide_pop) if wide_pop else '<none>'}")
    print()

    if not findings:
        print("FINDINGS: none. Every task carrying an unchecked Human AC is one the queue")
        print("surfaces. The control above is what makes this 0 mean something.")
        return 0

    print(f"FINDINGS: {len(findings)} task(s) carry a Human AC the queue cannot see.")
    print("These are REPORTED, not repaired — relocating a block changes what the")
    print("operator is being asked to rule on, which is the operator's call.")
    print()
    for tid, fn, (cls, wide, detail) in findings:
        print(f"  {tid}  [{cls}]  {wide} unchecked human AC(s) invisible to the queue")
        print(f"      file  : .tasks/active/{fn}")
        print(f"      cause : {detail}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
