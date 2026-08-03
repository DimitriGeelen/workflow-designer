#!/usr/bin/env python3
"""
rail-sweep.py — enumerate every rail carrying MY fingerprint, and refuse to
report all-clear from a source that cannot tell "nothing unread" from
"nothing tracked".

T-360. Prevention for G-022.

WHY THIS EXISTS
---------------
For ~24 days I reported "AEF is silent". That sentence was a one-topic
measurement wearing the clothes of a fact about a peer. The natural check --
`termlink agent inbox` -- returns `unread_topics: []` in TWO different
situations that are byte-identical on the wire:

    (a) nothing is unread                       <- reassuring, and true
    (b) this identity has no cursor store       <- uninformative, and silent

Its documentation says so outright: "When the cursor store is empty (never ran
`subscribe --resume`) returns `unread_topics:[]` with `ok:true`." An absent
measurement is being rendered in the vocabulary of a clean bill of health.
Absence cannot carry a decision. This sweep's whole job is to refuse that.

Measured 2026-08-03T21:13:52Z, same identity, same instant:

    agent_dms   --unread  ->  2 topics,  99 unread   (content walk)
    agent_inbox           ->  0 topics,   0 unread   (cursor store)

Both `ok: true`. Both `my_id: 6a646ce8b1bc6560`. They disagree by 99 messages.

WHY THIS IS NOT A SHELL SCRIPT THAT SHELLS OUT TO `termlink`
------------------------------------------------------------
Because that is the trap, not the fix. Probed 2026-08-03:

    MCP  agent_identity  -> fingerprint 6a646ce8b1bc6560, path /root/.termlink/identity.json
    shell `termlink agent identity`
                         -> fingerprint d1993c2c3ec44c94, path /root/.termlink/identity.key

and the path the MCP surface names does not exist in the shell's view of the
filesystem at all. So the obvious remedy -- "just double-check from the CLI" --
runs as a DIFFERENT AGENT and returns a confident, well-formed, entirely
plausible answer about somebody else's rails. A wrong answer that looks exactly
like a right one, produced by the very tool you would reach for to verify the
first tool.

Consequence for the design: the CAPTURE can only happen through the MCP
surface. This script VERIFIES a capture; it does not gather one. That split is
load-bearing, not a limitation worked around -- which is why check 3 exists.

CHECKS (each one can fail; see tools/_t360-rail-sweep-teeth.py)
--------------------------------------------------------------
  1 SNAPSHOT   snapshot present and parseable
  2 FRESHNESS  captured recently -- a sweep re-reading yesterday's capture is
               the same defect in a new costume
  3 IDENTITY   identity.fingerprint == dms.my_id == inbox.my_id
               "assert your own fingerprint matches the identity whose topics
               you enumerate, or you inherit the defect"
  4 MEMBERSHIP every enumerated topic actually carries that fingerprint
  5 TRUST      if the cursor store is empty while the content walk sees topics,
               the cursor store is UNTRACKED -> its all-clear is REFUSED
  6 BACKLOG    report per-topic unread from the cursor-store-INDEPENDENT source
  7 FRONTIER   a watchlist channel with ack_up_to == 0 has NO frontier set. Its
               "unread" is the whole retained window, not a personal backlog.
               That is an absent measurement, so it cannot carry an all-clear.
  8 COVERAGE   print the non-DM denominator. DM coverage is exhaustive; channel
               coverage is watchlist-scoped. The sweep must never let the second
               masquerade as the first -- that is G-022 one level up, and it is
               how "AEF is silent" happened in the first place. State the gap as
               a number, because a silence is what got us here.

SCOPE, STATED PLAINLY
---------------------
  DM topics      EXHAUSTIVE. Every dm: shape carrying my fingerprint.
  Non-DM topics  WATCHLIST ONLY. 549 non-DM topics exist on this hub; the
                 watchlist names a handful. Absence from this report is NOT
                 evidence of absence of traffic. Widen the watchlist, do not
                 read silence as quiet.

EXIT CODES -- the verdict is the exit code, not the prose
---------------------------------------------------------
   0  ALL-CLEAR   trustworthy, and genuinely zero unread
   1  BACKLOG     trustworthy enumeration, unread > 0 -- go read them
   2  UNKNOWN     cannot answer (missing/unparseable/stale snapshot)
   3  UNTRUSTED   an all-clear was available and was REFUSED
   4  IDENTITY    the enumeration is scoped to somebody else
   5  MEMBERSHIP  a topic surfaced that does not carry my fingerprint

Note 0 and 1 are both "the sweep worked". Everything >=2 means the sweep
declines to answer. It never exits 0 by defaulting.
"""

import argparse
import datetime as dt
import json
import sys

DEFAULT_SNAPSHOT = ".context/working/rail-snapshot.json"
DEFAULT_MAX_AGE_MIN = 90

EXIT_OK, EXIT_BACKLOG, EXIT_UNKNOWN = 0, 1, 2
EXIT_UNTRUSTED, EXIT_IDENTITY, EXIT_MEMBERSHIP = 3, 4, 5


def die(code, label, *lines):
    print(f"VERDICT: {label}")
    for ln in lines:
        print(f"  {ln}")
    return code


def topic_sides(topic):
    """dm:<a>:<b> -> {a, b}. Non-dm topics have no fingerprint sides."""
    parts = topic.split(":")
    if len(parts) == 3 and parts[0] == "dm":
        return {parts[1], parts[2]}
    return set()


def run(path, max_age_min, now=None):
    # --- 1 SNAPSHOT ---------------------------------------------------------
    try:
        with open(path) as fh:
            snap = json.load(fh)
    except FileNotFoundError:
        return die(EXIT_UNKNOWN, "UNKNOWN — no snapshot",
                   f"{path} does not exist.",
                   "A capture must be taken through the MCP termlink surface first.",
                   "NOT reported as all-clear: no measurement was taken.")
    except (json.JSONDecodeError, OSError) as exc:
        return die(EXIT_UNKNOWN, "UNKNOWN — snapshot unreadable", f"{path}: {exc}")

    # --- 2 FRESHNESS --------------------------------------------------------
    now = now or dt.datetime.now(dt.timezone.utc)
    raw = snap.get("captured_at")
    if not raw:
        return die(EXIT_UNKNOWN, "UNKNOWN — snapshot has no captured_at",
                   "An undated capture cannot be shown to be current.")
    try:
        when = dt.datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return die(EXIT_UNKNOWN, "UNKNOWN — captured_at unparseable", f"captured_at={raw!r}")
    age_min = (now - when).total_seconds() / 60.0
    if age_min > max_age_min:
        return die(EXIT_UNKNOWN, "UNKNOWN — stale snapshot",
                   f"captured {age_min:.0f} min ago; limit is {max_age_min} min.",
                   "Re-capture through the MCP surface. A stale all-clear is not an all-clear.")

    # --- 3 IDENTITY ---------------------------------------------------------
    mine = (snap.get("identity") or {}).get("fingerprint")
    dms_blob = snap.get("dms") or {}
    inbox_blob = snap.get("inbox") or {}
    dms_id = dms_blob.get("my_id")
    inbox_id = inbox_blob.get("my_id")

    if not mine:
        return die(EXIT_IDENTITY, "IDENTITY — snapshot does not state whose rails these are",
                   "identity.fingerprint is missing.")
    seen = {"identity": mine, "dms.my_id": dms_id, "inbox.my_id": inbox_id}
    disagree = {k: v for k, v in seen.items() if v != mine}
    if disagree:
        return die(EXIT_IDENTITY, "IDENTITY MISMATCH — this enumeration is scoped to somebody else",
                   f"my fingerprint: {mine}",
                   *(f"{k} says: {v}" for k, v in disagree.items()),
                   "This is exactly the G-022 failure mode. Refusing to report on another agent's rails.")

    # --- 4 MEMBERSHIP -------------------------------------------------------
    rows = dms_blob.get("dms") or []
    foreign = [r for r in rows
               if topic_sides(r.get("topic", "")) and mine not in topic_sides(r.get("topic", ""))]
    if foreign:
        return die(EXIT_MEMBERSHIP, "MEMBERSHIP — a topic surfaced that does not carry my fingerprint",
                   *(f"{r.get('topic')}" for r in foreign),
                   f"expected every dm topic to have {mine} on one side.")

    # --- 5 TRUST ------------------------------------------------------------
    cursor_topics = inbox_blob.get("unread_topics")
    cursor_untracked = (cursor_topics == [] and len(rows) > 0)

    # --- 6 BACKLOG ----------------------------------------------------------
    total = sum(int(r.get("unread") or 0) for r in rows)

    # --- 7 FRONTIER / 8 COVERAGE -------------------------------------------
    chan = snap.get("channels") or {}
    watch = chan.get("watchlist") or []
    population = chan.get("population_non_dm")
    # An unset frontier only MATTERS when something sits past it. Keying on
    # total>0 instead of last_offset>ack_up_to flags topics whose single
    # envelope is at offset 0 -- an over-broad matcher manufacturing findings,
    # which is its own way of making a report untrustworthy.
    unset = [c for c in watch
             if int(c.get("ack_up_to") or 0) == 0 and int(c.get("last_offset") or 0) > 0]

    print(f"identity   : {mine}")
    print(f"captured   : {raw}  ({age_min:.0f} min ago)")
    print(f"source     : content walk (cursor-store-independent)")
    print()
    print(f"DM topics  : {len(rows)}   [coverage: EXHAUSTIVE]")
    for r in sorted(rows, key=lambda x: -int(x.get("unread") or 0)):
        print(f"  {r.get('topic')}  unread={r.get('unread')}  first_unread={r.get('first_unread')}")
    print(f"  -> {total} unread across {len(rows)} DM topic(s)")
    print()

    if population is None:
        print("channels   : NOT MEASURED   [coverage: UNKNOWN]")
    else:
        print(f"channels   : {len(watch)} watched of {population} non-DM topics on hub"
              f"   [coverage: WATCHLIST-SCOPED, NOT EXHAUSTIVE]")
    for c in watch:
        frontier = int(c.get("ack_up_to") or 0)
        if frontier == 0 and int(c.get("last_offset") or 0) > 0:
            print(f"  {c.get('topic')}  FRONTIER UNSET (ack_up_to=0) — "
                  f"'{c.get('unread_count')} unread' is the whole retained window "
                  f"[{c.get('first_unread')}..{c.get('last_offset')}], not a personal backlog")
        else:
            print(f"  {c.get('topic')}  ack_up_to={frontier}  unread={c.get('unread_count')}")
    if population is not None and len(watch) < population:
        print(f"  -> {population - len(watch)} non-DM topic(s) NOT swept. Absence from this")
        print("     report is not evidence of quiet.")
    print()

    if cursor_untracked:
        return die(EXIT_UNTRUSTED, "UNTRUSTED — cursor-store all-clear REFUSED",
                   f"agent_inbox reports unread_topics: [] for {mine},",
                   f"while the content walk sees {len(rows)} topic(s) and {total} unread.",
                   "An empty cursor store and an empty backlog are byte-identical on that surface.",
                   "Reporting UNKNOWN rather than inheriting the ambiguity.",
                   "Fix: run `subscribe --resume` for THIS identity, or keep using the content walk.")

    if total > 0:
        return die(EXIT_BACKLOG, f"BACKLOG — {total} unread across {len(rows)} DM topic(s)",
                   "Trustworthy enumeration. Go read them before saying anyone is silent.")

    if unset:
        return die(EXIT_UNTRUSTED, "UNTRUSTED — a watched channel has no ack frontier",
                   *(f"{c.get('topic')}: ack_up_to=0 over {c.get('total')} retained envelope(s)"
                     for c in unset),
                   "With no frontier there is no 'unread' to be zero. That is an absent",
                   "measurement, and an absent measurement cannot carry an all-clear.",
                   "Fix: ack once on the topic to establish a frontier, then re-capture.")

    return die(EXIT_OK, "ALL-CLEAR",
               f"{len(rows)} DM topic(s) carrying {mine}, zero unread,",
               f"{len(watch)} watched channel(s) with a real frontier and nothing past it,",
               "and the cursor store was corroborated rather than assumed.",
               f"NOTE: still watchlist-scoped over {population} non-DM topics."
               if population else "NOTE: channel population not measured.")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[1])
    ap.add_argument("--snapshot", default=DEFAULT_SNAPSHOT)
    ap.add_argument("--max-age-min", type=float, default=DEFAULT_MAX_AGE_MIN)
    args = ap.parse_args()
    sys.exit(run(args.snapshot, args.max_age_min))


if __name__ == "__main__":
    main()
