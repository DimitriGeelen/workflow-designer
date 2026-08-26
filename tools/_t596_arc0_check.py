#!/usr/bin/env python3
"""T-596 — the checkable core of the Arc-0 exit gate.

Exit codes are the whole point, so they are documented before anything else:

    0  clause 3 SATISFIED — every blocking question is resolved with a real,
       agreeing source of truth.
    1  BLOCKED — the register is well-formed and honest, and at least one blocking
       question is still open. This is the expected state while Arc 0 is in flight.
       It is not a failure of the gate; it is the gate working.
    2  INTEGRITY VIOLATION — the register itself cannot be trusted: it self-certifies
       a resolution, names a source that does not exist, disagrees with its own source,
       or records the agent as a decision maker.

1 and 2 must stay distinguishable. If they collapsed into "non-zero", a gate that had
gone permanently blind would be indistinguishable from a gate correctly reporting open
work — and the poison controls in --self-test could not tell the two apart either.

WHAT THIS GATE DOES NOT CHECK, stated so nobody reads its output as more than it is:
the Arc-0 exit gate has three clauses. Clauses 1 (topology non-empty and validated) and
2 (every blocker finding has a contract disposition and testable scenario) have no
executable definition yet — "which topology" and "which findings" are not pinned down
anywhere. Only clause 3 is mechanised here. A clause-3 pass is NOT "Arc 0 is done".
"""
import sys
import os
import yaml

AGENT_MAY_NOT_DECIDE = "agent"


def load(path):
    with open(path, encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def check(register_path, envelope_path, root):
    problems = []   # integrity violations -> exit 2
    open_qs = []    # legitimately unanswered -> exit 1
    resolved = []

    try:
        reg = load(register_path)
    except Exception as exc:
        return 2, [f"register does not parse: {exc}"], [], []

    questions = (reg or {}).get("questions")
    if not questions:
        return 2, ["register carries no questions"], [], []

    for q in questions:
        qid = q.get("id", "<no id>")
        status = q.get("status")

        if status not in ("open", "resolved"):
            problems.append(f"{qid}: status {status!r} is neither open nor resolved")
            continue

        if q.get("decided_by") == AGENT_MAY_NOT_DECIDE:
            problems.append(
                f"{qid}: decided_by is 'agent' — an agent may recommend, never decide"
            )
            continue

        if status == "open":
            if q.get("blocks_arc_0_exit"):
                open_qs.append(qid)
            continue

        # status == resolved: it must be corroborated from outside the register (PL-148).
        sot = q.get("source_of_truth")
        if not sot or not sot.get("file"):
            problems.append(
                f"{qid}: resolved with no source_of_truth — the register is "
                f"self-certifying, which is the defect T-593 removed from the envelope"
            )
            continue

        sot_path = os.path.join(root, sot["file"])
        if not os.path.exists(sot_path):
            problems.append(f"{qid}: source_of_truth file is absent: {sot['file']}")
            continue

        if not q.get("decided_by"):
            problems.append(f"{qid}: resolved with no decided_by")
            continue

        resolved.append(qid)

    # H2 is the one entry whose source is machine-readable, so it gets a real
    # field-by-field agreement check rather than a mere existence check.
    h2 = next((q for q in questions if q.get("id") == "H2"), None)
    if h2 and h2.get("status") == "resolved":
        try:
            env = load(envelope_path)["to_project_resolution"]
        except Exception as exc:
            problems.append(f"H2: envelope unreadable, agreement uncheckable: {exc}")
        else:
            if env.get("status") != "resolved":
                problems.append(
                    "H2: register says resolved, envelope does not — the register "
                    "is ahead of its own source"
                )
            for field in ("chosen", "decided_by"):
                if h2.get(field) != env.get(field):
                    problems.append(
                        f"H2: register and envelope disagree on {field!r}: "
                        f"{h2.get(field)!r} vs {env.get(field)!r}"
                    )

    if problems:
        return 2, problems, open_qs, resolved
    if open_qs:
        return 1, [], open_qs, resolved
    return 0, [], [], resolved


def main():
    register, envelope, root = sys.argv[1], sys.argv[2], sys.argv[3]
    quiet = "--quiet" in sys.argv
    code, problems, open_qs, resolved = check(register, envelope, root)

    if not quiet:
        print("Arc-0 exit gate — clause 3: no unresolved source-of-truth ambiguity")
        print("  clause 1 (topology validated)        NOT-CHECKED — no executable definition")
        print("  clause 2 (blocker dispositions)      NOT-CHECKED — no executable definition")
        if problems:
            print("  clause 3                             INTEGRITY VIOLATION")
            for p in problems:
                print(f"      ! {p}")
        elif open_qs:
            print(f"  clause 3                             BLOCKED by {len(open_qs)} open question(s)")
            print(f"      open:     {', '.join(open_qs)}")
            print(f"      resolved: {', '.join(resolved) or 'none'}")
            print("      Arc 1 cannot start until the open ids are answered by the operator.")
        else:
            print("  clause 3                             SATISFIED")
            print(f"      resolved: {', '.join(resolved)}")
            print("      NOTE: clauses 1 and 2 remain unchecked. This is not 'Arc 0 is done'.")
    sys.exit(code)


if __name__ == "__main__":
    main()
