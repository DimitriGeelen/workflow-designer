#!/usr/bin/env python3
"""_t1066-why-you-check.py — a [REVIEW] Human criterion must say why it needs the operator (832 T-1066).

The operator's standing instruction (PD-302, 2026-09-21): Human-AC verification goes to the
independent reviewer, EXCEPT high risk, Tier 0 and large UX reviews. The delegation predicate
(tools/_t770) honours the author's label, and the label cost the author nothing: on 2026-10-06
83 of 84 open Human criteria were [REVIEW] by default, so nothing ever reached the reviewer and
the operator's queue held work the order had taken off them (T-1063).

So the label must now be argued. Every UNTICKED `### Human` criterion prefixed [REVIEW], in a
task created on or after CUTOFF, needs a line

    **Why you:** <exception> — <one-line reason>

where <exception> is one of the operator's own carve-outs:
    tier0        a Tier 0 / consequential action
    irreversible publishing, deploying, paying, credentials, anything that cannot be undone
    sovereignty  a ruling or decision only the operator may make (project rules, approvals)
    direction    what the project is for / what to build next
    large-ux     a large UX review (not a single "reads well" check — those go to the reviewer)
Anything else is written for the reviewer instead: `fw reviewer judge T-XXX --criterion N`.

Older tasks are out of scope (the backlog was triaged by T-1064/T-1065, not by this check).

  python3 tools/_t1066-why-you-check.py              live tree (.tasks/active)
  python3 tools/_t1066-why-you-check.py --self-test  fixtures, with negative controls
exit 0 = clean; 1 = violations (each printed with its fix); 2 = could not run
"""
import glob
import os
import re
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CUTOFF = "2026-10-06"
EXCEPTIONS = ("tier0", "irreversible", "sovereignty", "direction", "large-ux")
WHY = re.compile(r"\*\*Why you:\*\*\s*`?([a-z0-9-]+)`?", re.I)


def human_block(text):
    """The `### Human` section (up to the next ## or ### heading), or ''."""
    m = re.search(r"^### Human[^\n]*\n(.*?)(?=^##[ #]|\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def criteria(block):
    """Yield (ticked, first_line, full_text) for each top-level checkbox in a Human block."""
    block = re.sub(r"<!--.*?-->", "", block, flags=re.S)       # the template's commented examples
    items = re.split(r"(?m)^(?=- \[[ xX]\])", block)
    for it in items:
        m = re.match(r"- \[([ xX])\]\s*(.*)", it)
        if m:
            yield m.group(1).lower() == "x", m.group(2).strip(), it


def check_file(path):
    text = open(path, encoding="utf-8").read()
    m = re.search(r"^created:\s*'?(\d{4}-\d{2}-\d{2})", text, re.M)
    tid = re.search(r"^id:\s*(T-\d+)", text, re.M)
    if not m or not tid or m.group(1) < CUTOFF:
        return []
    out = []
    for ticked, first, full in criteria(human_block(text)):
        if ticked or "[REVIEW]" not in first:
            continue
        w = WHY.search(full)
        if not w:
            out.append((tid.group(1), first[:90], "no '**Why you:**' line"))
        elif w.group(1).lower() not in EXCEPTIONS:
            out.append((tid.group(1), first[:90], "'Why you: %s' is not one of %s" % (w.group(1), "/".join(EXCEPTIONS))))
    return out


def run(paths):
    bad = [v for p in paths for v in check_file(p)]
    for tid, crit, why in bad:
        print("FAIL  %s: %s — %s\n      fix: name the exception (**Why you:** %s — reason), or write it for the reviewer"
              " (fw reviewer judge %s --criterion N)" % (tid, crit, why, "|".join(EXCEPTIONS), tid))
    return bad


def self_test():
    def task(created, human):
        return "---\nid: T-9999\ncreated: %sT00:00:00Z\n---\n## Acceptance Criteria\n### Agent\n- [x] a\n### Human\n%s\n## Verification\n" % (created, human)
    cases = [
        ("bare [REVIEW], new task -> red", task("2026-10-07", "- [ ] [REVIEW] Looks right\n  **Steps:** x"), 1),
        ("valid reason -> green", task("2026-10-07", "- [ ] [REVIEW] Rule on X\n  **Why you:** sovereignty — a project rule"), 0),
        ("invalid reason -> red", task("2026-10-07", "- [ ] [REVIEW] Looks right\n  **Why you:** please look"), 1),
        ("older task out of scope -> green", task("2026-10-01", "- [ ] [REVIEW] Looks right"), 0),
        ("ticked criterion ignored -> green", task("2026-10-07", "- [x] [REVIEW] Looks right"), 0),
        ("[RUBBER-STAMP] not this rule -> green", task("2026-10-07", "- [ ] [RUBBER-STAMP] Publish it"), 0),
        ("commented template example ignored -> green", task("2026-10-07", "<!--\n- [ ] [REVIEW] Dashboard renders\n-->"), 0),
        ("Why you in the NEXT criterion does not cover this one -> red",
         task("2026-10-07", "- [ ] [REVIEW] A\n- [ ] [REVIEW] B\n  **Why you:** direction — scope"), 1),
    ]
    fails = 0
    with tempfile.TemporaryDirectory() as d:
        for name, body, want in cases:
            p = os.path.join(d, "T-9999-x.md")
            open(p, "w").write(body)
            got = len(check_file(p))
            ok = got == want
            fails += not ok
            print("%s  %s (violations %d, want %d)" % ("PASS" if ok else "FAIL", name, got, want))
    print("\n%d/%d self-test legs passed" % (len(cases) - fails, len(cases)))
    return 1 if fails else 0


def main(argv):
    if "--self-test" in argv:
        return self_test()
    paths = sorted(glob.glob(os.path.join(ROOT, ".tasks", "active", "T-*.md")))
    if not paths:
        print("CANNOT RUN: no task files under .tasks/active")
        return 2
    bad = run(paths)
    print("%d violation(s) in %d active task(s) created on/after %s" % (len(bad), len(paths), CUTOFF) if bad
          else "OK: every open [REVIEW] Human criterion in tasks created on/after %s names its exception" % CUTOFF)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
