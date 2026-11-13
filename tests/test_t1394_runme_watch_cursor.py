#!/usr/bin/env python3
"""T-1394: a runme watch resumes from the last event line a previous watch REPORTED, not from the time it is armed.

Job 130 (2026-11-11) wrote 'started' and 'STOPPED' in the same second. The watch woke on 'started'; the STOPPED landed
before the re-arm, the re-armed watch counted it as already seen, and it went unreported for about two hours.

Legs (file events only: PATH without termlink; RUNME_WATCH_LIST_CMD stubs the pending list):
  1. watch A reports 'started'; 'STOPPED' is appended before watch B is armed; B reports 'STOPPED' at once;
  2. a first arm with no cursor and old lines in the file reports none of them (it waits for a new line);
  3. a cursor past the end of the file (the file was truncated) is ignored: only the new line is reported.
T1394_WATCH=<script> runs the legs against another watch (the control: the pre-fix one must fail leg 1).
Exit 0 = all legs pass.
"""
import os
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WATCH_SH = os.environ.get("T1394_WATCH") or os.path.join(ROOT, "tools", "runme-watch.sh")
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def start(tmp, limit):
    env = dict(os.environ, RUNME_EVENTS_FILE=os.path.join(tmp, "events"), RUNME_WATCH_FILE=os.path.join(tmp, "watch"),
               RUNME_WATCH_LIST_CMD="echo no pending jobs", PATH="/usr/bin:/bin")
    env.pop("RUNME_WATCH_CURSOR", None)   # the default, beside the watch record
    p = subprocess.Popen(["bash", WATCH_SH, str(limit)], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                         text=True)
    for _ in range(100):                 # armed = its record exists (baseline taken before the record, T-1244)
        if os.path.exists(os.path.join(tmp, "watch")):
            break
        time.sleep(0.1)
    return p


def append(tmp, line):
    with open(os.path.join(tmp, "events"), "a") as fh:
        fh.write(line + "\n")


def main():
    started = "2026-11-11T15:06:47Z runme-130 started"
    stopped = "2026-11-11T15:06:47Z runme-130 STOPPED rc=1"

    with tempfile.TemporaryDirectory() as tmp:
        append(tmp, "old line before any watch")
        p = start(tmp, 30)
        append(tmp, started)
        out_a, _ = p.communicate(timeout=60)
        append(tmp, stopped)             # after A reported, before B is armed
        p = start(tmp, 8)
        out_b, _ = p.communicate(timeout=60)
        leg(p.returncode == 0 and stopped in out_b and started not in out_b and started in out_a,
            "1 an event written between a report and the re-arm is reported by the next watch",
            "A=%r B=%r" % (out_a.strip()[:120], out_b.strip()[:160]))

    with tempfile.TemporaryDirectory() as tmp:
        append(tmp, "old line one")
        append(tmp, "old line two")
        p = start(tmp, 6)
        out, _ = p.communicate(timeout=60)
        leg(p.returncode == 3 and "old line" not in out,
            "2 a first arm with no cursor does not report lines already in the file", out.strip()[:160])

    with tempfile.TemporaryDirectory() as tmp:
        append(tmp, "after truncation one")
        with open(os.path.join(tmp, "watch.cursor"), "w") as fh:
            fh.write("50\n")
        p = start(tmp, 30)
        append(tmp, "new event")
        out, _ = p.communicate(timeout=60)
        leg(p.returncode == 0 and "new event" in out and "after truncation one" not in out,
            "3 a cursor past the end of the file is ignored", out.strip()[:160])

    print("=== %d failed ===" % len(fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
