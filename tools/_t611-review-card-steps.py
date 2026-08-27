#!/usr/bin/env python3
"""T-611 — does every UNCHECKED [REVIEW] criterion still render its Steps block?

THE DEFECT CLASS THIS GUARDS (T-609). `/review/T-597` returned HTTP 200 and rendered its
AC titles while rendering ZERO Steps/Expected/If-not blocks, so the operator's decision card
was blank for three sessions and nobody noticed. The template was correct: it says
`{% if not ac.checked %}`, and three `[REVIEW]` ACs had been ticked on disk. Suppressing the
steps of a decision believed already made is right. The failure was that nothing compared
what the card SHOULD show against what it DID show.

SO THE INVARIANT IS A RELATION, NOT A COUNT. "Two Steps blocks render" would go green on a
card that ticked one AC and duplicated another's block, and would go RED — wrongly — the
moment the operator does their job and ticks one. What must hold is:

    rendered Steps blocks  ==  UNCHECKED [REVIEW] criteria in the task file

Both sides are measured. The left from the live card's bytes, the right from the task file
on disk. A fixed expected number would be an adjacent measurement that passes (rail 586).

WHY THE BYTES AND NOT THE CHECKER. Verified against the rendered response, never against the
template source and never against the status code — a usable card and an unusable card both
return 200 (rail 588).

Exit 0 = invariant holds. 1 = violated. 2 = could not measure (NOT a pass).
"""
import re
import sys
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TASK_GLOB = ".tasks/*/T-{id}-*.md"


def watchtower_url():
    """The triple file is the single source of truth for the port — never hard-code 3013."""
    p = REPO / ".context" / "working" / "watchtower.url"
    if not p.exists():
        return None
    return p.read_text().strip().rstrip("/")


def task_file(task_id):
    for sub in ("active", "completed"):
        hits = sorted((REPO / ".tasks" / sub).glob(f"T-{task_id}-*.md"))
        if hits:
            return hits[0]
    return None


def human_section(text):
    """Only the ### Human block. A [REVIEW] token elsewhere (the template's own worked
    example lives in an HTML comment right above) is a MENTION, not a criterion — the
    T-608 lesson, where a secret sweep flagged its own disclaimer."""
    m = re.search(r"^### Human\b(.*?)(?=^## |\Z)", text, re.S | re.M)
    if not m:
        return ""
    body = m.group(1)
    # strip HTML comments: the template ships example ACs inside them
    return re.sub(r"<!--.*?-->", "", body, flags=re.S)


def unchecked_reviews(text):
    return re.findall(r"^\s*-\s*\[ \]\s*\[REVIEW\]", human_section(text), re.M)


def checked_reviews(text):
    return re.findall(r"^\s*-\s*\[[xX]\]\s*\[REVIEW\]", human_section(text), re.M)


def rendered_steps(html):
    """Count Steps blocks in the SERVED bytes, tags stripped so markup changes don't
    silently reduce the count to zero and read as 'no unchecked ACs'."""
    text = re.sub(r"<[^>]+>", " ", html)
    return len(re.findall(r"\bSteps:", text))


def self_test():
    """Prove the invariant can go RED before trusting it green on the live card.

    The obvious arm — tick one of T-589's criteria and re-measure — is not available: a
    `### Human` AC is the operator's to tick and ticking one to test my own guard would be
    the agent asserting the operator's verdict. So the arm is synthetic, and it exercises
    the two directions the live card cannot currently show:

      * a criterion with NO instructions (the literal T-609 shape), and
      * instructions for a criterion already met (the same defect from the other side).
    """
    def task(acs):
        return "## Acceptance Criteria\n\n### Human\n" + "\n".join(acs) + "\n\n## Verification\n"

    U = "- [ ] [REVIEW] a thing"
    C = "- [x] [REVIEW] a done thing"
    steps = lambda n: "".join(f"<div>Steps:</div><p>do it</p>" for _ in range(n))

    cases = [
        ("2 unchecked / 2 Steps        ", task([U, U]), steps(2), True),
        ("2 unchecked / 1 Steps  T-609 ", task([U, U]), steps(1), False),
        ("2 unchecked / 0 Steps        ", task([U, U]), steps(0), False),
        ("1 unchecked+1 ticked/2 Steps ", task([U, C]), steps(2), False),
        ("1 unchecked+1 ticked/1 Steps ", task([U, C]), steps(1), True),
    ]
    ok = True
    print("self-test — the invariant must be able to go red")
    for label, text, html, expect_ok in cases:
        got = rendered_steps(html) == len(unchecked_reviews(text))
        good = got == expect_ok
        ok = ok and good
        print(f"  [{'PASS' if good else 'FAIL'}] {label} -> "
              f"{'holds' if got else 'VIOLATED':9s} (expected {'holds' if expect_ok else 'VIOLATED'})")

    # A [REVIEW] token inside the template's own HTML comment is a MENTION, not a criterion.
    commented = ("## Acceptance Criteria\n\n### Human\n<!--\n- [ ] [REVIEW] example from the "
                 "template\n-->\n- [ ] [REVIEW] the real one\n\n## Verification\n")
    n = len(unchecked_reviews(commented))
    good = n == 1
    ok = ok and good
    print(f"  [{'PASS' if good else 'FAIL'}] comment is a mention, not a use -> counted {n}, want 1")

    # Vacuity: a task with no [REVIEW] criteria must not pass 0 == 0.
    none = "## Acceptance Criteria\n\n### Human\n- [ ] plain criterion\n\n## Verification\n"
    good = len(unchecked_reviews(none)) + len(checked_reviews(none)) == 0
    ok = ok and good
    print(f"  [{'PASS' if good else 'FAIL'}] zero-[REVIEW] task is refused, not passed vacuously")

    print("self-test " + ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


def main():
    if "--self-test" in sys.argv:
        return self_test()
    task_id = sys.argv[1] if len(sys.argv) > 1 else "589"
    base = watchtower_url()
    if not base:
        print("CANNOT MEASURE: no .context/working/watchtower.url — is Watchtower running?")
        return 2

    tf = task_file(task_id)
    if tf is None:
        print(f"CANNOT MEASURE: no task file for T-{task_id}")
        return 2

    text = tf.read_text()
    want = len(unchecked_reviews(text))
    ticked = len(checked_reviews(text))
    if want + ticked == 0:
        print(f"CANNOT MEASURE: T-{task_id} carries no [REVIEW] criteria — this guard would "
              f"pass vacuously (0 == 0) and evidence nothing")
        return 2

    url = f"{base}/review/T-{task_id}"
    try:
        with urllib.request.urlopen(url, timeout=20) as r:
            html = r.read().decode("utf-8", "replace")
            code = r.status
    except Exception as exc:
        print(f"CANNOT MEASURE: {url} — {exc}")
        return 2

    got = rendered_steps(html)
    ok = got == want

    print(f"T-{task_id} review card — Steps blocks vs unchecked [REVIEW] criteria")
    print(f"  card            {url}  (HTTP {code}, {len(html)} bytes)")
    print(f"  task file       {tf.relative_to(REPO)}")
    print(f"  [REVIEW] ACs    {want} unchecked, {ticked} ticked")
    print(f"  Steps rendered  {got}")
    if not ok:
        print()
        print(f"  VIOLATED — {want} unchecked criteria, {got} Steps blocks on the card.")
        print("  The operator is being shown a criterion with no instructions for meeting it,")
        print("  or an instruction for a criterion already met. Both are T-609.")
    else:
        print(f"  OK — every unchecked criterion renders its instructions.")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
