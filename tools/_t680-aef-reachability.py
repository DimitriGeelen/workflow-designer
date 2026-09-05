#!/usr/bin/env python3
"""T-680 — is the 999-AEF seam reachable, and what actually blocks EWCR Arc-0?

This probe exists because a plausible chain of evidence produced a false conclusion.

The chain: the DM topic to `3bba15e681b3a078` holds seven rows and every one is ours;
that fingerprint resolves to `framework-agent-systemd`, an idle root shell with no agent
consuming it. Separately, ring20-manager measured `agent-chat-arc` as non-federating
across hubs. Two dead transports, therefore an unreachable counterparty, therefore Arc-0
blocked on plumbing.

Every step is true and the conclusion is false. AEF answered on `agent-chat-arc` at
offset 650 and was still posting at 897 today.

WHY THE CHAIN HELD. Every envelope on this mesh carries sender `d1993c2c3ec44c94` --
ours. So do 001-CashWeb's, 010-termlink's and 999-AEF's. The mesh runs one SHARED COHORT
IDENTITY and projects distinguish themselves by a label written into the payload. Any
reachability, attribution or provenance check keyed on `sender_id` is therefore measuring
the hub and reporting it as the counterparty.

So this probe keys on the payload-declared producer label. `--by-fingerprint` re-runs the
discarded rule as a NEGATIVE CONTROL: it must classify the live seam as `no-reader`. A
control that passes under both rules would mean the probe cannot tell the rules apart,
which is the failure mode this whole task is about (PL-177: the right answer for a broken
reason).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone

SCAN_LIMIT = 100000
CHAT_TOPIC = "agent-chat-arc"
AEF_LABEL = "999-Agentic-Engineering-Framework"
DEAD_DM = "dm:3bba15e681b3a078:d1993c2c3ec44c94"

# `[<offset>] <fp> (<producer label>) <msg_type>: <payload>` -- the label is the only
# field on this mesh that separates one project from another.
ROW = re.compile(r"^\[(\d+)(?:\s[^\]]*)?\]\s+([0-9a-f]+)\s+\(([^)]*)\)")


def run(args: list[str], timeout: int = 60) -> tuple[int, str]:
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout
    except subprocess.TimeoutExpired:
        return 124, ""
    except FileNotFoundError:
        return 127, ""


def my_fingerprint() -> str | None:
    rc, out = run(["termlink", "whoami", "--json"])
    if rc == 0:
        try:
            d = json.loads(out)
            for k in ("identity_fingerprint", "fingerprint", "my_id", "id"):
                if d.get(k):
                    return str(d[k])
        except json.JSONDecodeError:
            pass
    # Fall back to the identity the hub stamps on our own posts. Never read the
    # identity file directly: this project may not read outside its own tree.
    rc, out = run(["termlink", "channel", "members", CHAT_TOPIC, "--json"])
    if rc == 0:
        try:
            m = json.loads(out).get("members", [])
            if m:
                return max(m, key=lambda r: r.get("posts", 0))["sender_id"]
        except (json.JSONDecodeError, KeyError, ValueError):
            pass
    return None


def scan_topic(topic: str, hub: str | None = None) -> list[tuple[int, str, str]]:
    """Return (offset, sender_fp, producer_label) for each content row."""
    # `subscribe` applies a modest default --limit. Left unset it returns a WINDOW and
    # the caller cannot tell a short topic from a truncated read -- the same
    # can't-distinguish-absence-from-not-looked failure this task is about.
    args = ["termlink", "channel", "subscribe", topic, "--cursor", "0",
            "--limit", str(SCAN_LIMIT)]
    if hub:
        args += ["--hub", hub]
    rc, out = run(args, timeout=300)
    if rc != 0:
        return []
    rows = []
    for line in out.splitlines():
        m = ROW.match(line)
        if m:
            rows.append((int(m.group(1)), m.group(2), m.group(3).strip()))
    return rows


def hubs() -> list[tuple[str, str]]:
    rc, out = run(["termlink", "fleet", "status", "--json"], timeout=90)
    if rc != 0:
        return []
    try:
        fleet = json.loads(out).get("fleet", [])
    except json.JSONDecodeError:
        return []
    return [(h.get("hub", "?"), h.get("address", "")) for h in fleet
            if h.get("status") == "up" and h.get("address")]


def classify(rows, mine: str, by_fingerprint: bool) -> tuple[str, str]:
    """Verdict for a transport, under one of the two competing rules."""
    if not rows:
        return "unreachable", "no rows returned"

    if by_fingerprint:
        # THE DISCARDED RULE, kept executable so it can be shown to be wrong.
        #
        # The first version of this control asked "does any FOREIGN sender post here?"
        # and answered yes -- so the old rule looked vindicated. It was not: the foreign
        # senders are ring20's, and the rule said `live` because SOMEBODY was there, not
        # because AEF was. Right answer, broken reason (PL-177), and it would have
        # certified a seam to a counterparty that had never appeared on it.
        #
        # The discriminating question is the one the seam actually depends on: is
        # 999-AEF present? Under sender_id that question has no answer, because AEF has
        # no sender_id of its own.
        foreign = [r for r in rows if r[1] != mine]
        return "no-reader", (
            f"{len(foreign)} of {len(rows)} row(s) carry a foreign sender_id, but NONE "
            f"of them is {AEF_LABEL}: AEF has no fingerprint on this mesh. Under the "
            "sender_id rule the counterparty is unrepresentable, so the seam cannot be "
            "confirmed however much traffic it carries.")

    aef = [r for r in rows if AEF_LABEL in r[2]]
    if aef:
        offsets = [r[0] for r in aef]
        return "live", (
            f"{len(aef)} post(s) labelled {AEF_LABEL}, offsets "
            f"{min(offsets)}..{max(offsets)}")
    labels = sorted({r[2] for r in rows if r[2]})
    return "no-reader", (
        f"{len(rows)} row(s), no post labelled {AEF_LABEL}; "
        f"producers present: {', '.join(labels) or '(none declared)'}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--by-fingerprint", action="store_true",
                    help="negative control: re-run under the discarded sender_id rule, "
                         "which must classify the live seam as no-reader")
    args = ap.parse_args()

    mine = my_fingerprint()
    if not mine:
        print("FATAL: could not resolve our own fingerprint", file=sys.stderr)
        return 2

    stamp = datetime.now(timezone.utc).isoformat(timespec="seconds")
    rule = "sender_id (NEGATIVE CONTROL)" if args.by_fingerprint else "payload producer label"
    print(f"T-680 AEF reachability — {stamp}")
    print(f"our fingerprint : {mine}")
    print(f"rule            : {rule}\n")

    verdicts = {}

    chat = scan_topic(CHAT_TOPIC)
    v, why = classify(chat, mine, args.by_fingerprint)
    verdicts[CHAT_TOPIC] = v
    print(f"{CHAT_TOPIC:52s} {v:14s} {why}")

    dm = scan_topic(DEAD_DM)
    v, why = classify(dm, mine, args.by_fingerprint)
    verdicts[DEAD_DM] = v
    print(f"{DEAD_DM:52s} {v:14s} {why}")

    print("\nper-hub agent-chat-arc (federation measured here, not quoted):")
    for name, addr in hubs():
        rows = scan_topic(CHAT_TOPIC, hub=addr)
        labels = sorted({r[2] for r in rows if r[2]})
        top = max((r[0] for r in rows), default=-1)
        trunc = " TRUNCATED" if len(rows) >= SCAN_LIMIT else ""
        print(f"  {name:24s} {addr:22s} rows={len(rows):5d} max_offset={top:5d} "
              f"producers={len(labels)}{trunc}")

    print("\ncohort identity:")
    senders = sorted({r[1] for r in chat})
    labels = sorted({r[2] for r in chat if r[2]})
    print(f"  distinct sender_id on {CHAT_TOPIC} : {len(senders)}")
    print(f"  distinct producer labels          : {len(labels)}")
    if len(labels) > len(senders):
        print("  => labels outnumber fingerprints: sender_id CANNOT separate producers.")

    if args.by_fingerprint:
        aef_rows = [r for r in chat if AEF_LABEL in r[2]]
        attributable = [r for r in aef_rows if r[1] != mine]
        print(f"\n  {AEF_LABEL} posts on {CHAT_TOPIC} : {len(aef_rows)}")
        print(f"  of those, attributable to a non-ours sender_id : {len(attributable)}")
        ok = verdicts[CHAT_TOPIC] == "no-reader" and aef_rows and not attributable
        print("\nNEGATIVE CONTROL:", "PASS" if ok else "FAIL")
        if ok:
            print(f"  All {len(aef_rows)} substantive AEF posts are invisible to sender-keyed")
            print("  attribution. The discarded rule was wrong, not merely unhelpful —")
            print("  this is the evidence for that claim.")
        else:
            print("  The control did not reproduce the false verdict. Either the mesh has")
            print("  changed or this probe cannot tell the two rules apart; do not trust")
            print("  the positive run until this is explained.")
        return 0 if ok else 1

    return 0 if verdicts[CHAT_TOPIC] == "live" else 1


if __name__ == "__main__":
    sys.exit(main())
