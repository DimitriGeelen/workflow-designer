#!/usr/bin/env python3
"""T-1046 / T-1059: the /resume session-start check — mail part delegated to `fw sidecar alerts`.

Since AEF 1.8.3 the mail list itself is AEF's (T-3856, tested there). What 832 owns, and this checks
against a stub `fw` (ALERTS_FW), is the delegation contract:
  - the verb's output is shown as-is, and --limit / --mark-seen are passed through;
  - a failing verb (exit 3 = NOT CHECKED, or anything else), a missing verb, or empty output is
    reported as MAIL CHECK FAILED with exit 2 — never as "nothing";
  - the runme section is printed FIRST in every case, so a mail failure cannot hide it.
Runnable standalone (exit 0 = pass).
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "scripts", "session-start-alerts.sh")
# The wrapper execs this; named here so a broken exec path fails as itself, not as missing output.
IMPL = os.path.join(ROOT, "tools", "session-start-alerts.py")

STUB = """#!/usr/bin/env bash
echo "$*" > "$STUB_ARGS"
[ -n "${STUB_OUT:-}" ] && printf '%s\\n' "$STUB_OUT"
[ -n "${STUB_ERR:-}" ] && printf '%s\\n' "$STUB_ERR" >&2
exit "${STUB_RC:-0}"
"""


def run(tmp, args=(), out="", rc=0, err="", fw=None):
    env = dict(os.environ, ALERTS_FW=fw or os.path.join(tmp, "fw"), STUB_ARGS=os.path.join(tmp, "args"),
               STUB_OUT=out, STUB_RC=str(rc), STUB_ERR=err, ALERTS_NO_PROCS="1",
               ALERTS_RUNME_EVENTS=os.path.join(tmp, "none"), ALERTS_RUNME_WATCH=os.path.join(tmp, "none"),
               ALERTS_WATCHED="[]")
    r = subprocess.run(["bash", SCRIPT] + list(args), capture_output=True, text=True, env=env, timeout=60)
    passed = open(os.path.join(tmp, "args")).read().strip() if os.path.exists(os.path.join(tmp, "args")) else ""
    if os.path.exists(os.path.join(tmp, "args")):
        os.remove(os.path.join(tmp, "args"))
    return r.returncode, r.stdout, passed


# A stub termlink: `channel subscribe <topic> --cursor N ...` prints the envelopes in $TL_DIR/<topic>.jsonl
# whose offset >= N; exits $TL_RC (non-zero = the hub could not be read).
TL_STUB = """#!/usr/bin/env python3
import json, os, sys
a = sys.argv[1:]
if os.environ.get("TL_RC", "0") != "0":
    sys.stderr.write("hub unreachable\\n"); sys.exit(int(os.environ["TL_RC"]))
topic, cur = a[2], int(a[a.index("--cursor") + 1])
path = os.path.join(os.environ["TL_DIR"], topic + ".jsonl")
for line in (open(path) if os.path.exists(path) else []):
    if json.loads(line)["offset"] >= cur:
        print(line.strip())
"""


def _env_topics(tmp, tl_rc=0):
    import base64, json
    d = os.path.join(tmp, "tl")
    os.makedirs(d, exist_ok=True)

    def env(offset, sender, text, **meta):
        return json.dumps({"offset": offset, "ts": 1791397736942, "sender_id": sender, "msg_type": "note",
                           "metadata": meta, "payload_b64": base64.b64encode(text.encode()).decode()})
    with open(os.path.join(d, "t-corpus.jsonl"), "w") as fh:
        fh.write(env(5, "peer1", "old, already read") + "\n")
        fh.write(env(6, "peer1", "URGENT six requests for the designer") + "\n")
        fh.write(env(7, "us", "our own reply") + "\n")
        fh.write(env(8, "peer1", "", file="before.bpmn", description="ORIGINAL map") + "\n")
    tl = os.path.join(tmp, "termlink")
    with open(tl, "w") as fh:
        fh.write(TL_STUB)
    os.chmod(tl, 0o755)
    return dict(ALERTS_TERMLINK=tl, TL_DIR=d, TL_RC=str(tl_rc), ALERTS_TOPICS_SEEN=os.path.join(tmp, "seen.json"),
                ALERTS_WATCHED='[["t-corpus", "peer1", "Peer", 5]]')


def topics_legs(tmp, fw, leg):
    def go(args=(), tl_rc=0):
        env = dict(os.environ, ALERTS_FW=fw, STUB_ARGS=os.path.join(tmp, "args"), STUB_OUT="peer mail: nothing unseen",
                   STUB_RC="0", STUB_ERR="", ALERTS_NO_PROCS="1", ALERTS_RUNME_EVENTS=os.path.join(tmp, "none"),
                   ALERTS_RUNME_WATCH=os.path.join(tmp, "none"))
        env.update(_env_topics(tmp, tl_rc))
        r = subprocess.run(["bash", SCRIPT] + list(args), capture_output=True, text=True, env=env, timeout=60)
        return r.returncode, r.stdout

    rc, out = go()
    leg(rc == 0 and "Watched peer topics: 2 unseen" in out and "[t-corpus@6]" in out
        and "URGENT six requests" in out, "7 a new post by the watched sender is listed by name", out[-300:])
    leg("[t-corpus@8]" in out and "before.bpmn ORIGINAL map" in out, "8 an artifact post is named by file + description")
    leg("our own reply" not in out and "@7]" not in out, "9 a post by another sender (our own) is not listed")
    leg("already read" not in out and "@5]" not in out, "10 a post at or below the baseline is not listed")
    leg(out.index("Runme / live agents:") < out.index("Watched peer topics"), "11 runme section still first")
    rc, out = go()
    leg("2 unseen" in out and not os.path.exists(os.path.join(tmp, "seen.json")),
        "12 without --mark-seen nothing moves")
    rc, out = go(["--mark-seen"])
    rc2, out2 = go()
    leg(rc2 == 0 and "Watched peer topics: nothing unseen" in out2, "13 --mark-seen advances the marker", out2[-200:])
    os.remove(os.path.join(tmp, "seen.json"))
    rc, out = go(["--mark-seen"], tl_rc=4)
    leg(rc == 2 and "NOT CHECKED: t-corpus" in out and "Runme / live agents:" in out
        and "1 topic(s) NOT CHECKED" in out and "Watched peer topics: nothing unseen" not in out
        and not os.path.exists(os.path.join(tmp, "seen.json")),
        "14 an unreadable topic -> NOT CHECKED, exit 2, marker not written", out[-200:])


def main():
    fails = []

    def leg(ok, name, detail=""):
        print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
        if not ok:
            fails.append(name)

    for path in (SCRIPT, IMPL):
        leg(os.access(path, os.X_OK), "0 %s exists and is executable" % os.path.relpath(path, ROOT))
    with open(SCRIPT) as fh:
        leg("tools/session-start-alerts.py" in fh.read(), "0 the wrapper execs tools/session-start-alerts.py")

    with tempfile.TemporaryDirectory() as tmp:
        stub = os.path.join(tmp, "fw")
        with open(stub, "w") as fh:
            fh.write(STUB)
        os.chmod(stub, 0o755)

        rc, out, args = run(tmp, ["--limit", "4"], out="peer mail: 2 unseen\n  - AEF [c1] hello")
        leg(rc == 0 and "peer mail: 2 unseen" in out and "AEF [c1] hello" in out and args == "sidecar alerts --limit 4",
            "1 the verb's output is shown as-is; --limit passed through", "args=%r" % args)
        leg(out.index("Runme / live agents:") < out.index("peer mail:"), "2 the runme section comes first")

        rc, out, args = run(tmp, ["--mark-seen"], out="peer mail: nothing unseen")
        leg(rc == 0 and args == "sidecar alerts --limit 10 --mark-seen", "3 --mark-seen passed through", "args=%r" % args)

        rc, out, _ = run(tmp, out="NOT CHECKED: hub unreachable", rc=3)
        leg(rc == 2 and "MAIL CHECK FAILED" in out and "NOT CHECKED: hub unreachable" in out
            and "Runme / live agents:" in out, "4 verb exit 3 (NOT CHECKED) -> MAIL CHECK FAILED, exit 2, reason shown, runme still shown")

        rc, out, _ = run(tmp, out="", rc=0)
        leg(rc == 2 and "NOT CHECKED" in out, "5 empty output is never read as 'nothing' -> exit 2")

        rc, out, _ = run(tmp, fw=os.path.join(tmp, "no-such-fw"))
        leg(rc == 2 and "MAIL CHECK FAILED" in out, "6 missing verb -> MAIL CHECK FAILED, exit 2")

        # ── T-1087: watched peer topics, against a stub termlink ──
        topics_legs(tmp, stub, leg)

    if fails:
        print("\n%d failed leg(s)" % len(fails))
        return 1
    print("OK: session-start-alerts — mail delegated to fw sidecar alerts (output, flags, failures, runme first)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
