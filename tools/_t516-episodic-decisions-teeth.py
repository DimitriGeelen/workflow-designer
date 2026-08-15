#!/usr/bin/env python3
"""_t516-episodic-decisions-teeth — prove the decisions extractor catches all three symptoms.

T-516 fixed one root cause (a line-oriented parse of a block-structured document) with three
symptoms. Green on the fixed extractor is only meaningful if each symptom is shown to be
DETECTED — so every leg here constructs a document that exhibits the symptom and asserts the
extractor's output differs in the specific way that symptom would show.

PL-206, filed this morning: a control that CAN fail is still worthless if its stimulus was
built so it never would. So each leg asserts its stimulus actually contains the thing under
test before asserting the outcome — a fixture that does not exhibit the symptom is a leg
failure, not a pass.

Hermetic: writes only under mktemp. Exit 0 all passed, 1 a leg failed.
"""
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
EXTRACT = os.path.join(ROOT, ".agentic-framework", "agents", "context", "lib", "extract-decisions.py")

TEMPLATE_COMMENT = """## Decisions

<!-- Record decisions ONLY when choosing between alternatives.
     Skip for tasks with no meaningful choices.
     Format:
     ### [date] — [topic]
     - **Chose:** [what was decided]
     - **Why:** [rationale]
     - **Rejected:** [alternatives and why not]
-->

## Updates
"""

REAL_WRAPPED = """## Decisions

### 2026-08-15 — a real decision whose value wraps
- **Chose:** the first line of the value
  and a second line that the old extractor threw away
  and a third for good measure.
- **Why:** because a truncated rationale reads as a complete one.
- **Rejected:** the alternative, also wrapped
  onto a continuation line.

## Updates
"""

MANY = "## Decisions\n\n" + "".join(
    "### 2026-08-15 — decision {i}\n- **Chose:** choice {i}\n- **Why:** why {i}\n\n".format(i=i)
    for i in range(1, 13)
) + "## Updates\n"

ADJACENT_LABELS = """## Decisions

### 2026-08-15 — two adjacent rejected bullets
- **Chose:** the thing
- **Rejected:** the first alternative
- **Also rejected:** the second alternative

## Updates
"""

results = []


def run(md, tmp, name):
    p = os.path.join(tmp, name + ".md")
    with open(p, "w", encoding="utf-8") as f:
        f.write("# task\n\n" + md)
    r = subprocess.run([sys.executable, EXTRACT, p], capture_output=True, text=True)
    return r.stdout


def leg(name, ok, detail=""):
    results.append((name, ok, detail))
    print("  [%s] %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))


def main():
    if not os.path.exists(EXTRACT):
        print("REFUSE: extractor not found at %s — a teeth script with no subject is not green" % EXTRACT)
        return 2

    with tempfile.TemporaryDirectory(prefix="t516-teeth-") as tmp:
        # ── symptom 1: template comment must not become a decision ────────────────────
        # Stimulus check first: the fixture must actually contain the template placeholders,
        # otherwise this leg passes without exercising anything (PL-206).
        assert "[what was decided]" in TEMPLATE_COMMENT, "fixture lost its placeholders"
        out = run(TEMPLATE_COMMENT, tmp, "template")
        leg("template-only Decisions yields no entry",
            out.strip() == "",
            "got %r" % out.strip()[:60] if out.strip() else "empty, correct")

        # Prove the leg can fail: the SAME document with the comment markers removed is a
        # genuine (if silly) decision and MUST be extracted. Without this, "empty" could
        # mean "extractor is dead" rather than "comment correctly stripped" (PL-205).
        # De-indented deliberately. The first version of this leg just stripped the <!-- -->
        # markers and left the template's 5-space indentation, so `### …` never matched
        # `^###`, nothing parsed, and the leg failed — correctly, but for the wrong reason.
        # A stimulus that is malformed rather than merely uncommented tests nothing about
        # comment stripping. Same PL-206 trap, caught here by the leg going red instead of
        # green, which is the safe direction for it to fail in.
        uncommented = (
            "## Decisions\n\n"
            "### 2026-01-01 — real\n"
            "- **Chose:** an actual choice\n"
            "- **Why:** an actual reason\n"
            "- **Rejected:** an actual alternative\n\n"
            "## Updates\n"
        )
        assert "<!--" not in uncommented and uncommented.count("### ") == 1
        out_u = run(uncommented, tmp, "uncommented")
        leg("same text uncommented IS extracted (the stripper is what silenced it, not a dead parser)",
            "an actual choice" in out_u,
            "extractor produced %d chars" % len(out_u.strip()))

        # ── symptom 2: wrapped values must be captured whole ──────────────────────────
        assert "threw away" in REAL_WRAPPED, "fixture lost its continuation line"
        out = run(REAL_WRAPPED, tmp, "wrapped")
        leg("wrapped **Chose:** keeps its continuation lines",
            "threw away" in out and "third for good measure" in out,
            "chose captured whole" if "third for good measure" in out else "TRUNCATED: %r" % out[:120])
        leg("wrapped **Rejected:** keeps its continuation lines",
            "onto a continuation line" in out)
        # And the value must be ONE scalar, not smeared across lines — a multi-line scalar
        # would break the YAML the caller appends verbatim.
        chose_lines = [l for l in out.splitlines() if l.strip().startswith("chose:")]
        leg("wrapped value emits exactly one `chose:` scalar",
            len(chose_lines) == 1, "found %d" % len(chose_lines))

        # ── symptom 3: no silent cap ──────────────────────────────────────────────────
        assert MANY.count("### ") == 12, "fixture does not contain more than the old 20-line cap"
        out = run(MANY, tmp, "many")
        n = out.count("- decision:")
        leg("all 12 decisions survive (old head -20 dropped the tail silently)",
            n == 12, "got %d" % n)

        # ── adjacent unknown label must not be absorbed ───────────────────────────────
        assert "Also rejected" in ADJACENT_LABELS
        out = run(ADJACENT_LABELS, tmp, "adjacent")
        leg("an unknown **Also rejected:** bullet is not folded into the previous value",
            "the second alternative" not in out,
            "rejected value stayed its own scalar")

        # ── anti-overfit: a benign edit must not change the verdict ───────────────────
        # Reflowing whitespace is not a semantic change; if the extractor is sensitive to it
        # then it is measuring formatting, not decisions.
        reflowed = REAL_WRAPPED.replace("- **Why:**", "-  **Why:**")
        out_a = run(REAL_WRAPPED, tmp, "base")
        out_b = run(reflowed, tmp, "reflow")
        leg("benign whitespace reflow does not change the output", out_a == out_b)

    failed = [n for n, ok, _ in results if not ok]
    print("\nTEETH %s — %d passed, %d failed" % ("PASS" if not failed else "FAIL",
                                                 len(results) - len(failed), len(failed)))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
