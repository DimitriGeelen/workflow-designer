#!/usr/bin/env python3
"""
_t421-enforcement-claim-drift.py — find gates the tree SAYS are live and the settings
file does not install.

T-421. Structural half of T-420.

WHY THIS EXISTS
---------------
T-420 built a PreToolUse gate, registered it, and found it did not fire. Pulling that
thread produced a worse number than the one it started with: the framework ships 38
hook scripts and this project registers 17. Most of the 21 are correctly off. At
least one is not, and it is asserted as live in a comment that ships in EVERY task
file:

    # arc_id:  ... PreToolUse hook (check-arc-id) blocks save under agent control
    #              if it doesn't resolve.

`check-arc-id` is not registered in .claude/settings.json. The sentence is in ~420
task files and has never been true here.

That is the G-013/G-022 shape one level up. G-022 was "a measurement scoped to one
topic, reported as a fact about a peer". This is "a mechanism described in prose,
reported as a fact about the system" — and prose has no exit code, so nothing ever
disagreed with it.

THE THREE SETS
--------------
  EXISTS      hook scripts present in the framework tree
  REGISTERED  hooks wired into .claude/settings.json (by `fw hook <name>` or --script)
  CLAIMED     hook names the tree asserts are ACTIVE

The finding is CLAIMED minus REGISTERED. Not EXISTS minus REGISTERED — that set is 21
entries of which most are correctly off, and a detector that reports 21 things you
already decided about is a detector you learn to skip. The whole design problem here
is separating an assertion from a mention.

MENTION vs ASSERTION
--------------------
A hook name appears in this tree in three kinds of context:

  usage      `fw hook-enable --name check-visual-verification`     <- not a claim
  catalogue  a list of hooks available to enable                    <- not a claim
  assertion  "blocks save", "refuses when", "the hook enforces"     <- a claim

So a name counts as CLAIMED only when an assertion verb appears near it AND no opt-in
marker does. Both halves are needed: CLAUDE.md's check-visual-verification paragraph
contains the word "blocks" in the same sentence as the hook name, and is explicitly
labelled opt-in three words earlier. Assertion-only matching reports it; that would be
a false positive on the one hook whose off-ness is documented on purpose.

The verb has to be found in a WINDOW, not on the line. The check-arc-id claim that
motivated this file is split across two lines of a YAML comment block, with the hook
name on the line AFTER the verb's sentence begins. Line-scoped matching finds nothing
and reports a clean bill of health — which is the exact failure mode of the thing being
detected, reproduced inside the detector. Hence WINDOW = 2 lines either side.

SELF-DISPOSITION IS HONOURED, NOT RE-DECLARED
----------------------------------------------
Five scripts carry `REFERENCE ONLY — not registered in .claude/settings.json` in their
own headers (T-1459). That is a disposition already in the tree, written by whoever
decided it, next to the thing it describes. This reads it rather than maintaining a
second list that can disagree with the first. A hardcoded exclusion list here would be
the PL-142 shape: a fact with a shelf life, copied away from the artifact that owns it.

BASELINE, NOT ZERO
------------------
Exit 1 on any CLAIMED-but-unregistered hook would make this unusable as a verification
gate while the findings are open — and findings like check-arc-id are follow-up tasks,
not one-line fixes. So the gate is containment, in the shape T-408 already uses here:
a committed baseline file pins the known set, and the detector fails when the set
GROWS. A new false promise cannot be added quietly; the existing ones stay visible
without blocking every future commit.

  --baseline PATH   compare against a pinned set; exit 1 if it grew
  --write-baseline  rewrite the pinned set (do this only with a reason)

EXIT CODES
----------
  0  no drift beyond the baseline
  1  the claimed-but-unregistered set GREW (or, with no baseline, is non-empty)
  2  cannot answer — inputs missing or unreadable
"""

import argparse
import json
import os
import re
import sys

# T421_ROOT exists so the mutation check can point this at a scratch copy of the tree
# and spoil one input at a time. The real tree is never edited to test the detector —
# two of the three inputs are .claude/settings.json and CLAUDE.md, and T-420 has
# already demonstrated this session what editing the first one by hand costs.
ROOT = os.environ.get("T421_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOOK_DIR = os.path.join(ROOT, ".agentic-framework", "agents", "context")
SETTINGS = os.path.join(ROOT, ".claude", "settings.json")

# Files whose prose can make a claim about enforcement.
CLAIM_SOURCES = [
    os.path.join(ROOT, "CLAUDE.md"),
    os.path.join(ROOT, "FRAMEWORK.md"),
]
CLAIM_DIRS = [
    os.path.join(ROOT, ".tasks", "templates"),
]
# NOT scanned, deliberately: .agentic-framework/docs/. Measured on the first run —
# it produced 6 of 9 findings and every one was a false positive. A generated
# component catalogue ("**bus-handler** (script) @ agents/context/bus-handler.sh —
# processes incoming bus messages") describes what the FRAMEWORK contains; it says
# nothing about what THIS project installed. Same for the framework's own task
# reports, which discuss hooks under development upstream.
#
# The distinction the detector needs is not mention-vs-assertion alone but
# whose-configuration-is-being-asserted. Only project-owned prose — CLAUDE.md,
# FRAMEWORK.md, and the task templates this project writes files from — makes a
# claim about the gates running here. A vendored catalogue that lists 38 scripts
# would otherwise report 38 broken promises and be correct about none of them.

WINDOW = 2  # lines either side — the motivating claim is split across two lines

ASSERT_VERBS = re.compile(
    r"\b(blocks?|blocked|refuses?|refused|enforces?|prevents?|rejects?|"
    r"fires?|gates?|guards?|is installed|are installed|runs on|will block|"
    r"auto-triggers?|intercepts?)\b",
    re.I,
)
OPTIN_MARKERS = re.compile(
    r"(hook-enable|opt-in|opt in|to enable|enable in projects|available hooks|"
    r"reference only|not registered|--name\s)",
    re.I,
)
SELF_REFERENCE_ONLY = re.compile(r"REFERENCE ONLY", re.I)


def hooks_that_exist():
    out = {}
    if not os.path.isdir(HOOK_DIR):
        return out
    for fn in sorted(os.listdir(HOOK_DIR)):
        if not fn.endswith(".sh"):
            continue
        name = fn[:-3]
        path = os.path.join(HOOK_DIR, fn)
        try:
            head = open(path, encoding="utf-8", errors="replace").read(4000)
        except OSError:
            head = ""
        out[name] = {"path": path, "self_reference_only": bool(SELF_REFERENCE_ONLY.search(head))}
    return out


def hooks_registered():
    with open(SETTINGS, encoding="utf-8") as fh:
        data = json.load(fh)
    names = set()
    for _event, groups in (data.get("hooks") or {}).items():
        for group in groups:
            for hook in group.get("hooks") or []:
                cmd = hook.get("command", "")
                m = re.search(r"\bhook\s+([A-Za-z0-9._-]+)", cmd)
                if m:
                    names.add(m.group(1))
                else:
                    base = os.path.basename(cmd.split()[0]) if cmd.split() else ""
                    names.add(re.sub(r"\.(sh|py)$", "", base))
    return names


def claim_files():
    files = [p for p in CLAIM_SOURCES if os.path.isfile(p)]
    for d in CLAIM_DIRS:
        for dirpath, _dirs, names in os.walk(d):
            for n in names:
                if n.endswith((".md", ".yaml", ".yml")):
                    files.append(os.path.join(dirpath, n))
    return files


def claims(known_names):
    """name -> [(file, lineno, line)] where the tree ASSERTS the hook is active."""
    found = {}
    for path in claim_files():
        try:
            lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
        except OSError:
            continue
        for i, line in enumerate(lines):
            for name in known_names:
                # Token match, not substring. Measured: plain `in` matched the hook
                # named `context` against every `.context/` path and every
                # `agents/context/checkpoint.sh` reference in CLAUDE.md — three
                # findings, all noise, on a script that is an agent entry point
                # rather than a hook. The lookarounds exclude a name that is
                # preceded by `.` `/` `-` or a word char (a path segment) or
                # followed by one (a longer name).
                if not re.search(r"(?<![\w./-])%s(?![\w-])" % re.escape(name), line):
                    continue
                # A hook name with no hyphen may also be an ordinary English word.
                # `context` is a dispatchable hook (`fw hook context` resolves) AND
                # the most common noun in this codebase — it matched "context
                # explosion", "pollutes context" and "reading files ... .context/".
                # Three findings, all English. So an un-hyphenated name must appear
                # as an IDENTIFIER — backticked, parenthesised, quoted, or suffixed —
                # because prose asserting a hook names it as a thing, not as a word.
                # Hyphenated names need no such proof: `check-arc-id` is not English.
                #
                # Rejected: a stopword list containing "context". It would be one
                # declared entry today and would say nothing about the next hook
                # named `audit` or `resume`.
                if "-" not in name and not re.search(
                    r"[`'\"(\[]%s|%s\.(sh|py)" % (re.escape(name), re.escape(name)), line
                ):
                    continue
                lo, hi = max(0, i - WINDOW), min(len(lines), i + WINDOW + 1)
                window = "\n".join(lines[lo:hi])
                if not ASSERT_VERBS.search(window):
                    continue
                if OPTIN_MARKERS.search(window):
                    continue
                found.setdefault(name, []).append(
                    (os.path.relpath(path, ROOT), i + 1, line.strip()[:120])
                )
    return found


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--baseline")
    ap.add_argument("--write-baseline", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    try:
        exists = hooks_that_exist()
        registered = hooks_registered()
    except (OSError, json.JSONDecodeError) as exc:
        print("UNKNOWN — cannot read inputs: %s" % exc)
        return 2
    if not exists:
        print("UNKNOWN — no hook scripts found under %s" % HOOK_DIR)
        return 2

    claimed = claims(set(exists))
    unregistered = sorted(n for n in exists if n not in registered)
    finding = sorted(n for n in claimed if n not in registered)

    if not args.quiet:
        print("=== T-421 enforcement claim drift ===")
        print("  scripts present : %d" % len(exists))
        print("  registered      : %d" % len(registered & set(exists)))
        print("  unregistered    : %d" % len(unregistered))
        print()
        print("  disposition of the unregistered:")
        for n in unregistered:
            if exists[n]["self_reference_only"]:
                tag = "REFERENCE-ONLY (self-declared)"
            elif n in claimed:
                tag = "CLAIMED-BUT-OFF  <-- finding"
            else:
                tag = "off, no claim found"
            print("    %-30s %s" % (n, tag))
        if finding:
            print()
            print("  CLAIMED-BUT-OFF — the tree asserts these are live:")
            for n in finding:
                for path, lineno, line in claimed[n][:3]:
                    print("    %-24s %s:%d" % (n, path, lineno))
                    print("      %s" % line)

    if args.write_baseline:
        if not args.baseline:
            print("ERROR: --write-baseline needs --baseline PATH")
            return 2
        with open(args.baseline, "w", encoding="utf-8") as fh:
            fh.write("# T-421 claimed-but-unregistered baseline. Growth is a failure.\n")
            for n in finding:
                fh.write(n + "\n")
        print("\nbaseline written: %d entry(ies)" % len(finding))
        return 0

    if args.baseline:
        try:
            pinned = {l.strip() for l in open(args.baseline, encoding="utf-8")
                      if l.strip() and not l.startswith("#")}
        except OSError as exc:
            print("UNKNOWN — baseline unreadable: %s" % exc)
            return 2
        new = sorted(set(finding) - pinned)
        if new:
            print("\nFAIL — the claimed-but-unregistered set GREW: %s" % ", ".join(new))
            print("  Either register the hook, or drop the sentence that promises it.")
            print("  Do not widen the baseline to make this pass without a reason.")
            return 1
        gone = sorted(pinned - set(finding))
        if gone and not args.quiet:
            print("\n  (baseline entries no longer drifting: %s)" % ", ".join(gone))
        print("\nPASS — no new false promises since the baseline.")
        return 0

    if finding:
        print("\nFAIL — %d hook(s) claimed active, none registered." % len(finding))
        return 1
    print("\nPASS — every hook the tree asserts is live is registered.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
