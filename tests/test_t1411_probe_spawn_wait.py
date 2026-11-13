#!/usr/bin/env python3
"""T-1411: the T-568 probe waits for the Watchtower it starts as long as that process lives and is starting.

On 2026-11-13 (load 50-60) a private Watchtower answered after 25 s, the probe gave it about 3 s, and the core leg went
red here while the quiet pool was green: a DISAGREEMENT that refused a push. spawn_watchtower now waits up to
T568_START_S (default 120 s), and still refuses at once when the process exits.

Legs (a stub server instead of Watchtower, through spawn_watchtower's `cmd`):
  1. a server that answers only after 6 s is accepted with the default deadline;
  2. the same server with T568_START_S=2 is refused (the control: a short budget fails, as the old one did);
  3. a process that exits at once is refused, well inside the deadline.
Exit 0 = all legs pass.
"""
import importlib.util
import os
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
spec = importlib.util.spec_from_file_location("t568", os.path.join(ROOT, "tools", "_t568-live-card-visibility-probe.py"))
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)
fails = []

SLOW = [sys.executable, "-c",
        "import time,http.server,sys; time.sleep(6); "
        "http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), http.server.SimpleHTTPRequestHandler).serve_forever()",
        "{port}"]
DIES = [sys.executable, "-c", "import sys; sys.exit(1)"]


def leg(ok, name, detail=""):
    print("%s  %s%s" % ("PASS" if ok else "FAIL", name, (" — " + detail) if detail else ""))
    if not ok:
        fails.append(name)


def run(cmd, budget):
    if budget is None:
        os.environ.pop("T568_START_S", None)
    else:
        os.environ["T568_START_S"] = str(budget)
    t = time.time()
    url, proc = probe.spawn_watchtower(cmd)
    took = time.time() - t
    if proc:
        proc.terminate()
        proc.wait(timeout=10)
    return url, took


def main():
    url, took = run(SLOW, None)
    leg(url is not None, "1 a server that answers after 6 s is accepted (default deadline)", "%.1fs" % took)
    url, took = run(SLOW, 2)
    leg(url is None, "2 control: the same server with a 2 s budget is refused", "%.1fs" % took)
    url, took = run(DIES, None)
    leg(url is None and took < 15, "3 a process that exits is refused at once", "%.1fs" % took)
    print("=== %d failed ===" % len(fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
