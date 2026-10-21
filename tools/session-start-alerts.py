#!/usr/bin/env python3
"""session-start-alerts.py — what a new 832 session must see first (T-1046, T-1050, T-1059).

Two sections, runme first so a failing mail check can never hide it:
  1. Runme / live agents (832's own, T-1050): WATCH LOST, RUN IN FLIGHT / RUN ENDED WITHOUT RECORD,
     OTHER LIVE CLAUDE. AEF's `fw runme pending` does not see 832's launcher jobs (job.sh, T-1055);
     convergence is AEF's T-3901.
  2. Peer mail: since AEF 1.8.3 this DELEGATES to `fw sidecar alerts` (AEF T-3856, built from our
     stopgap): both routes, receipts and answered nudges excluded, NOT CHECKED instead of silence.
     832's own topic reader and its marker file retired here (T-1059).
  3. Watched peer topics (T-1087): peers that post on shared hub topics instead of the sidecar
     (Greenfield). Listed by name above a per-topic last-seen offset; --mark-seen advances it.
  4. AEF designer pin (T-1187): AEF is the designer's main consumer (operator, 2026-10-17); a release is
     done only when AEF serves it. One line from tools/_t1187-aef-pin-lag.sh: CURRENT, BEHIND N, or
     NOT CHECKED. Informational: it never changes the exit code, which stays the mail check's.
  5. Stale [REVIEW] documents (T-1152, OBS-291): an open [REVIEW] criterion that asks someone to read a docs/
     document older than its task's content. One line from tools/_t1152-stale-review-doc.py naming the
     tasks; informational too.

The user-level /resume skill (step 7) runs `scripts/session-start-alerts.sh --limit 10`; the
script may run with no task in focus (T-1047 allowlist).

  scripts/session-start-alerts.sh [--limit N] [--mark-seen]
  exit 0 = checked (mail or not); 2 = MAIL CHECK FAILED / NOT CHECKED, never a silent "nothing"
"""
import argparse
import base64
import datetime
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# The framework verb; ALERTS_FW points the test at a stub (tests/test_session_start_alerts.py).
FW = os.environ.get("ALERTS_FW", os.path.join(ROOT, ".agentic-framework", "bin", "fw"))


RUNME_EVENTS = os.environ.get("ALERTS_RUNME_EVENTS", os.path.join(ROOT, ".context", "working", "runme.events"))
RUNME_WATCH = os.environ.get("ALERTS_RUNME_WATCH", os.path.join(ROOT, ".context", "working", "runme.watch"))
MAIL_WATCH = os.environ.get("ALERTS_MAIL_WATCH", os.path.join(ROOT, ".context", "working", "sidecar-mail.watch"))

# ── Watched peer topics (T-1087) ──────────────────────────────────────────────────────────────
# Some peers do not use the sidecar: Greenfield (aef-greenfield-test, the evergreen trial) posts on
# shared hub topics, which `fw sidecar alerts` does not read. Its urgent T-172 request sat ~14 h
# unseen on 2026-10-07 until the operator relayed it. Each entry: topic, the peer's sender id, a
# label, and the offset we had already read when this was wired (used until --mark-seen writes a
# marker). Retire an entry once that peer is on a sidecar conversation with us.
WATCHED = [
    ("xfer-evergreen-corpus", "90d4553895d5a9a6", "Greenfield", 36),
    ("xfer-evergreen-kit", "90d4553895d5a9a6", "Greenfield", 38),
]
TERMLINK = os.environ.get("ALERTS_TERMLINK", "termlink")
SEEN_FILE = os.environ.get("ALERTS_TOPICS_SEEN",
                           os.path.join(ROOT, ".context", "working", "watched-topics.seen.json"))


def _comm(pid):
    try:
        with open("/proc/%d/comm" % pid) as fh:
            return fh.read().strip()
    except OSError:
        return None


def _ppid(pid):
    try:
        with open("/proc/%d/stat" % pid) as fh:
            return int(fh.read().rsplit(")", 1)[1].split()[1])
    except (OSError, ValueError, IndexError):
        return 0


def own_claude():
    """The claude process this check runs under (walk up the parent chain), or None.
    ALERTS_OWN_CLAUDE overrides it (tests)."""
    if os.environ.get("ALERTS_OWN_CLAUDE"):
        return int(os.environ["ALERTS_OWN_CLAUDE"])
    p = os.getpid()
    while p > 1:
        if _comm(p) == "claude":
            return p
        p = _ppid(p)
    return None


def runme_lines():
    """T-1050: what a NEW session must know about runme.sh hand-overs and other live agents here.

    - WATCH LOST: tools/runme-watch.sh was armed by a claude session that is not this one. A
      background watch dies with its session, silently, so a handed-over runme.sh would run with
      nothing listening (2026-10-05, the 1.8.2 upgrade).
    - RUN IN FLIGHT / RUN ENDED WITHOUT RECORD: the last run's `started` has no `done`/`STOPPED`.
    - OTHER LIVE CLAUDE: another claude process has this project as its cwd (T-1052: two live
      copies of one conversation both acted on the same runme event).
    """
    out, me = [], own_claude()
    try:
        with open(RUNME_WATCH) as fh:
            rec = dict(kv.split("=", 1) for kv in fh.read().split() if "=" in kv)
        armer = rec.get("claude_pid", "none")
        if not (armer.isdigit() and me is not None and int(armer) == me):
            alive = armer.isdigit() and _comm(int(armer)) == "claude"
            out.append("WATCH LOST: runme-watch was armed %s by claude pid %s, %s. A handed-over runme.sh would "
                       "run with nothing listening. Re-arm: bash tools/runme-watch.sh (as a BACKGROUND task)"
                       % (rec.get("armed", "?"), armer, "a different live session" if alive else "which is gone"))
    except OSError:
        pass
    try:
        with open(RUNME_EVENTS) as fh:
            ev = [ln.split(None, 3) for ln in fh if ln.strip()]
        started = [e for e in ev if len(e) >= 3 and e[2] == "started"]
        if started:
            last = started[-1]
            if not any(e[1] == last[1] and e[2] in ("done", "STOPPED") for e in ev):
                if os.environ.get("ALERTS_RUNME_RUNNING") in ("0", "1"):
                    running = os.environ["ALERTS_RUNME_RUNNING"] == "1"
                else:
                    # runme.sh execs tools/runme-launcher.sh (T-1055), so the live process is the launcher
                    running = subprocess.run(["pgrep", "-f", "bash .*runme(-launcher)?\\.sh"],
                                             capture_output=True).returncode == 0
                what = last[3].strip() if len(last) > 3 else ""
                out.append(("RUN IN FLIGHT: %s (%s) started %s — keep the watch armed" if running else
                            "RUN ENDED WITHOUT RECORD: %s (%s) started %s has no done/STOPPED and no runme.sh is "
                            "running (killed, or the host rebooted) — read its log") % (last[1], what[:120], last[0]))
    except OSError:
        pass
    out.extend(mail_watch_lines(me))
    if os.environ.get("ALERTS_NO_PROCS") != "1":
        for d in os.listdir("/proc"):
            if not d.isdigit() or int(d) == me or _comm(int(d)) != "claude":
                continue
            try:
                if os.readlink("/proc/%s/cwd" % d) != ROOT:
                    continue
                with open("/proc/%s/cmdline" % d, "rb") as fh:
                    cmd = fh.read().replace(b"\0", b" ").decode("utf-8", "replace").strip()
            except OSError:
                continue
            out.append("OTHER LIVE CLAUDE in this project: pid %s `%s` — two agents here both act on the same "
                       "events (T-1052); close one" % (d, cmd[:100]))
    return out


def mail_watch_lines(me):
    """T-1117: MAIL WATCH MISSING — this session cannot be typed into and no mail watch of its own is armed.

    A session outside tmux and TermLink cannot be injected (AEF inject.py c3, 832 T-1108/T-1115): peer mail waits
    for the operator's next prompt unless tools/sidecar-mail-watch.sh runs in the background and wakes the agent.
    Inside tmux the sidecar can inject (AEF T-4003), so nothing is said there.
    """
    if os.environ.get("TMUX"):
        return []
    fix = "Arm: bash tools/sidecar-mail-watch.sh (as a BACKGROUND task)"
    try:
        with open(MAIL_WATCH) as fh:
            rec = dict(kv.split("=", 1) for kv in fh.read().split() if "=" in kv)
    except OSError:
        return ["MAIL WATCH MISSING: no sidecar mail watch is armed; this session cannot be typed into, so peer "
                "mail waits for the next prompt. " + fix]
    armer = rec.get("claude_pid", "none")
    if armer.isdigit() and me is not None and int(armer) == me:
        return []
    alive = armer.isdigit() and _comm(int(armer)) == "claude"
    return ["MAIL WATCH MISSING: the sidecar mail watch was armed %s by claude pid %s, %s. " % (
        rec.get("armed", "?"), armer, "a different live session" if alive else "which is gone") + fix]


def print_runme():
    try:
        lines = runme_lines()
    except Exception as e:  # noqa: BLE001 — this section must never hide the mail check
        lines = ["RUNME CHECK FAILED: %s" % e]
    print("Runme / live agents:")
    for ln in lines or ["nothing pending"]:
        print("  " + ln)


def mail(limit, mark_seen):
    """Peer mail via `fw sidecar alerts`. Exit 3 from the verb (a route it could not read) and any
    other failure are reported as MAIL CHECK FAILED and return 2, never as 'nothing'."""
    cmd = [FW, "sidecar", "alerts", "--limit", str(limit)] + (["--mark-seen"] if mark_seen else [])
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    except (OSError, subprocess.TimeoutExpired) as e:
        print("MAIL CHECK FAILED: %s: %s" % (" ".join(cmd[1:3]), e))
        return 2
    out = (r.stdout or "").rstrip()
    if r.returncode != 0:
        print("MAIL CHECK FAILED (fw sidecar alerts exit %d):" % r.returncode)
        for ln in (out + "\n" + (r.stderr or "")).strip().splitlines()[-8:]:
            print("  " + ln)
        return 2
    print(out if out else "peer mail: (fw sidecar alerts printed nothing — treat as NOT CHECKED)")
    return 0 if out else 2


def _watched():
    """WATCHED, or the JSON list in ALERTS_WATCHED (tests; '[]' turns the section off)."""
    raw = os.environ.get("ALERTS_WATCHED")
    return [tuple(w) for w in json.loads(raw)] if raw is not None else WATCHED


def _topic_posts(topic, after):
    """Envelopes on `topic` with offset > after, or raise. One `termlink channel subscribe` call."""
    r = subprocess.run([TERMLINK, "channel", "subscribe", topic, "--cursor", str(after + 1),
                        "--limit", "500", "--json"], capture_output=True, text=True, timeout=60)
    if r.returncode != 0:
        raise RuntimeError("termlink exit %d: %s" % (r.returncode, (r.stderr or r.stdout).strip()[:160]))
    posts = []
    for line in r.stdout.splitlines():
        line = line.strip()
        if line.startswith("{"):
            e = json.loads(line)
            if isinstance(e.get("offset"), int) and e["offset"] > after:
                posts.append(e)
    return posts


def _summary(e):
    meta = e.get("metadata") or {}
    if meta.get("description") or meta.get("file"):
        text = "%s %s" % (meta.get("file", ""), meta.get("description", ""))
    else:
        try:
            text = base64.b64decode(e.get("payload_b64") or "").decode("utf-8", "replace")
        except ValueError:
            text = "(undecodable payload)"
    text = " ".join(text.split())
    return text[:110] + ("…" if len(text) > 110 else "")


def watched_topics(mark_seen):
    """Section 3. Returns 0 if every watched topic was read, 2 if any could not be (NOT CHECKED)."""
    watched = _watched()
    if not watched:
        return 0
    try:
        seen = json.load(open(SEEN_FILE)) if os.path.exists(SEEN_FILE) else {}
    except (OSError, ValueError) as e:
        print("Watched peer topics:\n  NOT CHECKED: marker %s unreadable: %s" % (SEEN_FILE, e))
        return 2
    rc, lines, new_seen = 0, [], dict(seen)
    for topic, sender, label, baseline in watched:
        after = int(seen.get(topic, baseline))
        try:
            posts = _topic_posts(topic, after)
        except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as e:
            lines.append("NOT CHECKED: %s — %s" % (topic, e))
            rc = 2
            continue
        for e in posts:
            if e.get("sender_id") == sender:
                ts = datetime.datetime.fromtimestamp(e.get("ts", 0) / 1000, datetime.timezone.utc)
                lines.append("%s [%s@%d] %s %s: %s" % (label, topic, e["offset"], ts.strftime("%m-%d %H:%MZ"),
                                                      e.get("msg_type", "?"), _summary(e)))
        if posts:
            new_seen[topic] = max(p["offset"] for p in posts)
    failed = sum(1 for ln in lines if ln.startswith("NOT CHECKED"))
    unseen = len(lines) - failed
    head = "%d unseen" % unseen if unseen else "nothing unseen"
    if failed:  # never let an unread topic sit under a heading that reads as all-clear
        head = "%s, %d topic(s) NOT CHECKED" % ("%d unseen" % unseen if unseen else "none unseen in what was read",
                                               failed)
    print("Watched peer topics: %s" % head)
    for ln in lines:
        print("  " + ln)
    if mark_seen and rc == 0:
        os.makedirs(os.path.dirname(SEEN_FILE), exist_ok=True)
        with open(SEEN_FILE, "w") as fh:
            json.dump(new_seen, fh, indent=1, sort_keys=True)
    return rc


def aef_pin():
    """T-1187: is AEF serving our latest designer release? One line; never fails the run."""
    # Spelled root/"tools"/name so _t451's census sees the call (T-1191).
    tool = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tools", "_t1187-aef-pin-lag.sh")
    try:
        r = subprocess.run(["bash", tool], capture_output=True, text=True, timeout=30)
        line = (r.stdout.strip().splitlines() or ["(no output)"])[-1]
        if r.returncode == 2:
            line = "NOT CHECKED — " + line
    except (OSError, subprocess.TimeoutExpired) as e:
        line = "NOT CHECKED — %s" % e
    print("AEF designer pin: %s" % line)


def stale_review_docs():
    """T-1152: [REVIEW] criteria pointing at a document older than the task. One line; never fails the run."""
    tool = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tools", "_t1152-stale-review-doc.py")
    try:
        r = subprocess.run([sys.executable, tool], capture_output=True, text=True, timeout=90)
        lines = r.stdout.strip().splitlines() or ["(no output)"]
        if r.returncode == 1:
            tasks = sorted({l.split()[1] for l in lines if l.startswith("STALE ")}, key=lambda t: int(t[2:]))
            line = "%d finding(s) in %s — run: python3 tools/_t1152-stale-review-doc.py" % (
                len([l for l in lines if l.startswith("STALE ")]), ", ".join(tasks))
        elif r.returncode in (0, 3):
            line = lines[-1]
        else:
            line = "NOT CHECKED — exit %d: %s" % (r.returncode, (r.stderr.strip().splitlines() or [""])[-1][:120])
    except (OSError, subprocess.TimeoutExpired) as e:
        line = "NOT CHECKED — %s" % e
    print("Stale [REVIEW] docs: %s" % line)


def identity_coverage():
    """T-1203: does every entry point sign with 832's own TermLink key? One line; never fails the run."""
    tool = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "tools", "_t1203-identity-coverage.sh")
    try:
        r = subprocess.run(["bash", tool], capture_output=True, text=True, timeout=60)
        lines = r.stdout.strip().splitlines() or ["(no output)"]
        if r.returncode == 0:
            line = lines[-1]
        elif r.returncode == 1:
            fails = [l.split(None, 1)[1].strip() for l in lines if l.lstrip().startswith("FAIL ")]
            line = "%d FAIL — %s — run: bash tools/_t1203-identity-coverage.sh" % (len(fails), "; ".join(fails))
        else:
            line = "NOT CHECKED — " + lines[-1]
    except (OSError, subprocess.TimeoutExpired) as e:
        line = "NOT CHECKED — %s" % e
    print("TermLink identity: %s" % line)


def mark_seen_ids(ids):
    """T-1248: mark as shown ONLY the messages named (full id or a unique prefix of one listed now). A blanket
    --mark-seen marks every listed message, read or not, and a shown message is withheld from the mail watcher
    and the prompt hook: greenfield's T-4415 answer sat unseen that way. Prints each id it marked; an id that
    matches nothing listed, or more than one, is refused (exit 2) and nothing is marked."""
    try:
        r = subprocess.run([FW, "sidecar", "alerts", "--limit", "0", "--json"], capture_output=True, text=True,
                           timeout=180)
        listed = [m["id"] for m in json.loads(r.stdout).get("mail", [])]
    except (OSError, subprocess.TimeoutExpired, ValueError, KeyError) as e:
        print("MARK NOT DONE: could not list mail: %s" % e)
        return 2
    chosen = []
    for want in ids:
        hits = [m for m in listed if m == want or m.startswith(want)]
        if len(hits) != 1:
            print("MARK NOT DONE: %r matches %d listed message(s); nothing marked" % (want, len(hits)))
            return 2
        chosen.append(hits[0])
    sys.path.insert(0, os.path.join(ROOT, ".agentic-framework", "lib"))
    from sidecar import receiver, seen
    seen.mark_shown([(m, receiver.read_message(m)) for m in chosen], by="alerts")
    for m in chosen:
        print("marked shown: %s" % m)
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--mark-seen", action="store_true",
                    help="marks EVERY listed message shown; prefer --mark-seen-ids with the ids you have read (T-1248)")
    ap.add_argument("--mark-seen-ids", nargs="+", metavar="ID",
                    help="mark only these messages shown (full id or unique prefix), then exit (T-1248)")
    a = ap.parse_args(argv)
    if a.mark_seen_ids:
        return mark_seen_ids(a.mark_seen_ids)
    print_runme()  # first, so a failed mail check below cannot hide it
    rc_mail = mail(a.limit, a.mark_seen)
    rc_topics = watched_topics(a.mark_seen)
    # T-1244: ALERTS_SKIP_LIVE_CHECKS=1 (tests only) skips the three read-only live probes below. They touch the
    # network, every task file and the hub, take 5-10s each and have nothing to do with the runme/mail sections the
    # runme-alerts test drives; under full-suite load they pushed one call past that test's subprocess timeout.
    if os.environ.get("ALERTS_SKIP_LIVE_CHECKS") != "1":
        aef_pin()
        stale_review_docs()
        identity_coverage()
    return max(rc_mail, rc_topics)


if __name__ == "__main__":
    sys.exit(main())
