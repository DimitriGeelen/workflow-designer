#!/usr/bin/env python3
"""Census of DEAD-leg honesty notes in BPMN maps.

Convention (pair round #4, rail 324/325, AEF knowledge-leveling v3): a
dead-but-reachable leg — control flow that is drawn live because it is
structurally reachable, but whose real-world trigger is broken/unbuilt —
carries an `aef:meta` note containing the token `DEAD:` (in practice
inline: context first, then "DEAD: <what is dead>"). Each note counts once
regardless of token position.

SCAN CONTRACT (rail 325, pinned by AEF at adoption): census tooling reads
ONLY the `note` attribute of `aef:meta` elements. Never raw-text grep the
file — header comments explaining the convention mention the token too
(knowledge-leveling v3: 4 real DEAD legs, 9 raw-text hits). Same defect
class as PL-060 (T-302's phantom [REVIEWER] census from template comments).

Usage:
    python3 tools/census-dead-legs.py FILE [FILE...]
    python3 tools/census-dead-legs.py examples/aef-processes/rendered/*.bpmn

Prints per-file counts with the leg's owning element id, then a total.
Exit 0 always — this is a census, not a gate.
"""
import sys
import xml.etree.ElementTree as ET

TOKEN = "DEAD:"


def census(path):
    """Return [(element_id, note_text), ...] for notes carrying DEAD: in one file.

    Scans aef:meta note attributes only (see scan contract above).
    """
    root = ET.parse(path).getroot()
    parent_of = {child: parent for parent in root.iter() for child in parent}
    hits = []
    for el in root.iter():
        if el.tag.endswith("}meta") or el.tag == "meta":
            note = el.get("note") or ""
            if TOKEN in note:
                # climb to the owning flow element (aef:meta usually sits
                # inside extensionElements, which has no id of its own)
                owner = parent_of.get(el)
                while owner is not None and not owner.get("id"):
                    owner = parent_of.get(owner)
                hits.append((owner.get("id") if owner is not None else "?", note))
    return hits


def main(argv):
    if not argv:
        print(__doc__)
        return 0
    total = 0
    for path in argv:
        hits = census(path)
        total += len(hits)
        print(f"{path}: {len(hits)}")
        for eid, note in hits:
            print(f"  {eid}: {note[:100]}")
    print(f"total: {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
