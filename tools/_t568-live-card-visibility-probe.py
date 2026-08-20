#!/usr/bin/env python3
"""_t568-live-card-visibility-probe.py — the HTTP-level version of the reported bug.

The teeth script (`_t568-fabric-card-cache-teeth.sh`) proves `_load_components()` reacts to
an in-place edit, with mutants pinning what each leg asserts. This probe answers the
different question the report actually asked: does the RUNNING dashboard show the current
card? A correct loader that the live process never picked up is still a stale page, and
that distinction is the whole of PL-148 — an instrument's wiring must be asserted by
something other than the instrument.

The reproduction is 001-CashWeb-Lightspeed-Ecwid-integration's, made exact:

  1. write a throwaway card (creating a file bumps the directory mtime, so BOTH the old
     and the new loader see it — this step is deliberately not the test);
  2. fetch it and require the page to show the written purpose;
  3. rewrite it IN PLACE and restore the directory's mtime **to the nanosecond**, so the
     only observable change is the file's own bytes;
  4. fetch again and require the NEW purpose.

Step 3's precision is load-bearing and was learned the hard way here: `stat -c %Y` and
`touch -d @<seconds>` round to whole seconds, which silently CHANGES a directory mtime
that carried a fractional part — and a directory whose mtime "changed" invalidates the old
cache too, so the broken code passes. The first run of this probe reported a pass for
exactly that reason. os.utime(..., ns=...) plus an equality assertion closes it.

The throwaway card is removed on every exit path, including failure.

NO SILENT SKIP, AND NO EXTERNAL DEPENDENCY EITHER. If the deployed Watchtower is
reachable this tests THAT one, because "the deployed dashboard is stale" is the fact the
report is about. If it is not reachable the probe SPAWNS its own instance on an ephemeral
port rather than skipping — a leg that passes when it never ran is the same defect this
whole task is about (T-560), and a probe that can only run when a server happens to be up
cannot be wired into the gating suite, which is how `_t567-episodic-parse-check.py` ended
up as an unwired guard one task earlier.

Exit 0 = a live page reflects an in-place card edit. 1 = it does not. 2 = could not run.
"""
import os
import re
import shutil
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARD = os.path.join(ROOT, ".fabric", "components", "t568-probe.yaml")
CDIR = os.path.dirname(CARD)
CID = "t568-probe"


def card(value: str) -> str:
    return (
        "id: %s\nname: %s\ntype: script\nsubsystem: designer-carrier\n"
        "location: tools/_t568-fabric-card-cache-teeth.sh\npurpose: \"%s\"\n"
        % (CID, CID, value)
    )


def base_url() -> str:
    p = os.path.join(ROOT, ".context", "working", "watchtower.url")
    if not os.path.exists(p):
        return ""
    return open(p).read().strip()


def fetch(url: str) -> str:
    html = urllib.request.urlopen(url + "/fabric/component/" + CID, timeout=10).read().decode()
    m = re.search(r"T568-PURPOSE-[A-Z-]+", html)
    return m.group(0) if m else "(purpose not rendered)"


def reachable(url: str, timeout: float = 20.0) -> bool:
    # 20s, not 1s. A COLD Watchtower's first `/` render is not fast — it walks the task
    # tree, the git log and the fabric — and a 1s readiness poll reports "never came up"
    # for a server that is already listening and answering. Measured here: the spawned
    # instance was bound on 127.0.0.1 while sixty consecutive 1s probes all timed out.
    try:
        urllib.request.urlopen(url + "/", timeout=timeout).read()
        return True
    except Exception:  # noqa: BLE001
        return False


def spawn_watchtower():
    """Start a private Watchtower on an ephemeral port. Returns (url, proc) or (None, None).

    Used only when the deployed instance is unreachable, so that this probe can be wired
    into the gating suite instead of depending on an operator's server being up.
    """
    import socket

    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    fw = os.path.join(ROOT, ".agentic-framework")
    env = dict(os.environ, PROJECT_ROOT=ROOT, FW_PORT=str(port))
    proc = subprocess.Popen(
        [sys.executable, "-m", "web.app", "--port", str(port)],
        cwd=fw, env=env,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    url = "http://127.0.0.1:%d" % port
    for _ in range(6):
        if proc.poll() is not None:
            return None, None
        if reachable(url):
            return url, proc
        time.sleep(0.5)
    proc.terminate()
    return None, None


def main() -> int:
    proc = None
    url = base_url()
    where = "the deployed Watchtower"
    if not url or not reachable(url):
        url, proc = spawn_watchtower()
        where = "a private Watchtower spawned by this probe"
        if not url:
            print("CANNOT RUN: no Watchtower reachable and none could be started",
                  file=sys.stderr)
            return 2
    if os.path.exists(CARD):
        print("CANNOT RUN: %s already exists — refusing to clobber it" % CARD, file=sys.stderr)
        return 2

    try:
        with open(CARD, "w") as f:
            f.write(card("T568-PURPOSE-BEFORE"))
        time.sleep(0.3)
        seen_before = fetch(url)
        if seen_before != "T568-PURPOSE-BEFORE":
            print("FAIL: fresh card did not render (got %r) — the probe's own premise is "
                  "broken, so nothing below would mean anything" % seen_before)
            return 1

        st = os.stat(CDIR)
        with open(CARD, "w") as f:
            f.write(card("T568-PURPOSE-AFTER"))
        os.utime(CDIR, ns=(st.st_atime_ns, st.st_mtime_ns))
        if os.stat(CDIR).st_mtime_ns != st.st_mtime_ns:
            print("CANNOT RUN: directory mtime could not be restored exactly; without that "
                  "this probe passes on the broken code too", file=sys.stderr)
            return 2
        time.sleep(0.3)
        seen_after = fetch(url)
        if seen_after != "T568-PURPOSE-AFTER":
            print("FAIL: card on disk says AFTER, %s says %r. An in-place edit is invisible "
                  "to the live dashboard — HTTP 200, no signal. (T-568)" % (url, seen_after))
            return 1
        print("PASS: an in-place card edit is visible at %s (%s) with the directory mtime "
              "pinned to the nanosecond" % (url, where))
        return 0
    finally:
        try:
            os.remove(CARD)
        except OSError:
            pass
        if proc is not None:
            try:
                os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
            except OSError:
                proc.terminate()


if __name__ == "__main__":
    sys.exit(main())
