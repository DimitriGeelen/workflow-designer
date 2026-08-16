#!/usr/bin/env python3
"""T-544 teeth — the session cookie must be named for the port actually bound.

`web/app.py` scopes the Flask session cookie by port on purpose. Its own
comment (T-2278) says why: RFC 6265 does not scope cookies by port, so two
Watchtowers on one host share `SESSION_COOKIE_NAME` and each overwrites the
other's session, breaking CSRF on every cross-instance POST.

The defence was reading the wrong port. `SESSION_COOKIE_NAME` is built from
`Config.PORT`, which reads `FW_PORT` or falls back to 3000, and `--port` never
updates it — it moves the listening socket and nothing else. `create_app()`
also runs at module import, before argparse exists. Measured on this host:
AEF's Watchtower on :3000 and this project's on :3012 BOTH emitted
`fw_session_3000`, and because each signs with its own `.fw-secret-key` the
survivor's cookie could not even be decoded by the other — `session` came back
empty, `session.get("_csrf_token")` was None, and every state-changing POST
403'd as "Session expired" on a freshly loaded page with no restart.

A guard that names the wrong port is worse than no guard: it reads as
protection in code review and in the comment, and the failure it permits
presents to the user as an expired session rather than as a collision.

MEASURED END-TO-END, NOT READ. The property is about the socket that is
actually bound, so a static check of the source could not establish it — the
whole defect was source that looked correct. This starts a real instance on a
real port and reads the real `Set-Cookie`.

The fixture is mutation-sensitive BY CONSTRUCTION rather than by an injected
mutant: the probe binds a port that is deliberately NOT the default, so the
pre-fix code path can only emit `fw_session_<default>` and the leg goes red.
Leg 0 refuses if that separation ever collapses, since a probe that binds the
default port would pass whether the fix is present or not.

Exit codes:  0 = green   1 = a leg is red   2 = REFUSE (stimulus not established)
"""

import os
import re
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FW = ROOT / ".agentic-framework"
APP = FW / "web" / "app.py"

# The value `Config.PORT` falls back to when FW_PORT is unset — i.e. the name
# the BROKEN code path would emit regardless of what it bound.
DEFAULT_PORT = 3000
BOOT_TIMEOUT_S = 25


def refuse(msg):
    print("REFUSE: %s" % msg)
    sys.exit(2)


def free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def main():
    if not APP.is_file():
        refuse("web/app.py not found at %s" % APP)

    # ── Leg 0 — the default port must still be what the broken path would use.
    #    If the fallback ever changes, the separation this probe relies on is
    #    gone and every leg below would pass without testing anything.
    src = APP.read_text(encoding="utf-8")
    m = re.search(r'PORT\s*=\s*int\(os\.environ\.get\("FW_PORT",\s*"(\d+)"\)\)',
                  (FW / "web" / "config.py").read_text(encoding="utf-8"))
    if not m:
        refuse("could not locate Config.PORT's fallback in web/config.py — the "
               "probe cannot know which name the broken path would emit")
    if int(m.group(1)) != DEFAULT_PORT:
        refuse("Config.PORT fallback is %s, this probe assumes %d — update "
               "DEFAULT_PORT or the discrimination below is meaningless"
               % (m.group(1), DEFAULT_PORT))
    if "SESSION_COOKIE_NAME" not in src:
        refuse("web/app.py no longer sets SESSION_COOKIE_NAME at all — the "
               "port-scoping defence this probe guards has been removed, which "
               "is a bigger change than a red leg should quietly report")

    port = free_port()
    if port == DEFAULT_PORT:
        refuse("the OS handed out the default port %d — this run could not tell "
               "a fixed build from a broken one" % DEFAULT_PORT)

    failures = []
    env = dict(os.environ)
    env.pop("FW_PORT", None)          # the exact condition that exposed the bug
    env["PROJECT_ROOT"] = str(ROOT)

    proc = subprocess.Popen(
        [sys.executable, "-m", "web.app", "--port", str(port)],
        cwd=str(FW), env=env,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    cookie_names: list[str] = []
    try:
        deadline = time.time() + BOOT_TIMEOUT_S
        raw_headers = None
        while time.time() < deadline:
            if proc.poll() is not None:
                refuse("the instance exited during boot (rc=%s) — nothing was "
                       "measured" % proc.returncode)
            try:
                with urllib.request.urlopen(
                        "http://127.0.0.1:%d/approvals" % port, timeout=3) as r:
                    raw_headers = r.headers
                    break
            except (urllib.error.URLError, ConnectionError, OSError):
                time.sleep(0.5)
        if raw_headers is None:
            refuse("instance on :%d never answered within %ds — nothing was "
                   "measured, which is not a pass" % (port, BOOT_TIMEOUT_S))

        cookie_names = [
            v.split("=", 1)[0].strip()
            for v in raw_headers.get_all("Set-Cookie") or []
        ]
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()

    if not cookie_names:
        refuse("the instance set no cookie at all on /approvals — the property "
               "under test is unobservable, so this is a refusal not a pass")

    expected = "fw_session_%d" % port
    broken = "fw_session_%d" % DEFAULT_PORT

    # ── Leg 1 — the name follows the BOUND port.
    if expected not in cookie_names:
        failures.append(
            "leg1: instance bound to :%d set %s, not %s. The cookie name is not "
            "derived from the port actually bound." % (port, cookie_names, expected))

    # ── Leg 2 — and specifically is NOT the default. Separated from leg 1 so the
    #    report distinguishes 'named something else' from 'fell back to the
    #    default', which is the regression with a known blast radius: it puts
    #    this instance back in a shared cookie slot with every other Watchtower
    #    on the host and breaks CSRF on both.
    if broken in cookie_names and broken != expected:
        failures.append(
            "leg2: instance bound to :%d set %s — the pre-T-544 path, built from "
            "Config.PORT rather than the bound port. Any second Watchtower on "
            "this host now shares this cookie slot and both will 403 on every "
            "state-changing POST, reported to the user as 'Session expired'."
            % (port, broken))

    print("T-544 session-cookie port-scoping teeth")
    print("    bound port         : %d   (default, i.e. the broken name: %d)"
          % (port, DEFAULT_PORT))
    print("    FW_PORT            : unset (the condition that exposed the bug)")
    print("    Set-Cookie name(s) : %s" % ", ".join(cookie_names))
    print("    expected           : %s" % expected)

    if failures:
        print("\n%d finding(s):" % len(failures))
        for f in failures:
            print("  - %s" % f)
        return 1
    print("\nall legs green")
    return 0


if __name__ == "__main__":
    sys.exit(main())
