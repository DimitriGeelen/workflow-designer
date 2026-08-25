#!/usr/bin/env python3
"""T-586 — assert that worktree isolation is denied, by every route it has.

WHY A GUARD AND NOT JUST THE CONFIG. The operator asked twice, in two sessions, whether
we were "stuck in a worktree again". Both times the answer was no and this repo has never
had one. But the question stayed askable because nothing prevented it: `permissions` in
.claude/settings.json was empty, so `EnterWorktree`, `Agent(isolation: "worktree")` and
`git worktree add` were all reachable. Deny rules fix that — and deny rules live in a JSON
file that one careless edit removes, leaving no trace. Their absence looks exactly like
their presence until somebody tests it. So the rules get a guard.

EVERY ROUTE, NOT JUST THE TOOL. Denying `EnterWorktree` alone leaves `git worktree add`
open through Bash, which is the same mistake as gating a surface instead of the capability
behind it. Both are required here.

THIS GUARD ASSERTS PRESENCE, WHICH IS THE EASY DIRECTION TO GET WRONG. A presence
assertion fails loudly when its subject is missing, so it does not have the silent-green
problem an absence assertion has. What it CAN do is pass for the wrong reason — succeed at
reading some file, find nothing it recognises, and report OK. So `--self-test` builds a
fixture with the rules stripped and requires the checker to reject it. If the checker
cannot fail on a file it should reject, it is not checking anything.

Exit: 0 all routes denied · 1 a route is open · 2 could not look (refusal, not a pass)
"""

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SETTINGS = os.path.join(REPO, ".claude", "settings.json")

# Each route worktree isolation can be reached through, and the exact deny rule that
# closes it. Keyed by rule so a partial application is reported per-route rather than
# as one undifferentiated failure.
REQUIRED = {
    "EnterWorktree": "the EnterWorktree tool (harness-native worktree entry)",
    "ExitWorktree": "the ExitWorktree tool",
    "Bash(git worktree:*)": "`git worktree add` and friends via the shell",
}


def check(path):
    """Return (ok, lines) for one settings file. Never raises on bad input."""
    lines = []
    try:
        with open(path) as fh:
            data = json.load(fh)
    except FileNotFoundError:
        return None, [f"CANNOT LOOK: {path} does not exist."]
    except json.JSONDecodeError as exc:
        return None, [f"CANNOT LOOK: {path} is not valid JSON ({exc})."]

    deny = (data.get("permissions") or {}).get("deny") or []
    if not isinstance(deny, list):
        return None, [f"CANNOT LOOK: permissions.deny is {type(deny).__name__}, not a list."]

    ok = True
    for rule, what in REQUIRED.items():
        if rule in deny:
            lines.append(f"  [denied] {rule:24s} {what}")
        else:
            ok = False
            lines.append(f"  [OPEN  ] {rule:24s} {what}  <-- rule missing")
    return ok, lines


def self_test():
    """Prove the checker can reject. Without this, a green run means nothing."""
    import tempfile

    print("SELF-TEST — the checker must FAIL on a file it should reject")
    good = {"permissions": {"deny": list(REQUIRED)}}
    cases = [
        ("all three rules present", good, True),
        ("deny list empty", {"permissions": {"deny": []}}, False),
        ("no permissions key", {"hooks": {}}, False),
        ("tool denied but shell route open",
         {"permissions": {"deny": ["EnterWorktree", "ExitWorktree"]}}, False),
        ("shell denied but tool route open",
         {"permissions": {"deny": ["Bash(git worktree:*)"]}}, False),
    ]
    passed = True
    with tempfile.TemporaryDirectory() as d:
        for name, doc, want in cases:
            p = os.path.join(d, "s.json")
            with open(p, "w") as fh:
                json.dump(doc, fh)
            got, _ = check(p)
            mark = "ok  " if got is want else "FAIL"
            if got is not want:
                passed = False
            print(f"  [{mark}] {name:36s} expected={want}  got={got}")
        # A file the checker cannot read must ABSTAIN (None), never pass.
        p = os.path.join(d, "broken.json")
        with open(p, "w") as fh:
            fh.write("{not json")
        got, _ = check(p)
        mark = "ok  " if got is None else "FAIL"
        if got is not None:
            passed = False
        print(f"  [{mark}] {'unparseable file abstains':36s} expected=None  got={got}")
    print()
    return passed


def main():
    if not self_test():
        print("SELF-TEST FAILED — the checker cannot reject a settings file with the")
        print("rules stripped, so it would report OK regardless of what it read. The")
        print("live file was NOT checked; this tool's silence is not evidence.")
        return 2

    ok, lines = check(SETTINGS)
    print(f"LIVE: {os.path.relpath(SETTINGS, REPO)}")
    for ln in lines:
        print(ln)
    print()
    if ok is None:
        return 2
    if ok:
        print("All worktree routes are denied.")
        return 0
    print("A worktree route is OPEN. Apply the deny rules — .claude/settings.json is")
    print("human-review gated (B-005), so this is the operator's edit, not the agent's:")
    print()
    print('  cd /opt/832-Workflow-designer && python3 -c "import json;p=\'.claude/settings.json\';'
          'd=json.load(open(p));d.setdefault(\'permissions\',{})[\'deny\']='
          '[\'EnterWorktree\',\'ExitWorktree\',\'Bash(git worktree:*)\'];'
          'json.dump(d,open(p,\'w\'),indent=2)" && .agentic-framework/bin/fw enforcement baseline')
    return 1


if __name__ == "__main__":
    sys.exit(main())
