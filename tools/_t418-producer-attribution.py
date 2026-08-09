#!/usr/bin/env python3
"""
_t418-producer-attribution.py — is a sender fingerprint on this hub attributable
to ONE producer, or to several?

T-418. Triggered by AEF rail 509, generalised past it.

WHAT THIS ANSWERS
-----------------
When a peer's post arrives, "who sent this" has two candidate answers and they are
not the same answer:

    sender_id       cryptographic, hub-derived from sender_pubkey_hex (T-1427),
                    cannot be forged -- and on this substrate is a HOST identity,
                    not a project identity.
    from_project    free text in the envelope's metadata map. Distinguishes
                    co-resident producers that cooperate. Proves nothing about
                    one that does not, because nothing signs it.

AEF reported at 509 that their post went out under `d1993c2c3ec44c94` and called it
"this host's key". Measured here: our own shell `termlink` CLI signs as the SAME
fingerprint (identity.key), while our MCP surface signs as `6a646ce8b1bc6560`
(identity.json). So the co-resident they warned us about is us.

WHY THE DETECTOR AND NOT A NOTE
--------------------------------
The cheap remedy is a comment naming `d1993c2c3ec44c94` as collapsed. That closes the
member in hand and leaves the class -- the exact shape both projects have now hit on a
gitignore, a word list and an id allocator. So this takes NO fingerprint as input:
it partitions whatever capture it is given and reports every sender that fails to be
project-unique, whichever sender that turns out to be.

TWO DISTINCT VERDICTS, DELIBERATELY NOT MERGED
-----------------------------------------------
  AMBIGUOUS     one fingerprint, >1 distinct from_project. Attribution is WRONG:
                a reader keying on the fingerprint routes some posts to the wrong
                producer. (Live example: 002-Claude-Partner-Network and
                999-agentic-engineering-framework on one key.)
  UNATTRIBUTED  content posts carrying no from_project at all. Attribution is
                ABSENT: nothing to be wrong, and nothing to act on either.

They are not the same failure and a remedy for one does not touch the other. AEF's
rail 508 is UNATTRIBUTED; their 509 is attributable and lands in the AMBIGUOUS set
alongside two unrelated projects.

CAPTURE / VERDICT SPLIT (T-360, reused on purpose)
---------------------------------------------------
This reads a captured JSONL and never touches the network. rail-sweep.py had to make
the same split for a harder reason -- shelling out to `termlink` runs as a DIFFERENT
AGENT and returns a confident answer about somebody else's rails. Here the split buys
determinism for the teeth, and it keeps the fixture payload-free: attribution needs
`{offset, sender_id, msg_type, metadata}` and nothing else, so no message body is ever
written to disk by the capture step. (T-417: a 1.6MB rail dump reached a tracked tree
because the capture kept bytes it did not need.)

EXIT CODES -- the verdict is the exit code
-------------------------------------------
  0  every sender in the capture is project-unique
  1  at least one sender is AMBIGUOUS or UNATTRIBUTED
  2  usage / unreadable capture
"""

import json
import os
import sys
from collections import OrderedDict

# Envelope msg_types that are not content. Attribution is a question about who SAID
# something; receipts and reactions are bookkeeping and a topic_metadata envelope is
# written by whoever created the topic, not by a participant.
META_TYPES = {"receipt", "reaction", "redaction", "edit", "topic_metadata"}


def load(paths):
    """Read capture rows. Tolerates blank lines; a malformed row is fatal, not skipped
    -- a capture we cannot fully parse cannot support an all-clear."""
    rows = []
    for p in paths:
        with open(p, encoding="utf-8") as fh:
            for n, line in enumerate(fh, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    rows.append((p, json.loads(line)))
                except json.JSONDecodeError as exc:
                    raise SystemExit("ERROR: %s line %d is not JSON: %s" % (p, n, exc))
    return rows


def partition(rows):
    """sender_id -> {projects: OrderedDict(project -> count), unlabelled: int, total: int}"""
    by_sender = OrderedDict()
    for _, env in rows:
        if env.get("msg_type") in META_TYPES:
            continue
        sender = env.get("sender_id")
        if sender is None:
            raise SystemExit("ERROR: capture row has no sender_id; refusing to grade it")
        slot = by_sender.setdefault(
            sender, {"projects": OrderedDict(), "unlabelled": 0, "total": 0}
        )
        slot["total"] += 1
        meta = env.get("metadata") or {}
        proj = meta.get("from_project")
        if proj:
            slot["projects"][proj] = slot["projects"].get(proj, 0) + 1
        else:
            slot["unlabelled"] += 1
    return by_sender


def self_check(rows, project, identity):
    """Which of OUR OWN posts went out under a key that is not our MCP identity?

    Separate from the topic-wide verdict on purpose. "some peer's attribution is
    broken" is a reading problem; "our own outbound is mis-signed" is a problem we
    hand to everyone who reads us, and only we can fix it. AEF hit this at their 508
    and told us; we had been doing it since offset 75 without noticing.

    `project` and `identity` are ARGUMENTS, not literals — `identity` should come from
    the MCP `agent_identity` surface at call time. A fingerprint baked in here would be
    the same close-the-member-in-hand move this whole detector exists to avoid.
    """
    strays = []
    for _, env in rows:
        if env.get("msg_type") in META_TYPES:
            continue
        meta = env.get("metadata") or {}
        if meta.get("from_project") == project and env.get("sender_id") != identity:
            strays.append((env.get("topic"), env.get("offset"), env.get("sender_id")))
    return strays


def main(argv):
    args = [a for a in argv[1:] if not a.startswith("--")]
    want_self = "--self" in argv[1:]
    if not args:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        print("usage: %s [--self] <capture.jsonl> [more.jsonl ...]" % argv[0],
              file=sys.stderr)
        print("  --self  also report OUR posts signed by a key that is not ours;\n"
              "          reads T418_PROJECT and T418_IDENTITY from the environment",
              file=sys.stderr)
        return 2
    try:
        rows = load(args)
    except OSError as exc:
        print("ERROR: %s" % exc, file=sys.stderr)
        return 2

    by_sender = partition(rows)
    if not by_sender:
        # An empty capture is not a clean bill of health -- it is an absent measurement,
        # and absence cannot carry a verdict (G-022, the whole point of rail-sweep).
        print("REFUSED: capture holds no content envelopes — nothing was measured.",
              file=sys.stderr)
        return 2

    print("=== T-418 producer attribution (%d content envelope(s), %d sender(s)) ==="
          % (sum(s["total"] for s in by_sender.values()), len(by_sender)))

    bad = 0
    for sender, slot in by_sender.items():
        projects = list(slot["projects"].items())
        verdicts = []
        if len(projects) > 1:
            verdicts.append("AMBIGUOUS")
        if slot["unlabelled"]:
            verdicts.append("UNATTRIBUTED")
        shown = ", ".join("%s x%d" % (p, c) for p, c in projects) or "(none)"
        if verdicts:
            bad += 1
            print("  FAIL %s  %s" % (sender, "+".join(verdicts)))
            print("       projects: %s" % shown)
            if slot["unlabelled"]:
                print("       %d content post(s) carry no from_project"
                      % slot["unlabelled"])
        else:
            print("  ok   %s  project-unique (%s)" % (sender, shown))

    if want_self:
        project = os.environ.get("T418_PROJECT")
        identity = os.environ.get("T418_IDENTITY")
        if not project or not identity:
            print("ERROR: --self needs T418_PROJECT and T418_IDENTITY in the environment."
                  " Refusing to guess — a self-check against the wrong identity returns a"
                  " confident answer about somebody else.", file=sys.stderr)
            return 2
        strays = self_check(rows, project, identity)
        print()
        print("--- self-check: posts claiming %s, signed by another key ---" % project)
        if strays:
            bad += 1
            for topic, offset, sender in strays:
                print("  FAIL offset=%-5s signed=%s  (ours is %s)  %s"
                      % (offset, sender, identity, topic))
            print("  %d of our own post(s) are indistinguishable, on the key, from any"
                  " co-resident agent." % len(strays))
        else:
            print("  ok   every post claiming %s is signed %s" % (project, identity))

    print()
    if bad:
        print("NOT PROJECT-UNIQUE — %d sender(s)/check(s) failed. A reader keying on the\n"
              "fingerprint attributes these posts to the wrong producer, or to none." % bad,
              file=sys.stderr)
        return 1
    print("ATTRIBUTABLE — every sender in this capture carries exactly one from_project")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
