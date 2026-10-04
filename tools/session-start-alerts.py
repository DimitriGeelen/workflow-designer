#!/usr/bin/env python3
"""session-start-alerts.py — peer mail this agent has not been shown yet (832 T-1046).

The user-level /resume skill (step 7, AEF T-3327) runs `scripts/session-start-alerts.sh --limit 10`
and skips SILENTLY when the script is absent. AEF 1.7.740 does not vendor one, so until AEF ships
theirs this is ours. Retire it when `.agentic-framework/` carries the upstream script.

What counts as mail: envelopes on this project's inbox topics whose `metadata.from_project` is
another project, excluding `sidecar.receipt` delivery noise. The sender key is NOT usable to tell
ours from theirs — peers on this host post with the same hub key we do.

"Not yet shown" is THIS script's marker (.context/working/.alerts-seen-offset, per topic), never the
channel read position: the sidecar auto-acks and moves that, which is how AEF mail sat unseen for a
day (2026-10-03). Showing does not advance the marker; `--mark-seen` does, after the agent has
acknowledged the senders.

  scripts/session-start-alerts.sh [--limit N] [--mark-seen] [--from-json FILE]
  exit 0 = checked (mail or not); 2 = MAIL CHECK FAILED (hub unreachable etc.), never a silent "nothing"
"""
import argparse
import base64
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT = os.environ.get("ALERTS_PROJECT", os.path.basename(ROOT))
MARKER = os.environ.get("ALERTS_MARKER", os.path.join(ROOT, ".context", "working", ".alerts-seen-offset"))
NOISE = {"sidecar.receipt"}
PAGE = 200


class CheckFailed(Exception):
    pass


def inbox_topics():
    """The project inbox (circuit spelling, resolved by the framework) plus the legacy sidecar topic."""
    lib = os.path.join(ROOT, ".agentic-framework", "lib")
    sys.path.insert(0, lib)
    os.environ.setdefault("PROJECT_ROOT", ROOT)
    try:
        from sidecar import circuit
        primary = circuit.topic_for_circuit(circuit.circuit_id("project"))
    except Exception as e:  # noqa: BLE001 — named in the failure, not swallowed
        raise CheckFailed("cannot resolve the project inbox topic: %s" % e)
    return [primary, "sidecar:%s" % PROJECT]


def fetch(topic, cursor):
    """All envelopes at offset >= cursor, paged. A missing topic is empty; any other error fails."""
    out = []
    while True:
        r = subprocess.run(["termlink", "channel", "subscribe", topic, "--cursor", str(cursor),
                            "--limit", str(PAGE), "--json"], capture_output=True, text=True, timeout=120)
        if r.returncode != 0:
            if "not found" in r.stderr:
                return out
            raise CheckFailed("%s: %s" % (topic, (r.stderr.strip().splitlines() or ["rc=%d" % r.returncode])[-1]))
        page, nxt = [], None
        # envelopes come on stdout, the paging trailer ({"next_cursor": ...}) on stderr
        for line in (r.stdout + "\n" + r.stderr).splitlines():
            if not line.startswith("{"):
                continue
            row = json.loads(line)
            if "offset" in row:
                page.append(row)
            elif "next_cursor" in row:
                nxt = row["next_cursor"]
        out.extend(page)
        if len(page) < PAGE or nxt is None or nxt <= cursor:
            return out
        cursor = nxt


def is_mail(env):
    meta = env.get("metadata") or {}
    sender = meta.get("from_project") or meta.get("from_agent")
    return env.get("msg_type") not in NOISE and bool(sender) and sender != PROJECT


def first_line(env):
    try:
        text = base64.b64decode(env.get("payload_b64") or "").decode("utf-8", "replace")
    except Exception:  # noqa: BLE001
        text = str(env.get("payload") or "")
    text = " ".join(text.split())
    return text[:160] + ("…" if len(text) > 160 else "")


def load_marker():
    try:
        with open(MARKER) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def save_marker(m):
    os.makedirs(os.path.dirname(MARKER), exist_ok=True)
    tmp = MARKER + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(m, fh, indent=1, sort_keys=True)
    os.replace(tmp, MARKER)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--mark-seen", action="store_true")
    ap.add_argument("--from-json", help="offline: a JSON object {topic: [envelope, ...]} instead of the hub")
    a = ap.parse_args(argv)

    marker = load_marker()
    try:
        if a.from_json:
            with open(a.from_json) as fh:
                data = json.load(fh)
            got = {t: [e for e in envs if e["offset"] >= marker.get(t, -1) + 1] for t, envs in data.items()}
        else:
            got = {t: fetch(t, marker.get(t, -1) + 1) for t in inbox_topics()}
    except (CheckFailed, subprocess.TimeoutExpired, OSError, ValueError) as e:
        print("MAIL CHECK FAILED: %s" % e)
        return 2

    # Newest last, across topics (offsets are per topic, timestamps are not).
    mail = sorted(((t, e) for t, envs in got.items() for e in envs if is_mail(e)), key=lambda te: te[1].get("ts", 0))
    # A "[nudge]" is the sender's outbox re-announcing a consult already in this list or acked long ago;
    # dozens of them would push real mail past --limit, so they are counted per conversation instead.
    nudges, unseen = {}, []
    for t, e in mail:
        if first_line(e).startswith("[nudge]"):
            key = ((e.get("metadata") or {}).get("from_project"), (e.get("metadata") or {}).get("conversation_id"))
            nudges[key] = nudges.get(key, 0) + 1
        else:
            unseen.append((t, e))
    print("Peer mail not yet shown: %d message(s), %d nudge(s)" % (len(unseen), sum(nudges.values())))
    for t, e in unseen[-a.limit:] if a.limit > 0 else []:
        meta = e.get("metadata") or {}
        print("  [%s @%d] %s  %s — %s" % (t, e["offset"], meta.get("from_project") or meta.get("from_agent"),
                                         e.get("msg_type", "?"), first_line(e)))
    if len(unseen) > a.limit > 0:
        print("  (%d older not listed; raise --limit to see them)" % (len(unseen) - a.limit))
    for (who, conv), n in sorted(nudges.items(), key=lambda kv: -kv[1]):
        print("  nudges: %d from %s on conversation %s" % (n, who, conv))
    if not unseen and not nudges:
        print("  nothing")

    if a.mark_seen:
        for t, envs in got.items():
            if envs:
                marker[t] = max(marker.get(t, -1), max(e["offset"] for e in envs))
        save_marker(marker)
        print("marked seen: %s" % ", ".join("%s@%d" % kv for kv in sorted(marker.items())) or "nothing to mark")
    return 0


if __name__ == "__main__":
    sys.exit(main())
