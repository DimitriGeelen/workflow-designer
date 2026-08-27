#!/usr/bin/env python3
"""T-597 — evaluate all three Arc-0 exit clauses, including the ones we do not own.

Exit codes match _t596_arc0_check.py deliberately, so the two read the same way:

    0  every blocking clause satisfied
    1  BLOCKED — well-formed, and at least one clause is not satisfied. Expected.
    2  INTEGRITY VIOLATION — the clause register cannot be trusted.

THE POINT OF THIS FILE (PL-034)

A guard that checks internal self-consistency cannot detect a broken promise to an
external party. Clauses 1 and 2 belong to the AEF agent: their evidence lives in a
repository this one cannot read. Contact is mandated by roadmap §2.1/§2.3. Everything
observable from here is silent about them, and silence is not a pass.

So a counterparty-owned clause is satisfiable ONLY by a recorded attestation naming who
attested and when. Absent that, it is BLOCKED — never satisfied, and never reported as a
Designer-side defect either, which is the opposite error and just as wrong.

Two integrity rules keep the register from certifying itself:

  * A clause may not be satisfied while its definition is unratified. The agent wrote
    these definitions from the roadmap's fence text; an agent that may both invent the
    property and declare it met has certified nothing.
  * A clause's `owner` must agree with the roadmap's own §2.1 ownership table, derived by
    reading which column contains the clause's key phrase. The register records what the
    roadmap says; it does not get a vote.
"""
import sys
import re
import yaml

COLUMN_SIDE = {2: "aef", 3: "designer"}


def derive_owner_from_roadmap(roadmap_path, ownership_line, key_phrase):
    """Return the side whose column contains key_phrase, per the roadmap's Arc-0 row.

    Reads the table row rather than trusting the register, so a register that reassigns
    ownership to whichever side makes the gate convenient is caught.
    """
    with open(roadmap_path, encoding="utf-8") as fh:
        lines = fh.readlines()
    row = lines[ownership_line - 1]
    cells = [c.strip() for c in row.split("|")]
    for idx, side in COLUMN_SIDE.items():
        if idx < len(cells) and key_phrase.lower() in cells[idx].lower():
            return side
    return None


def check(clause_path, roadmap_path, h_gate_result):
    problems = []
    blocked = []
    satisfied = []

    try:
        reg = yaml.safe_load(open(clause_path, encoding="utf-8"))
    except Exception as exc:
        return 2, [f"clause register does not parse: {exc}"], [], []

    clauses = (reg or {}).get("clauses")
    if not clauses:
        return 2, ["clause register carries no clauses"], [], []

    ownership_line = int(str(reg.get("ownership_table", "")).rsplit(":", 1)[-1] or 0)
    if not ownership_line:
        return 2, ["clause register names no ownership_table line to corroborate against"], [], []

    # The roadmap must still say what the register claims it says. If the table moved or was
    # edited, corroboration is impossible and that is an integrity failure, not a pass.
    corr = reg.get("ownership_corroboration") or {}
    with open(roadmap_path, encoding="utf-8") as fh:
        row = fh.readlines()[ownership_line - 1]
    cells = [c.strip() for c in row.split("|")]
    for phrase in corr.get("aef_column_must_contain", []):
        if len(cells) <= 2 or phrase.lower() not in cells[2].lower():
            problems.append(
                f"ownership table at line {ownership_line} no longer carries "
                f"{phrase!r} in the AEF column — corroboration base has moved"
            )
    for phrase in corr.get("designer_column_must_contain", []):
        if len(cells) <= 3 or phrase.lower() not in cells[3].lower():
            problems.append(
                f"ownership table at line {ownership_line} no longer carries "
                f"{phrase!r} in the Designer column — corroboration base has moved"
            )

    for c in clauses:
        cid = c.get("id", "<no id>")
        owner = c.get("owner")
        method = (c.get("evaluation") or {}).get("method")

        key = c.get("roadmap_key_phrase")
        if key:
            derived = derive_owner_from_roadmap(roadmap_path, ownership_line, key)
            if derived is None:
                problems.append(
                    f"{cid}: key phrase {key!r} appears in no ownership column — "
                    f"ownership claim is uncorroborated"
                )
                continue
            if derived != owner:
                problems.append(
                    f"{cid}: register says owner={owner!r} but the roadmap's own "
                    f"ownership table puts {key!r} in the {derived!r} column"
                )
                continue

        satisfied_claim = bool(c.get("satisfied"))

        if satisfied_claim and not c.get("definition_ratified"):
            problems.append(
                f"{cid}: claims satisfied while definition_ratified is false — an "
                f"agent-proposed property cannot certify itself"
            )
            continue

        if method == "counterparty-attestation":
            att = c.get("attestation")
            if satisfied_claim and not att:
                problems.append(
                    f"{cid}: counterparty-owned clause claims satisfied with no "
                    f"attestation — nothing visible from this repository can certify it"
                )
                continue
            if att and not (att.get("attested_by") and att.get("attested_at")):
                problems.append(f"{cid}: attestation is missing attested_by/attested_at")
                continue
            if satisfied_claim:
                satisfied.append(cid)
            elif c.get("blocks_arc_0_exit"):
                blocked.append((cid, f"awaiting attestation from {owner}"))

        elif method == "local-register":
            # Clause 3 defers to the H-register gate, whose verdict is passed in.
            if h_gate_result == 0:
                satisfied.append(cid)
            elif h_gate_result == 2:
                problems.append(f"{cid}: H-register reports an integrity violation")
            elif c.get("blocks_arc_0_exit"):
                blocked.append((cid, "open operator decisions in the H-register"))

        else:
            problems.append(f"{cid}: unknown evaluation method {method!r}")

    if problems:
        return 2, problems, blocked, satisfied
    if blocked:
        return 1, [], blocked, satisfied
    return 0, [], [], satisfied


def main():
    clause_path, roadmap_path, h_result = sys.argv[1], sys.argv[2], int(sys.argv[3])
    quiet = "--quiet" in sys.argv
    code, problems, blocked, satisfied = check(clause_path, roadmap_path, h_result)

    if not quiet:
        print("Arc-0 exit gate — all three clauses")
        if problems:
            print("  INTEGRITY VIOLATION")
            for p in problems:
                print(f"      ! {p}")
        else:
            for cid in satisfied:
                print(f"  {cid:<10} SATISFIED")
            for cid, why in blocked:
                print(f"  {cid:<10} BLOCKED — {why}")
            if blocked:
                print()
                # T-610: the previous wording said the attestation needed "a counterparty
                # we have no authorisation to contact". That was never true and the
                # operator corrected it: roadmap §2.1 carries a "Required joint handoff"
                # column for every arc and §7 is "Recommended AEF-agent handoff" —
                # collaboration is the structure of the instruction set, not a permission.
                # A gate that states an invented constraint teaches it to every reader,
                # and this one stalled Arc 0 for three sessions.
                print("  Clauses 1 and 2 are owned by the AEF agent (roadmap §2.1, Arc 0 row).")
                print("  No amount of Designer-side work closes them; they need an attestation")
                print("  from AEF. Requested 2026-08-27 on agent-chat-arc offset 602,")
                print("  thread EWCR-ARC0-ATTEST-832, under the roadmap §2.3 envelope.")
                print("  Awaiting a substantive accepted/refused/needs-decision response —")
                print("  §2.3: transport is not collaboration completion. Arc 0 stays open")
                print("  until that response lands AND the operator ratifies the definitions.")
    sys.exit(code)


if __name__ == "__main__":
    main()
