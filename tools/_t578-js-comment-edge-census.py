#!/usr/bin/env python3
"""_t578-js-comment-edge-census.py — how many tool edges in this tree are held ONLY by a
JavaScript comment?

WHY THIS EXISTS. tools/_t451-unwired-guard-census.py decides that a tool is reachable when
some file references `tools/<name>` in an EXECUTABLE position. T-495 taught it to ignore
prose in two languages — Python (tokenize for comments, ast for bare string statements) and
shell (a word-aware, quote-aware `#` stripper). It was never taught JavaScript. `.mjs` and
`.js` are read whole, so `// tools/x.py` and a `/** ... tools/x.py ... */` JSDoc block both
count as calls.

That was found by accident: tools/_t423-carrier-agreement-guard.py is counted WIRED solely
because line 7 of its sibling `.mjs` mentions the path inside a block comment. Reword that
comment and a live, suite-critical guard reports unwired. The accident is the problem — the
census carries a LIMIT paragraph whose whole job is to enumerate its blind spots so a clean
run cannot imply coverage it does not have, and JavaScript is not in it.

WHAT THIS MEASURES, AND WHAT IT DOES NOT. It answers one question: for each tool, are ALL of
its `.mjs`/`.js` references inside comments? It does NOT re-implement the census. A tool
whose JS references are all prose may still be perfectly reachable from a shell script or a
Python caller — those are reported separately and are not findings. The finding is the
intersection: reachable ONLY through JavaScript, and that JavaScript is a comment.

WHY A SEPARATE INSTRUMENT RATHER THAN A PATCH TO THE CENSUS. Teaching the census to strip JS
changes its verdicts, and its ratchet is a committed baseline that must not move without the
movement being understood first. Measure, then decide — the opposite order is how a baseline
gets re-cut around a number nobody examined.

STRIPPING IS EXACT WHERE IT CAN BE. JavaScript has no stdlib tokenizer here, so the stripper
is hand-written and states its own limits rather than implying it has none:
  * `//` to end of line, and `/* */` spans, both tracked outside strings
  * single, double and template quotes tracked, with backslash escapes
  * NOT handled: a regex literal containing quote or comment characters
    (`/["']/`), which can desynchronise quote state for the rest of the file
Files where stripping is uncertain are reported, never silently trusted — an unparseable
file is not a file with no references.

Exit 0 always: this is a census, not a gate. Its output is a number to act on.
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)

SKIP_DIRS = {".git", "node_modules", ".agentic-framework", ".editor-versions"}


def strip_js(text):
    """Blank out // and /* */ comments, preserving offsets. -> (stripped, uncertain)."""
    out = list(text)
    i, n = 0, len(text)
    quote = None
    uncertain = False
    while i < n:
        c = text[i]
        if quote:
            if c == "\\":
                i += 2
                continue
            if c == quote:
                quote = None
            i += 1
            continue
        if c in "\"'`":
            quote = c
            i += 1
            continue
        if c == "/" and i + 1 < n:
            nxt = text[i + 1]
            if nxt == "/":
                j = text.find("\n", i)
                j = n if j == -1 else j
                for k in range(i, j):
                    out[k] = " "
                i = j
                continue
            if nxt == "*":
                j = text.find("*/", i + 2)
                if j == -1:
                    uncertain = True
                    j = n
                else:
                    j += 2
                for k in range(i, j):
                    if out[k] != "\n":
                        out[k] = " "
                i = j
                continue
            # A regex literal is the case this stripper cannot tell from division.
            # Not an error, but a reason not to claim certainty about this file.
            uncertain = True
        i += 1
    return "".join(out), uncertain


def walk(exts):
    for root, dirs, files in os.walk(REPO):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".venv")]
        for f in files:
            if f.endswith(exts):
                yield os.path.join(root, f)


def main():
    tools = sorted(f for f in os.listdir(HERE)
                   if not f.startswith(".") and os.path.isfile(os.path.join(HERE, f)))

    js_all, js_code, uncertain_files = {}, {}, []
    for p in walk((".mjs", ".js")):
        try:
            t = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        stripped, unc = strip_js(t)
        if unc:
            uncertain_files.append(os.path.relpath(p, REPO))
        for name in tools:
            pat = "tools/" + name
            if pat in t:
                js_all.setdefault(name, set()).add(os.path.relpath(p, REPO))
                if pat in stripped:
                    js_code.setdefault(name, set()).add(os.path.relpath(p, REPO))

    # References from the two languages the census DOES strip, plus every other file type it
    # reads whole. Deliberately not re-derived here: any hit outside JS means this tool's
    # reachability does not depend on the JS question at all.
    non_js = {}
    for p in walk((".sh", ".py", ".yaml", ".yml", ".md", ".json", ".bats", ".toml")):
        try:
            t = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        rel = os.path.relpath(p, REPO)
        for name in tools:
            if "tools/" + name in t:
                non_js.setdefault(name, set()).add(rel)

    prose_only = []
    for name, files in sorted(js_all.items()):
        if name in js_code:
            continue                       # a real JS call exists
        others = non_js.get(name, set()) - {os.path.join("tools", name)}
        prose_only.append((name, sorted(files), sorted(others)))

    print("== JS-comment edge census (T-578) ==")
    print(f"POPULATION: {len(tools)} file(s) in tools/; "
          f"{len(js_all)} referenced from .mjs/.js at all, "
          f"{len(js_code)} of those from executable JS.")
    if uncertain_files:
        print(f"\nSTRIPPING UNCERTAIN in {len(uncertain_files)} file(s) — a regex literal or an "
              f"unterminated block\n  comment can desynchronise quote state. Named, not trusted:")
        for f in uncertain_files[:8]:
            print("    " + f)

    hard = [x for x in prose_only if not x[2]]
    soft = [x for x in prose_only if x[2]]

    print(f"\nREFERENCED FROM JS ONLY AS PROSE: {len(prose_only)}")
    print(f"  of which reachable by some other route anyway: {len(soft)}")
    print(f"  of which the JS COMMENT IS THE ONLY EDGE:      {len(hard)}   <- the finding")
    for name, files, _ in hard:
        print(f"\n  {name}")
        for f in files:
            print(f"      prose-only reference in {f}")
    for name, files, others in soft:
        print(f"  [also reachable] {name} — via {', '.join(others[:3])}")

    print("\nREAD THIS AS A CENSUS, NOT A DEFECT COUNT. A prose-only edge is not a broken tool;")
    print("it is a tool whose WIRED verdict rests on a sentence, and would flip if the sentence")
    print("were reworded. That is a property of the census, not of the tool.")

    # ── The question this file was opened to answer turned out to be the small one ──────
    # Going looking for JS comments found ~zero, because 41 of the 52 JS-referenced tools are
    # rescued by "some other route" — and inspecting those routes showed they are
    # overwhelmingly handovers and episodic YAML, which the census also reads WHOLE. So the
    # JS gap is real and narrow, and it sits inside a far larger one that its LIMIT paragraph
    # discloses in kind ("no comment syntax assumed") without disclosing in SCALE.
    #
    # Reported here rather than in a second tool because splitting them would let the small
    # number be quoted without the large one, which is how the first measurement misled.
    PROSE_EXT = (".md", ".yaml", ".yml")
    code_ref, prose_ref = {}, {}
    for p in walk((".mjs", ".js", ".sh", ".py", ".yaml", ".yml", ".md", ".json", ".bats", ".toml")):
        rel = os.path.relpath(p, REPO)
        try:
            t = open(p, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        is_js = p.endswith((".mjs", ".js"))
        stripped = strip_js(t)[0] if is_js else None
        for name in tools:
            if "tools/" + name not in t or rel == "tools/" + name:
                continue
            if p.endswith(PROSE_EXT):
                prose_ref.setdefault(name, set()).add(rel)
            elif is_js:
                (code_ref if "tools/" + name in stripped else prose_ref).setdefault(name, set()).add(rel)
            else:
                code_ref.setdefault(name, set()).add(rel)

    referenced = set(code_ref) | set(prose_ref)
    prose_only = sorted(set(prose_ref) - set(code_ref))
    print("\n== The larger surface the JS question sits inside ==")
    print(f"  tools/ files                              {len(tools)}")
    print(f"  referenced anywhere outside themselves    {len(referenced)}")
    print(f"  have at least one EXECUTABLE-CODE edge    {len(code_ref)}")
    print(f"  PROSE-ONLY — no code edge anywhere        {len(prose_only)}   <- the real number")
    where = {}
    for n in prose_only:
        for f in prose_ref[n]:
            k = ("handover" if "/handovers/" in f else "episodic" if "/episodic/" in f
                 else "task file" if f.startswith(".tasks/") else "other " + os.path.splitext(f)[1])
            where[k] = where.get(k, 0) + 1
    for k, v in sorted(where.items(), key=lambda x: -x[1]):
        print(f"      prose lives in {k:<14} {v} reference(s)")
    print("  A tool in that set is counted WIRED by _t451 whenever any of those files names it,")
    print("  because .md and .yaml are read whole. Its reachability is then a fact about what a")
    print("  handover once said, not about what runs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
