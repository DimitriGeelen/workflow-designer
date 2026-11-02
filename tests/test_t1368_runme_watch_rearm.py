#!/usr/bin/env python3
"""T-1368: the text that wakes the agent says to re-arm the runme watch, and names what is still pending.

tools/runme-watch.sh ends on its first event, because that exit is what wakes the agent; so every event needs a
re-arm, a STOPPED one included. On 2026-11-02 the operator re-ran job 118 32 s after it stopped, and the agent, which
had not re-armed, missed the whole run. The watch now ends its output with the launcher's own list of pending jobs and
the re-arm command, so the re-arm is in front of the agent instead of in its memory.

Legs (file events only: PATH without termlink; the pending list comes from RUNME_WATCH_LIST_CMD):
  1. a STOPPED event while a job is pending: the output has the event, "RE-ARM NOW" and the pending job's line;
  2. a done event with nothing pending: the output has the event and says no job is pending, no "RE-ARM NOW".
Exit 0 = both legs pass.
"""
import os
import subprocess
import sys
import tempfile
import time

ROOT = os.environ.get("T1368_ROOT") or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WATCH_SH = os.path.join(ROOT, "tools", "runme-watch.sh")
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def watch_one(tmp, tag, event_line, list_cmd):
    ev = os.path.join(tmp, tag + ".events")
    wf = os.path.join(tmp, tag + ".watch")
    open(ev, "w").close()
    env = dict(os.environ, RUNME_EVENTS_FILE=ev, RUNME_WATCH_FILE=wf, RUNME_WATCH_LIST_CMD=list_cmd,
               PATH="/usr/bin:/bin")   # no termlink: the file leg only
    p = subprocess.Popen(["bash", WATCH_SH, "60"], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for _ in range(100):               # armed = its record exists (baseline taken before the record, T-1244)
        if os.path.exists(wf):
            break
        time.sleep(0.1)
    with open(ev, "a") as fh:
        fh.write(event_line + "\n")
    out, _ = p.communicate(timeout=60)
    return p.returncode, out


def main():
    with tempfile.TemporaryDirectory() as tmp:
        stop = "2026-11-02T12:58:28Z runme-x STOPPED rc=1 — not confirmed at step 1/2 (received: an empty Enter)"
        rc, out = watch_one(tmp, "a", stop,
                            "echo 118-decide-t1363-go — Decide T-1363  [ready; last: STOPPED]")
        leg(rc == 0 and stop in out and "RE-ARM NOW" in out and "118-decide-t1363-go" in out
            and "bash tools/runme-watch.sh" in out,
            "1 a STOPPED event with a job pending ends with RE-ARM NOW and the pending job", out.strip().replace("\n", " | ")[:300])

        done = "2026-11-02T12:59:46Z runme-y done rc=0"
        rc, out = watch_one(tmp, "b", done, "echo no pending jobs")
        leg(rc == 0 and done in out and "no job pending" in out and "RE-ARM NOW" not in out,
            "2 a done event with nothing pending says so, no RE-ARM NOW", out.strip().replace("\n", " | ")[:300])

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
