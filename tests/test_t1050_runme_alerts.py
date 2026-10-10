#!/usr/bin/env python3
"""T-1050: the session-start check tells a NEW session about runme.sh hand-overs nobody is watching.

Two halves, both offline (no hub, no real claude processes):
  A. tools/runme-watch.sh writes .context/working/runme.watch when armed, removes it when it reports
     an event, and KEEPS it on timeout (the state the next session must see).
  B. scripts/session-start-alerts.sh prints, before the mail check:
       WATCH LOST                 the watch was armed by a claude that is not this session
       (nothing)                  the watch was armed by this session
       RUN IN FLIGHT              last run started, no done/STOPPED, a runme.sh is running
       RUN ENDED WITHOUT RECORD   same, but nothing is running (killed / reboot)
       nothing pending            no watch record, last run ended
     and the section survives a failing mail check.
Exit 0 = all legs pass.
"""
import os
import subprocess
import sys
import tempfile
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WATCH_SH = os.path.join(ROOT, "tools", "runme-watch.sh")
ALERTS = os.path.join(ROOT, "scripts", "session-start-alerts.sh")
fails = []


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def alerts(tmp, events, watch=None, own="111", running="0", mail="own", tmux=None):
    ev = os.path.join(tmp, "events")
    with open(ev, "w") as fh:
        fh.write(events)
    wf = os.path.join(tmp, "watch")
    if watch is None:
        if os.path.exists(wf):
            os.remove(wf)
    else:
        with open(wf, "w") as fh:
            fh.write(watch)
    # mail is delegated to `fw sidecar alerts` since T-1059; a stub answers "nothing unseen"
    fw = os.path.join(tmp, "fw-stub")
    with open(fw, "w") as fh:
        fh.write('#!/usr/bin/env bash\necho "peer mail: nothing unseen"\n')
    os.chmod(fw, 0o755)
    # T-1117: the mail-watch record ("own" = armed by this session, None = absent, else its text)
    mw = os.path.join(tmp, "mailwatch")
    if mail is None:
        if os.path.exists(mw):
            os.remove(mw)
    else:
        with open(mw, "w") as fh:
            fh.write("watch_pid=6 claude_pid=%s armed=2026-10-10T10:00:00Z\n" % own if mail == "own" else mail)
    env = dict(os.environ, ALERTS_RUNME_EVENTS=ev, ALERTS_RUNME_WATCH=wf, ALERTS_OWN_CLAUDE=own,
               ALERTS_RUNME_RUNNING=running, ALERTS_NO_PROCS="1", ALERTS_FW=fw, ALERTS_MAIL_WATCH=mw)
    env.pop("TMUX", None)
    if tmux:
        env["TMUX"] = tmux
    r = subprocess.run(["bash", ALERTS], capture_output=True, text=True, env=env, timeout=60)
    return r.returncode, r.stdout


ENDED = ("2026-10-05T13:05:22Z runme-A started upgrade — log: x\n"
         "2026-10-05T13:43:59Z runme-A done rc=0\n")
OPEN = ENDED + "2026-10-05T14:00:00Z runme-B started cron install — log: y\n"


def main():
    with tempfile.TemporaryDirectory() as tmp:
        # ── A. runme-watch.sh keeps a record of who armed it ──
        ev, wf = os.path.join(tmp, "w-events"), os.path.join(tmp, "w-record")
        open(ev, "w").close()
        env = dict(os.environ, RUNME_EVENTS_FILE=ev, RUNME_WATCH_FILE=wf, PATH="/usr/bin:/bin")  # no termlink: file leg only
        p = subprocess.Popen(["bash", WATCH_SH, "30"], env=env, stdout=subprocess.PIPE, text=True)
        for _ in range(50):
            if os.path.exists(wf):
                break
            time.sleep(0.1)
        rec = open(wf).read() if os.path.exists(wf) else ""
        leg("watch_pid=%d" % p.pid in rec and "claude_pid=" in rec and "armed=" in rec,
            "A1 armed watch writes its record (watch pid, arming claude, time)", rec.strip())
        with open(ev, "a") as fh:
            fh.write("2026-10-05T15:00:00Z runme-X started test\n")
        out, _ = p.communicate(timeout=20)
        leg(p.returncode == 0 and "runme-X started" in out and not os.path.exists(wf),
            "A2 an event is reported and the record is removed", "rc=%s" % p.returncode)
        p = subprocess.run(["bash", WATCH_SH, "1"], env=env, capture_output=True, text=True, timeout=20)
        leg(p.returncode == 3 and os.path.exists(wf), "A3 on timeout the record is KEPT (nothing is listening any more)",
            "rc=%s" % p.returncode)

        # ── B. the session-start check ──
        rc, out = alerts(tmp, ENDED, watch="watch_pid=5 claude_pid=999999 armed=2026-10-05T13:00:00Z\n")
        leg(rc == 0 and "WATCH LOST" in out and "claude pid 999999" in out and "runme-watch.sh" in out,
            "B1 watch armed by a gone session -> WATCH LOST with the re-arm command")
        rc, out = alerts(tmp, ENDED, watch="watch_pid=5 claude_pid=111 armed=2026-10-05T13:00:00Z\n")
        leg("WATCH LOST" not in out and "nothing pending" in out, "B2 CONTROL: watch armed by THIS session -> nothing")
        rc, out = alerts(tmp, OPEN, running="1")
        leg("RUN IN FLIGHT: runme-B" in out, "B3 last run started, runme.sh running -> RUN IN FLIGHT")
        rc, out = alerts(tmp, OPEN, running="0")
        leg("RUN ENDED WITHOUT RECORD: runme-B" in out, "B4 last run started, nothing running -> RUN ENDED WITHOUT RECORD")
        rc, out = alerts(tmp, ENDED)
        leg("nothing pending" in out and "RUN " not in out and "WATCH LOST" not in out,
            "B5 CONTROL: no record, last run ended -> nothing pending")
        # ── C. T-1117: MAIL WATCH MISSING ──
        rc, out = alerts(tmp, ENDED, mail=None)
        leg("MAIL WATCH MISSING: no sidecar mail watch is armed" in out and "sidecar-mail-watch.sh" in out,
            "C1 no mail watch armed -> MAIL WATCH MISSING with the arm command")
        rc, out = alerts(tmp, ENDED, mail="watch_pid=6 claude_pid=999999 armed=2026-10-10T10:00:00Z\n")
        leg("MAIL WATCH MISSING: the sidecar mail watch was armed" in out and "which is gone" in out,
            "C2 mail watch armed by a gone session -> MAIL WATCH MISSING")
        rc, out = alerts(tmp, ENDED)
        leg("MAIL WATCH MISSING" not in out and "nothing pending" in out, "C3 CONTROL: armed by THIS session -> nothing")
        rc, out = alerts(tmp, ENDED, mail=None, tmux="/tmp/tmux-0/fw-agents,1,0")
        leg("MAIL WATCH MISSING" not in out, "C4 inside tmux (the sidecar can inject) -> nothing")

        # B6: the section is printed even when the mail check fails (the verb cannot be run)
        env = dict(os.environ, ALERTS_RUNME_EVENTS=os.path.join(tmp, "events"), ALERTS_RUNME_WATCH=os.path.join(tmp, "nowatch"),
                   ALERTS_OWN_CLAUDE="111", ALERTS_NO_PROCS="1", ALERTS_FW=os.path.join(tmp, "no-such-fw"),
                   ALERTS_MAIL_WATCH=os.path.join(tmp, "mailwatch"))
        r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "session-start-alerts.py")],
                           capture_output=True, text=True, env=env, timeout=60)
        leg(r.returncode == 2 and "Runme / live agents:" in r.stdout and "MAIL CHECK FAILED" in r.stdout,
            "B6 a failing mail check does not hide the runme section", "rc=%s" % r.returncode)

    print("\n%d failed leg(s)" % len(fails) if fails else "\nall legs passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
