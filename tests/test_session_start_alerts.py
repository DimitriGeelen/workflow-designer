#!/usr/bin/env python3
"""T-1046: session-start-alerts.py against a committed-in-test fixture (no hub).

Asserts: a peer consult is shown; our own post, a receipt and a nudge are not listed as mail (the
nudge is counted); --limit keeps the NEWEST; the marker is the script's own, advanced only by
--mark-seen; and a second run after --mark-seen reports nothing. Runnable standalone (exit 0 = pass).
"""
import base64
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "scripts", "session-start-alerts.sh")
INBOX, LEGACY = "inbox:hub/832-Workflow-designer", "sidecar:832-Workflow-designer"


def env(offset, ts, sender, text, msg_type="sidecar.consult", conv="c1"):
    return {"offset": offset, "ts": ts, "msg_type": msg_type,
            "metadata": {"from_project": sender, "conversation_id": conv},
            "payload_b64": base64.b64encode(text.encode()).decode()}


FIXTURE = {
    INBOX: [
        env(0, 100, "999-Agentic-Engineering-Framework", "PEER-OLD consult"),
        env(1, 200, "832-Workflow-designer", "OWN-POST must not show"),
        env(2, 300, "999-Agentic-Engineering-Framework", "RECEIPT must not show", msg_type="sidecar.receipt"),
        env(3, 400, "999-Agentic-Engineering-Framework", "[nudge] an unread consult is waiting", conv="cX"),
        env(4, 600, "010-termlink", "PEER-NEW consult"),
    ],
    LEGACY: [env(0, 500, "055-agentic-fleet-cockpit", "PEER-LEGACY consult")],
}


def run(tmp, *args):
    e = dict(os.environ, ALERTS_MARKER=os.path.join(tmp, "marker.json"), ALERTS_PROJECT="832-Workflow-designer")
    r = subprocess.run(["bash", SCRIPT, "--from-json", os.path.join(tmp, "fx.json")] + list(args),
                       capture_output=True, text=True, env=e)
    return r.returncode, r.stdout


def main():
    fails = []
    with tempfile.TemporaryDirectory() as tmp:
        with open(os.path.join(tmp, "fx.json"), "w") as fh:
            json.dump(FIXTURE, fh)

        rc, out = run(tmp, "--limit", "10")
        if rc != 0:
            fails.append("plain run exited %d" % rc)
        for want in ("PEER-OLD", "PEER-NEW", "PEER-LEGACY", "3 message(s), 1 nudge(s)", "nudges: 1 from 999-Agentic-Engineering-Framework on conversation cX"):
            if want not in out:
                fails.append("missing %r" % want)
        for bad in ("OWN-POST", "RECEIPT", "[nudge] an unread"):
            if bad in out:
                fails.append("listed %r, which is not mail" % bad)
        if not out.index("PEER-OLD") < out.index("PEER-LEGACY") < out.index("PEER-NEW"):
            fails.append("not ordered by timestamp across topics")
        if os.path.exists(os.path.join(tmp, "marker.json")):
            fails.append("a run WITHOUT --mark-seen wrote the marker")

        rc, out = run(tmp, "--limit", "1")
        if "PEER-NEW" not in out or "PEER-OLD" in out or "2 older not listed" not in out:
            fails.append("--limit 1 did not keep only the newest: %r" % out)

        rc, out = run(tmp, "--mark-seen")
        marker = json.load(open(os.path.join(tmp, "marker.json")))
        if marker != {INBOX: 4, LEGACY: 0}:
            fails.append("--mark-seen wrote %r" % marker)

        rc, out = run(tmp)
        if "0 message(s), 0 nudge(s)" not in out or "nothing" not in out:
            fails.append("after --mark-seen, a rerun still reports mail: %r" % out)

        FIXTURE[INBOX].append(env(5, 700, "999-Agentic-Engineering-Framework", "PEER-AFTER-MARK"))
        with open(os.path.join(tmp, "fx.json"), "w") as fh:
            json.dump(FIXTURE, fh)
        rc, out = run(tmp)
        if "PEER-AFTER-MARK" not in out or "1 message(s)" not in out:
            fails.append("mail arriving after the marker was not shown: %r" % out)

    for f in fails:
        sys.stderr.write("FAIL: %s\n" % f)
    if not fails:
        print("OK: session-start-alerts — peer mail shown, own/receipt/nudge filtered, newest kept, marker own and honoured")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
