#!/usr/bin/env python3
"""extract-decisions — parse a task file's ## Decisions section into episodic YAML.

Replaces the line-oriented extraction that lived inline in episodic.sh, which treated a
block-structured markdown document as one-fact-per-line and produced three defects
(832 T-516; email-archive's G-EPISODIC-PLACEHOLDER-LEAK, rail 11890):

  1. PHANTOM DECISIONS. The old filter dropped lines matching ^<!-- and ^--> but not the
     INTERIOR of a multi-line HTML comment. The task template's Decisions block is exactly
     such a comment, so `### [date] — [topic]` and `- **Chose:** [what was decided]`
     survived and were emitted as a real decision — on EVERY task close. Measured in 832:
     363 of 448 episodics, 81%, rising rather than stable.

  2. TRUNCATED REAL DECISIONS. `sed 's/.*\\*\\*Chose:\\*\\* *//'` ran on a single line, so a
     value wrapping onto continuation lines was cut at the first newline. This is the worse
     half: a phantom entry is visibly junk, a truncated rationale reads as complete.

  3. SILENT CAP. `head -20` discarded everything past 20 lines with no note.

Usage:  extract-decisions.py <task-file>
Writes YAML decision entries to stdout (the body of a `decisions:` block, indented two
spaces). Emits nothing when there are no real decisions — the caller writes the
no-decisions note. Exit 0 always unless the file is unreadable (exit 2); an absent or
comment-only Decisions section is a normal outcome, not an error.

Scalars are single-quoted with '' escaping (T-1871 / L-392: double-quoted YAML treats
backslashes and some backtick sequences as escapes and raises ScannerError).
"""
import re
import sys

# Fields as they appear in the task template, mapped to their episodic YAML keys.
FIELDS = [
    ("Chose", "chose"),
    ("Why", "rationale"),
    ("Rejected", "alternatives_rejected"),
]
FIELD_RE = re.compile(r"^\s*-?\s*\*\*(" + "|".join(f for f, _ in FIELDS) + r"):\*\*\s*(.*)$")
HEADING_RE = re.compile(r"^###\s+(.*\S)\s*$")
# Any bolded-label bullet, known field or not. An UNKNOWN one (e.g. '- **Also rejected:**')
# must END the current value rather than be folded into it as a continuation line —
# otherwise two adjacent bullets silently merge into one scalar, which is the same
# lose-the-structure failure as the truncation this file exists to fix, running the other way.
ANY_LABEL_RE = re.compile(r"^\s*-?\s*\*\*[^*]+:\*\*")

# A value that is still the template's own example text. Kept as a SECOND line of defence:
# stripping comment bodies (the root-cause fix) already removes the template, so this only
# catches a decision someone half-filled in. It is deliberately not the primary mechanism —
# filtering placeholders while leaving the parse broken is what makes the output LOOK clean.
PLACEHOLDER_RE = re.compile(
    r"\[date\]|\[topic\]|\[what was decided\]|\[rationale\]|\[alternatives"
)


def strip_html_comments(text):
    """Remove <!-- ... --> spans including their interior lines.

    Non-greedy and DOTALL so each comment closes at its own terminator rather than the
    last one in the file. An unterminated comment consumes to end-of-section, which is the
    safe direction: better to drop a malformed tail than to emit template text as data.
    """
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    if "<!--" in text:
        text = text[: text.index("<!--")]
    return text


def decisions_section(md):
    """The text between '## Decisions' and the next H2, exclusive.

    Matched on '## Decisions' exactly so the template's separate '## Decision' section
    (singular — the inception decision anchor) is not swept in.
    """
    lines = md.splitlines()
    out, inside = [], False
    for line in lines:
        if re.match(r"^##\s+Decisions\s*$", line):
            inside = True
            continue
        if inside and re.match(r"^##\s+", line):
            break
        if inside:
            out.append(line)
    return "\n".join(out)


def parse(section):
    """Parse into [{decision, chose, rationale, alternatives_rejected}].

    Continuation lines are folded into the field they follow, which is what fixes the
    truncation: a wrapped '**Chose:** ...' keeps its tail instead of being cut at the
    first newline. A blank line or a new field/heading ends the current value.
    """
    entries, cur, field = [], None, None
    for raw in section.splitlines():
        line = raw.rstrip()
        h = HEADING_RE.match(line)
        if h:
            if cur:
                entries.append(cur)
            cur = {"decision": h.group(1)}
            field = None
            continue
        m = FIELD_RE.match(line)
        if m and cur is not None:
            label, value = m.group(1), m.group(2).strip()
            field = dict(FIELDS)[label]
            cur[field] = value
            continue
        if not line.strip():
            field = None
            continue
        if ANY_LABEL_RE.match(line):
            # A bolded label we do not map. Close the open value; do not absorb it.
            field = None
            continue
        # Continuation of the value above — the line the old extractor threw away.
        if cur is not None and field:
            cur[field] = (cur[field] + " " + line.strip()).strip()
    if cur:
        entries.append(cur)
    return entries


def is_real(entry):
    """A decision is real when nothing in it is still template example text."""
    blob = " ".join(str(v) for v in entry.values())
    return not PLACEHOLDER_RE.search(blob)


def q(s):
    return "'" + str(s).replace("'", "''") + "'"


def main():
    if len(sys.argv) < 2:
        print("usage: extract-decisions.py <task-file>", file=sys.stderr)
        return 2
    try:
        md = open(sys.argv[1], encoding="utf-8").read()
    except OSError as e:
        print("extract-decisions: %s" % e, file=sys.stderr)
        return 2

    entries = [e for e in parse(strip_html_comments(decisions_section(md))) if is_real(e)]

    for e in entries:
        print("  - decision: %s" % q(e.get("decision", "")))
        if e.get("chose"):
            print("    chose: %s" % q(e["chose"]))
        if e.get("rationale"):
            print("    rationale: %s" % q(e["rationale"]))
        if e.get("alternatives_rejected"):
            print("    alternatives_rejected: [%s]" % q(e["alternatives_rejected"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
