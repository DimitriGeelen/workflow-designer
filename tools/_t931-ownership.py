#!/usr/bin/env python3
r"""_t931-ownership.py — is a task's `owner: human` still a sovereignty claim, or stale metadata?

THE RULING (operator, 2026-09-29). `owner: human` is a sovereignty claim only while a Human
acceptance criterion is actually OPEN. When none is open, the field asserts a judgement requirement
that does not exist, and ownership should follow the criteria back to the agent.

WHY THIS EXISTS AS ITS OWN PREDICATE. Ownership was previously self-justifying. The delegation
boundary (tools/_t770-delegation-boundary.py) carves criteria out to OPERATOR-ONLY with the rule
`owner-human` and the reason "completing an owner:human task is not delegated" — true, but circular:
the ownership justifies the non-delegation and nothing justifies the ownership. `fw task delegate`
converts CRITERIA and never touches the owner field, so a task created the framework's own
documented way (`--owner human`, lib/init.sh:926) with no Human criteria stays operator-only
forever with nothing for the delegation mechanism to grip.

WHAT HID IT, MEASURED. _t770 line 354 drops every TICKED criterion from a corpus-wide scan:
`if args.unticked_only or not args.task: rows = [r for r in rows if not r["ticked"]]`. A task whose
criteria are ALL ticked and which is blocked purely by the owner field therefore emits zero rows.
T-885, T-708 and T-723 classify as OPERATOR-ONLY/owner-human when scanned one at a time and are
absent from all 406 rows of the corpus scan. The surface answers "which OPEN criteria could be
delegated" — a fair question — while nobody asks "which tasks are blocked with nothing left open".
That second set is the rubber-stamp queue, and it was unmeasurable by construction.

ONE VOCABULARY. The parse comes from _t770.parse_task, imported, not re-implemented (T-322). A
second regex for "what is a Human acceptance criterion" is how two encodings start disagreeing —
which is already an open gap here (G-052), and this must not widen it.

A NOTE ON A HAZARD THAT IS *NOT* A DEFECT HERE. A naive scan for `^\s*-\s*\[.\]` under `### Human`
returns 2 for T-885, which has none: both hits are the task template's own [REVIEW]/[REVIEWER]
examples inside an HTML comment. _t770's AC_RE is anchored at column 0 and the examples are
indented, so it never matches them. Anyone writing a THIRD scanner will hit this; _t770 does not.

VERDICTS
    NOT-HUMAN-OWNED   owner is not human — nothing to say
    OWNER-JUSTIFIED   owner: human AND at least one OPEN (unticked) Human criterion
    OWNER-STALE       owner: human AND zero open Human criteria — the ruling applies

This module DECIDES NOTHING AND WRITES NOTHING. It returns a verdict. The write is the caller's,
and the caller is attended by design (see T-931 Decisions: cron runs the detector, never the actor).
"""
from __future__ import annotations

import argparse
import glob
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

NOT_HUMAN_OWNED = "NOT-HUMAN-OWNED"
OWNER_JUSTIFIED = "OWNER-JUSTIFIED"
OWNER_STALE = "OWNER-STALE"


class _FrameworkParser:
    """The framework's own Human-criteria parser (lib.delegation), wearing _t770's parse_task
    contract: (frontmatter dict, [{"section", "ticked"}]). Used where _t770 is absent -- in the
    framework repo, this IS the one vocabulary (T-322), so no second parser ships upstream."""

    def __init__(self, mod):
        self._m = mod

    def parse_task(self, path):
        text = open(path, encoding="utf-8", errors="replace").read()
        acs = [{"section": "Human" if c.subhead.lower().startswith("human") else (c.subhead or ""),
                "ticked": bool(c.ticked)} for c in self._m.parse_criteria(text)]
        return self._m.frontmatter(text), acs


def _framework_parser():
    """lib.delegation from the framework repo itself (FRAMEWORK.md at the root) or a vendored
    .agentic-framework/; None when neither is importable."""
    repo = os.path.dirname(HERE)
    for root in ((repo, os.path.join(repo, ".agentic-framework"))
                 if os.path.isfile(os.path.join(repo, "FRAMEWORK.md"))
                 else (os.path.join(repo, ".agentic-framework"), repo)):
        if os.path.isfile(os.path.join(root, "lib", "delegation.py")):
            sys.path.insert(0, root)
            try:
                from lib import delegation  # type: ignore[import-not-found]
            except Exception:  # noqa: BLE001 - fall through to the explicit SETUP BROKEN below
                sys.path.remove(root)
                continue
            return _FrameworkParser(delegation)
    return None


def _load_t770():
    """Import the delegation-boundary module for its parser. Dash in the filename, so importlib."""
    path = os.environ.get("FW_T770_TOOL", os.path.join(HERE, "_t770-delegation-boundary.py"))
    if not os.path.isfile(path) and "FW_T770_TOOL" not in os.environ:
        fw = _framework_parser()
        if fw is not None:
            return fw
    if not os.path.isfile(path):
        raise SystemExit("SETUP BROKEN: no delegation-boundary tool at %s — the parser lives there "
                         "and is not re-implemented here (T-322)" % path)
    spec = importlib.util.spec_from_file_location("_t770_boundary", path)
    if spec is None or spec.loader is None:
        raise SystemExit("SETUP BROKEN: cannot load a module spec from %s" % path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    for attr in ("parse_task",):
        if not hasattr(mod, attr):
            raise SystemExit("SETUP BROKEN: %s has no %s — the parser contract moved" % (path, attr))
    return mod


def verdict(path, t770=None):
    """Return (verdict, open_human, total_human, detail) for one task file."""
    t770 = t770 or _load_t770()
    task, acs = t770.parse_task(path)

    if (task.get("owner") or "").strip() != "human":
        return (NOT_HUMAN_OWNED, 0, 0,
                "owner is %r, not human" % (task.get("owner") or ""))

    human = [a for a in acs if a["section"] == "Human"]
    open_human = [a for a in human if not a["ticked"]]

    if open_human:
        return (OWNER_JUSTIFIED, len(open_human), len(human),
                "%d open Human criterion/criteria — the field is a live sovereignty claim"
                % len(open_human))

    if human:
        why = ("%d Human criterion/criteria, all ticked — only the human may tick a Human AC, so "
               "the judgement has already been exercised" % len(human))
    else:
        why = "no Human criteria exist — no judgement was ever written down"
    return (OWNER_STALE, 0, len(human), why)


def scan(paths):
    t770 = _load_t770()
    out = []
    for p in sorted(paths):
        v, open_h, total_h, detail = verdict(p, t770)
        task, acs = t770.parse_task(p)
        agent = [a for a in acs if a["section"] != "Human"]
        out.append({
            "task": task["id"], "path": p, "verdict": v,
            "owner": task.get("owner", ""),
            "open_human": open_h, "total_human": total_h,
            "agent_total": len(agent),
            "agent_ticked": sum(1 for a in agent if a["ticked"]),
            "detail": detail,
        })
    return out


def main():
    ap = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[0])
    ap.add_argument("--root", default=".")
    ap.add_argument("--task", help="one task id, e.g. T-885")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--stale-only", action="store_true",
                    help="only OWNER-STALE rows — the set the ruling applies to")
    ap.add_argument("--ready-only", action="store_true",
                    help="OWNER-STALE rows whose Agent ACs are also all ticked: the rubber-stamp queue")
    ap.add_argument("--facts", action="store_true",
                    help="one TSV line for the audit rail: scanned, human-owned, stale, ready, names. "
                         "Mirrors `lib.delegation_cli surface --facts` so the audit needs no heredoc "
                         "of its own — a heredoc inside $(...) is a syntax error `bash -n` does not "
                         "catch, because the substitution body is parsed lazily (hit live here).")
    args = ap.parse_args()

    tid = (args.task or "").strip()
    if tid and not tid.upper().startswith("T-"):
        tid = "T-" + tid            # accept 885 and T-885 alike; the id form is T-NNN
    pattern = os.path.join(args.root, ".tasks/active",
                           "%s-*.md" % tid.upper() if tid else "*.md")
    paths = glob.glob(pattern)
    if not paths:
        print("no task files matched %s" % pattern, file=sys.stderr)
        return 2

    rows = scan(paths)

    if args.facts:
        stale = [r for r in rows if r["verdict"] == OWNER_STALE]
        ready = [r for r in stale if r["agent_total"] > 0
                 and r["agent_ticked"] == r["agent_total"]]
        human = [r for r in rows if r["verdict"] != NOT_HUMAN_OWNED]
        print("%d\t%d\t%d\t%d\t%s" % (len(rows), len(human), len(stale), len(ready),
                                      ", ".join(r["task"] for r in stale[:8])))
        return 0

    if args.ready_only:
        rows = [r for r in rows if r["verdict"] == OWNER_STALE
                and r["agent_total"] > 0 and r["agent_ticked"] == r["agent_total"]]
    elif args.stale_only:
        rows = [r for r in rows if r["verdict"] == OWNER_STALE]

    if args.json:
        print(json.dumps(rows, indent=2))
        return 0

    for r in rows:
        print("%-8s %-16s human %d/%d open  agent %d/%d  %s"
              % (r["task"], r["verdict"], r["open_human"], r["total_human"],
                 r["agent_ticked"], r["agent_total"], r["detail"]))
    if not args.task:
        stale = sum(1 for r in rows if r["verdict"] == OWNER_STALE)
        print("\n%d row(s); OWNER-STALE %d" % (len(rows), stale))
    return 0


if __name__ == "__main__":
    sys.exit(main())
