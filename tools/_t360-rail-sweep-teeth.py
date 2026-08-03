#!/usr/bin/env python3
"""
_t360-rail-sweep-teeth.py — prove rail-sweep.py can FAIL, and can also PASS.

T-360 teeth. Reading a guard tells you it was written. Breaking the tree tells
you it works. Every case below mutates one thing and asserts the verdict moves.

Two of these matter more than the rest:

  CAN-PASS      a sweep that can never say ALL-CLEAR is not a sweep, it is an
                alarm stuck on. If case `clean` did not exit 0, the UNTRUSTED
                verdict would be a constant and would discriminate nothing.

  DISCRIMINATES the two sources must actually disagree on the LIVE snapshot.
                If cursor store and content walk agreed, this whole sweep would
                be measuring a difference that isn't there, and would pass for
                the wrong reason.

Run: python3 tools/_t360-rail-sweep-teeth.py
Exit 0 = every mutation moved the verdict the way it was predicted to.
"""

import datetime as dt
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SWEEP = os.path.join(HERE, "rail-sweep.py")
LIVE = os.path.join(os.path.dirname(HERE), ".context", "working", "rail-snapshot.json")

MINE = "6a646ce8b1bc6560"
KNOWN_MISS = "dm:6a646ce8b1bc6560:d1993c2c3ec44c94"
AEF_RAIL = "dm:0e7ee6cad65137fc:6a646ce8b1bc6560"

OK, BACKLOG, UNKNOWN, UNTRUSTED, IDENTITY, MEMBERSHIP = 0, 1, 2, 3, 4, 5
NAME = {0: "ALL-CLEAR", 1: "BACKLOG", 2: "UNKNOWN", 3: "UNTRUSTED",
        4: "IDENTITY", 5: "MEMBERSHIP"}


def fresh():
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def base():
    """The real shape, stamped now so freshness is not what is under test."""
    return {
        "captured_at": fresh(),
        "identity": {"fingerprint": MINE},
        "dms": {"ok": True, "my_id": MINE, "dms": [
            {"topic": AEF_RAIL, "peer": "0e7ee6cad65137fc", "unread": 95, "first_unread": 329},
            {"topic": KNOWN_MISS, "peer": "d1993c2c3ec44c94", "unread": 4, "first_unread": 1},
        ]},
        "inbox": {"ok": True, "my_id": MINE, "unread_topics": []},
    }


def run(snap, extra=()):
    """Write snap to a temp file, run the sweep, return (exit, stdout)."""
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as fh:
        if snap is not None:
            fh.write(snap if isinstance(snap, str) else json.dumps(snap))
        path = fh.name
    try:
        if snap is None:
            os.unlink(path)
        p = subprocess.run([sys.executable, SWEEP, "--snapshot", path, *extra],
                           capture_output=True, text=True)
        return p.returncode, p.stdout
    finally:
        if os.path.exists(path):
            os.unlink(path)


CASES = []


def case(label, want, mutate=None, extra=(), snap="base"):
    CASES.append((label, want, mutate, extra, snap))


# ── 1 SNAPSHOT ──────────────────────────────────────────────────────────────
case("no snapshot file at all", UNKNOWN, snap=None)
case("snapshot is not JSON", UNKNOWN, snap="{ this is not json")

# ── 2 FRESHNESS ─────────────────────────────────────────────────────────────
case("captured_at removed", UNKNOWN, lambda s: s.pop("captured_at"))
case("captured_at unparseable", UNKNOWN, lambda s: s.update(captured_at="last tuesday"))
case("snapshot is 3 hours old", UNKNOWN,
     lambda s: s.update(captured_at=(dt.datetime.now(dt.timezone.utc)
                                     - dt.timedelta(hours=3)).strftime("%Y-%m-%dT%H:%M:%SZ")))

# ── 3 IDENTITY — the assertion the root cause demands ───────────────────────
case("identity.fingerprint missing", IDENTITY, lambda s: s["identity"].pop("fingerprint"))
case("dms enumerated for the CLI identity instead of mine", IDENTITY,
     lambda s: s["dms"].update(my_id="d1993c2c3ec44c94"))
case("inbox scoped to a third identity", IDENTITY,
     lambda s: s["inbox"].update(my_id="0e7ee6cad65137fc"))

# ── 4 MEMBERSHIP ────────────────────────────────────────────────────────────
case("a topic between two OTHER agents surfaces", MEMBERSHIP,
     lambda s: s["dms"]["dms"].append(
         {"topic": "dm:0e7ee6cad65137fc:d1993c2c3ec44c94", "peer": "x",
          "unread": 1, "first_unread": 1}))

# ── 5 TRUST — the defect itself, and its absence ────────────────────────────
case("LIVE SHAPE: empty cursor store while content walk sees topics", UNTRUSTED)
case("backlog drained but cursor store STILL untracked", UNTRUSTED,
     lambda s: [r.update(unread=0) for r in s["dms"]["dms"]])
case("cursor store corroborates -> plain backlog, not untrusted", BACKLOG,
     lambda s: s["inbox"].update(unread_topics=[
         {"topic": AEF_RAIL, "cursor": 328, "latest": 423, "unread": 95},
         {"topic": KNOWN_MISS, "cursor": 0, "latest": 4, "unread": 4}]))

# ── CAN-PASS — without this the whole instrument is a constant ──────────────
case("genuinely nothing to read -> ALL-CLEAR is reachable", OK,
     lambda s: (s["dms"].update(dms=[]), s["inbox"].update(unread_topics=[])))
case("topics exist, all read, cursor store tracking -> ALL-CLEAR", OK,
     lambda s: ([r.update(unread=0) for r in s["dms"]["dms"]],
                s["inbox"].update(unread_topics=[
                    {"topic": AEF_RAIL, "cursor": 423, "latest": 423, "unread": 0}])))


# ── 7 FRONTIER — an unset frontier is an absent measurement, not a zero ─────
def _clean_dms(s):
    """Everything about the DMs is fine, so only the channel state is on trial."""
    [r.update(unread=0) for r in s["dms"]["dms"]]
    s["inbox"].update(unread_topics=[
        {"topic": AEF_RAIL, "cursor": 423, "latest": 423, "unread": 0}])


case("clean DMs but watched channel has ack_up_to=0 -> refuse all-clear", UNTRUSTED,
     lambda s: (_clean_dms(s), s.update(channels={
         "population_non_dm": 549, "watchlist": [
             {"topic": "agent-chat-arc", "ack_up_to": 0, "unread_count": 2001,
              "total": 2001, "first_unread": 8911, "last_offset": 10911}]})))
case("same channel WITH a real frontier and nothing past it -> ALL-CLEAR", OK,
     lambda s: (_clean_dms(s), s.update(channels={
         "population_non_dm": 549, "watchlist": [
             {"topic": "agent-chat-arc", "ack_up_to": 10911, "unread_count": 0,
              "total": 2001, "first_unread": None, "last_offset": 10911}]})))
case("empty channel, no traffic, unset frontier is harmless -> ALL-CLEAR", OK,
     lambda s: (_clean_dms(s), s.update(channels={
         "population_non_dm": 549, "watchlist": [
             {"topic": "agent-chat-arc-other", "ack_up_to": 0, "unread_count": 0,
              "total": 0, "first_unread": None, "last_offset": 0}]})))
# LIVE SHAPE of agent-chat-arc-other: one envelope, at offset 0, nothing past
# the frontier. Keying the flag on total>0 fires here and manufactures a
# finding; keying it on last_offset>ack_up_to does not.
case("one envelope AT offset 0 — nothing past frontier -> ALL-CLEAR", OK,
     lambda s: (_clean_dms(s), s.update(channels={
         "population_non_dm": 549, "watchlist": [
             {"topic": "agent-chat-arc-other", "ack_up_to": 0, "unread_count": 0,
              "total": 1, "first_unread": None, "last_offset": 0}]})))


def main():
    fails = []
    print(f"{'verdict':<12} {'want':<12} case")
    print("-" * 78)
    for label, want, mutate, extra, which in CASES:
        if which == "base":
            snap = base()
            if mutate:
                mutate(snap)
        else:
            snap = which
        got, _ = run(snap, extra)
        ok = got == want
        mark = "  " if ok else "!!"
        print(f"{mark}{NAME.get(got, got):<10} {NAME.get(want, want):<12} {label}")
        if not ok:
            fails.append((label, want, got))

    # ── KNOWN MISS: the sweep must rediscover the topic actually missed ─────
    print("-" * 78)
    live_ok = os.path.exists(LIVE)
    if not live_ok:
        fails.append(("live snapshot missing — known-miss check could not run", "-", "-"))
        print("!! live snapshot absent; known-miss + discriminator checks NOT RUN")
    else:
        with open(LIVE) as fh:
            live = json.load(fh)
        walk_topics = {r["topic"] for r in live["dms"]["dms"]}
        cursor_topics = {r["topic"] for r in live["inbox"]["unread_topics"]}

        if KNOWN_MISS in walk_topics:
            print(f"   OK  known miss rediscovered: {KNOWN_MISS}")
        else:
            fails.append(("known miss NOT rediscovered", KNOWN_MISS, sorted(walk_topics)))
            print(f"!! known miss NOT found in enumeration: {KNOWN_MISS}")

        # ── DISCRIMINATOR: the two sources must actually disagree ───────────
        missed_by_cursor = walk_topics - cursor_topics
        if missed_by_cursor:
            print(f"   OK  sources disagree — cursor store misses {len(missed_by_cursor)} "
                  f"topic(s) the content walk sees")
            for t in sorted(missed_by_cursor):
                print(f"         {t}")
        else:
            fails.append(("sources AGREE on live data — sweep discriminates nothing here",
                          "disagreement", "none"))
            print("!! cursor store and content walk AGREE — this sweep is measuring "
                  "a difference that is not present; it would pass for the wrong reason")

        # Age of the live capture, printed rather than assumed. The known-miss
        # check above reads the file directly, so it is age-independent: it
        # proves the SOURCE can find that topic, which is a fact about the
        # instrument, not about this minute.
        try:
            when = dt.datetime.fromisoformat(live["captured_at"].replace("Z", "+00:00"))
            age = (dt.datetime.now(dt.timezone.utc) - when).total_seconds() / 60
            print(f"   --  live capture is {age:.0f} min old"
                  f"{'  (STALE for decisions — re-capture before trusting a verdict)' if age > 90 else ''}")
        except (KeyError, ValueError):
            print("   --  live capture age: unknown")

        # ── COVERAGE: the sweep must DISCLOSE that channels are not exhaustive
        # A sweep that quietly covers 2 of 549 and prints a confident verdict is
        # the original defect with better formatting.
        #
        # --max-age-min is deliberately huge HERE and only here: what is on trial
        # in this sub-check is the disclosure TEXT, not the currency of the data.
        # Without it, an aged snapshot short-circuits to UNKNOWN and these four
        # assertions fail for a reason that has nothing to do with what they
        # test. Freshness itself still has teeth -- see the "3 hours old" case,
        # which must still come back UNKNOWN.
        p = subprocess.run([sys.executable, SWEEP, "--snapshot", LIVE,
                            "--max-age-min", "999999"],
                           capture_output=True, text=True)
        out = p.stdout
        for needle, why in [
            ("EXHAUSTIVE", "must state DM coverage is exhaustive"),
            ("WATCHLIST-SCOPED, NOT EXHAUSTIVE", "must state channel coverage is not"),
            ("not evidence of quiet", "must say absence from the report is not quiet"),
            ("FRONTIER UNSET", "must name the unset ack frontier rather than print a 0"),
        ]:
            if needle in out:
                print(f"   OK  scope disclosure: {why}")
            else:
                fails.append((f"scope disclosure missing: {why}", needle, "absent"))
                print(f"!! scope disclosure MISSING ({why}): {needle!r}")

    print("-" * 78)
    if fails:
        print(f"TEETH FAILED — {len(fails)} case(s) did not move the verdict as predicted:")
        for label, want, got in fails:
            print(f"  {label}: wanted {want}, got {got}")
        return 1
    print(f"TEETH PASS — {len(CASES)} mutations, each moved the verdict as predicted;")
    print("             ALL-CLEAR proven reachable; known miss rediscovered;")
    print("             the two sources proven to disagree on live data.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
