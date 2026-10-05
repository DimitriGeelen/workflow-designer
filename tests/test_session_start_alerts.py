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
               ALERTS_RUNME_EVENTS=os.path.join(tmp, "none"), ALERTS_RUNME_WATCH=os.path.join(tmp, "none"))
    r = subprocess.run(["bash", SCRIPT] + list(args), capture_output=True, text=True, env=env, timeout=60)
    passed = open(os.path.join(tmp, "args")).read().strip() if os.path.exists(os.path.join(tmp, "args")) else ""
    if os.path.exists(os.path.join(tmp, "args")):
        os.remove(os.path.join(tmp, "args"))
    return r.returncode, r.stdout, passed


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

    if fails:
        print("\n%d failed leg(s)" % len(fails))
        return 1
    print("OK: session-start-alerts — mail delegated to fw sidecar alerts (output, flags, failures, runme first)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
