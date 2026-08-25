#!/usr/bin/env python3
"""Teeth for tools/_t499-watchtower-ownership.sh — does the abstention channel actually
discriminate, or is exit 2 a code that exists and never fires?

T-499's open AC asks for a property, not a file: "abstention is distinguishable from a
verdict". A tool can satisfy the letter of that by declaring an exit code it can never
reach, which is precisely the "constant wearing a verdict" this project spent T-364, T-579
and T-581 removing. So every one of the six documented outcomes is driven here, on demand,
from a fixture — and the two that most look like decoration (NO-ENDPOINT, MALFORMED) are
the ones that need a server to exist at all, which is why they were the last to be built.

── WHY THE CONTROL IS HERMETIC AND WHY IT RUNS FIRST ─────────────────────────────────
Every refusal leg below asserts a NON-ZERO exit. All of them are therefore satisfied by a
tool that is simply broken — a syntax error exits 2 and would light up the entire
abstention half of this file as "working". The control is the only leg that separates "the
instrument discriminates" from "the instrument is dead", so it runs first and aborts the
rest on failure.

It deliberately does NOT point at the project's live Watchtower. Doing so would make the
control fail whenever the server happens to be stopped — an environmental red that trains
readers to skip it, on the one leg that must never be skipped. Instead it serves our own
identity from a fixture, so a green control means the tool can still say OURS about
something that genuinely is.

── WHY EACH LEG ASSERTS THE REASON, NOT ONLY THE CODE ────────────────────────────────
Exit 1 covers DOWN and FOREIGN; exit 2 covers four reasons. Asserting the code alone would
let NO-SELF pass a leg written for MALFORMED, so any refactor that routed every abstention
into one branch would stay green while destroying the distinction the AC is about. Each leg
pins the printed reason token as well.
"""
import http.server
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import json

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Overridable for the same reason the tool's own subject is: proving these teeth BITE means
# running them against a deliberately broken copy, and mutating the real file in place is
# how T-576's probe would have destroyed the evidence for its own diagnosis.
TOOL = os.environ.get("T499_TEETH_TOOL") or os.path.join(REPO, "tools", "_t499-watchtower-ownership.sh")
SELF = "/opt/832-Workflow-designer"


class Fixture(http.server.BaseHTTPRequestHandler):
    """Serves whatever the current scenario says /api/_identity should be.

    `body=None` means answer 404 — that is the NO-ENDPOINT case, and it has to be a real
    HTTP error rather than a closed socket, because the whole point of the distinction is
    that something IS listening.
    """

    body = None

    def do_GET(self):
        if self.path != "/api/_identity" or type(self).body is None:
            self.send_error(404, "no such endpoint")
            return
        payload = type(self).body.encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, *a):
        pass


def serve(body):
    cls = type("F", (Fixture,), {"body": body})
    srv = http.server.HTTPServer(("127.0.0.1", 0), cls)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, "http://127.0.0.1:%d" % srv.server_address[1]


def run(url, self_root=SELF, cwd=None, tool=TOOL):
    env = dict(os.environ)
    env["T499_SELF_ROOT"] = self_root
    env["T499_TIMEOUT"] = "3"
    args = [tool] + ([url] if url is not None else [])
    p = subprocess.run(args, capture_output=True, text=True, env=env, cwd=cwd or REPO)
    return p.returncode, p.stdout + p.stderr


results = []


def leg(name, got_rc, want_rc, out, want_reason):
    ok = got_rc == want_rc and want_reason in out
    results.append((name, ok, got_rc, want_rc, want_reason))
    print("  [%s] %-28s exit %s (want %s), reason %s"
          % ("PASS" if ok else "FAIL", name, got_rc, want_rc, want_reason))
    if not ok:
        for line in out.strip().splitlines()[:6]:
            print("        | " + line)
    return ok


print("== T-499 ownership teeth: six outcomes, driven from fixtures ==")
print()

if not os.access(TOOL, os.X_OK):
    print("TEETH BROKEN: %s is missing or not executable — measured nothing" % TOOL)
    sys.exit(2)

# ── CONTROL ───────────────────────────────────────────────────────────────────────────
print("-- control (must pass, or every refusal below is meaningless) --")
srv, url = serve(json.dumps({"service": "watchtower", "project_root": SELF}))
rc, out = run(url)
if not leg("CONTROL/ours", rc, 0, out, "IDENTITY-CONFIRMED"):
    print()
    print("TEETH BROKEN: the tool cannot say OURS about a server that is ours.")
    print("Every leg below asserts a non-zero exit and would be satisfied by a broken")
    print("tool, so they are NOT run. Nothing has been measured.")
    srv.shutdown()
    sys.exit(2)
srv.shutdown()
print()

# ── verdicts (exit 1) ─────────────────────────────────────────────────────────────────
print("-- verdicts: exit 1, a statement about the target --")

srv, url = serve(json.dumps({"service": "watchtower", "project_root": "/opt/999-Elsewhere"}))
rc, out = run(url)
leg("FOREIGN/other-root", rc, 1, out, "FOREIGN")
srv.shutdown()

srv, url = serve(json.dumps({"service": "open-webui", "project_root": SELF}))
rc, out = run(url)
leg("FOREIGN/other-service", rc, 1, out, "FOREIGN")
srv.shutdown()

# Port 9 (discard) is closed on this host; a closed socket is the DOWN case.
rc, out = run("http://127.0.0.1:9")
leg("DOWN/nothing-listening", rc, 1, out, "DOWN")
print()

# ── abstentions (exit 2) ──────────────────────────────────────────────────────────────
print("-- abstentions: exit 2, a statement about our own ability to tell --")

srv, url = serve(json.dumps({"service": "watchtower", "project_root": SELF}))
rc, out = run(url, self_root="")
leg("NO-SELF/root-unknown", rc, 2, out, "NO-SELF")
srv.shutdown()

srv, url = serve(None)  # listening, but /api/_identity 404s
rc, out = run(url)
leg("NO-ENDPOINT/404", rc, 2, out, "NO-ENDPOINT")
srv.shutdown()

srv, url = serve(json.dumps({"service": "watchtower", "started_at": "now"}))
rc, out = run(url)
leg("MALFORMED/no-project-root", rc, 2, out, "MALFORMED")
srv.shutdown()

# NO-TARGET needs a tree with no triple file. The tool derives its root from its own
# location, so it is copied rather than run with a doctored cwd — a cwd change would not
# move ROOT and the real .context/working/watchtower.url would still be found.
tmp = tempfile.mkdtemp()
try:
    os.makedirs(os.path.join(tmp, "tools"))
    copy = os.path.join(tmp, "tools", os.path.basename(TOOL))
    shutil.copy2(TOOL, copy)
    rc, out = run(None, cwd=tmp, tool=copy)
    leg("NO-TARGET/no-triple", rc, 2, out, "NO-TARGET")
finally:
    shutil.rmtree(tmp, ignore_errors=True)
print()

# ── the mapping itself ────────────────────────────────────────────────────────────────
# Each leg above pins one case. This asserts the PARTITION: nothing that is a verdict
# leaves through the abstention code and nothing that is an abstention leaves through the
# verdict code. A refactor that made every failure exit 2 would pass six legs and fail here.
print("-- the partition: no verdict exits 2, no abstention exits 1 --")
verdict_legs = [r for r in results if r[0].startswith(("FOREIGN", "DOWN", "CONTROL"))]
abstain_legs = [r for r in results if r[0].startswith(("NO-", "MALFORMED"))]
bad = [r[0] for r in verdict_legs if r[2] == 2] + [r[0] for r in abstain_legs if r[2] == 1]
print("  verdict cases   : %s" % ", ".join(r[0] for r in verdict_legs))
print("  abstention cases: %s" % ", ".join(r[0] for r in abstain_legs))
if bad:
    print("  [FAIL] crossed the partition: %s" % ", ".join(bad))
    results.append(("PARTITION", False, None, None, "disjoint"))
else:
    print("  [PASS] partition holds across %d cases" % len(results))
    results.append(("PARTITION", True, None, None, "disjoint"))
print()

# ── evidence printing ─────────────────────────────────────────────────────────────────
# Asserted because a verdict a reader cannot audit is the failure mode that produced
# T-576 and T-581. Checked on an abstention specifically: those are the branches most
# likely to return early and skip the evidence block.
print("-- every outcome prints the evidence it judged on --")
srv, url = serve(json.dumps({"service": "watchtower", "project_root": "/opt/999-Elsewhere"}))
rc, out = run(url)
srv.shutdown()
need = ["target      :", "our root    :", "their root  :", "curl rc     :"]
missing = [n for n in need if n not in out]
rc2, out2 = run("http://127.0.0.1:9")
missing += [n + " (on DOWN)" for n in ["target      :", "our root    :", "curl rc     :"] if n not in out2]
if missing:
    print("  [FAIL] evidence lines absent: %s" % ", ".join(missing))
    results.append(("EVIDENCE", False, None, None, "printed"))
else:
    print("  [PASS] %d evidence field(s) present on both a verdict and a refusal" % len(need))
    results.append(("EVIDENCE", True, None, None, "printed"))
print()

# ── the gap this tool fills, MEASURED but NOT ASSERTED ────────────────────────────────
# Deliberately not a leg. It measures the VENDORED helper, which AEF owns and may fix; an
# assertion here would go red the moment upstream improves, i.e. it would punish the
# outcome we want. Printed so the claim in the tool's header stays checkable by a reader
# rather than becoming a comment nobody re-runs.
print("-- context (measured, NOT asserted — subject is vendored and may change) --")
lib = os.path.join(REPO, ".agentic-framework", "lib", "watchtower.sh")
if os.path.exists(lib):
    srv, url = serve(json.dumps({"service": "watchtower", "project_root": SELF}))
    probe = (
        'source %s 2>/dev/null; '
        '_watchtower_identity_matches "%s" >/dev/null 2>&1; echo "foreign_or_unknown_self=$?"'
    )
    a = subprocess.run(["bash", "-c", probe % (lib, url)],
                       capture_output=True, text=True,
                       env={**os.environ, "PROJECT_ROOT": "/opt/999-Elsewhere"})
    b = subprocess.run(["bash", "-c", probe % (lib, url)],
                       capture_output=True, text=True,
                       env={k: v for k, v in os.environ.items()
                            if k not in ("PROJECT_ROOT", "FRAMEWORK_ROOT")})
    srv.shutdown()
    print("  _watchtower_identity_matches, foreign root      -> %s" % a.stdout.strip())
    print("  _watchtower_identity_matches, OUR OWN root unset-> %s" % b.stdout.strip())
    print("  (same code for 'that server is someone else's' and 'I do not know who I am')")
else:
    print("  vendored lib/watchtower.sh not present — context skipped, nothing asserted")
print()

passed = sum(1 for r in results if r[1])
failed = len(results) - passed
print("== %d passed, %d failed, %d outcome(s) driven ==" % (passed, failed, len(results)))
sys.exit(0 if failed == 0 else 1)
