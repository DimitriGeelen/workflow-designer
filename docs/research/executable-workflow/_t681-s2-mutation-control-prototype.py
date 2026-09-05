#!/usr/bin/env python3
"""T-681 S2 (IW-2) — can the mutation control be built WITHOUT introducing a real
breach path into the shipped tree?

The control asserts one property: a POST to /api/save cannot write outside the
version store. It must go RED when the guard is removed, or it is decoration.

Everything happens against a THROWAWAY copy of gallery-serve.py, with --repo and
--docroot pointed into a throwaway root. The shipped tree is never mutated and is
never the server's repo. That is the whole point of the spike: if the red state can
only be produced by breaking the real file, IW-2 resolves negative and the arc's
recommendation flips to NO-GO.

Sequence:
  1. baseline   — pristine copy, traversal id  -> MUST be refused        (GREEN)
  2. mutated    — ID_RE widened to allow . and /, same id -> MUST escape (RED)
  3. reverted   — pristine copy again, same id -> MUST be refused        (GREEN)

A control that never shows RED in step 2 proves nothing; this script fails loudly
if step 2 does not breach.
"""
import http.client
import json
import os
import re
import shutil
import socket
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REAL_SERVER = "/opt/832-Workflow-designer/tools/gallery-serve.py"
ROOT = os.path.join(HERE, "s2-root")
SERVER_COPY = os.path.join(ROOT, "gallery-serve-copy.py")
REPO = os.path.join(ROOT, "repo")
DOCROOT = os.path.join(ROOT, "docroot")

# Relative traversal that escapes .editor-versions/<id>/ but stays inside ROOT even
# if it succeeds. A contained breach is still a breach; an uncontained one is a bug
# in the spike.
# Lowercase deliberately: the widened ID_RE only admits [a-z0-9_./-], so an uppercase
# witness is refused by the MUTATED regex too and phase 2 shows a false green. That is
# exactly PL-177 (right answer, broken reason) and it cost this spike one run.
# '../escaped' resolves REPO/.editor-versions/../escaped -> REPO/escaped: outside the
# version store (a real breach) but inside the throwaway root (contained).
ESCAPE_ID = "../escaped"
ESCAPE_WITNESS = os.path.join(REPO, "escaped")

PRISTINE_ID_RE = "ID_RE = re.compile(r'^[a-z0-9][a-z0-9_-]*$')"
MUTATED_ID_RE = "ID_RE = re.compile(r'^[a-z0-9.\\-/][a-z0-9_./-]*$')"


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def fresh_root():
    shutil.rmtree(ROOT, ignore_errors=True)
    os.makedirs(REPO)
    os.makedirs(DOCROOT)
    shutil.copy2(REAL_SERVER, SERVER_COPY)


def mutate(enable):
    """Widen ID_RE in the COPY only. Returns True if the edit actually landed."""
    with open(SERVER_COPY) as f:
        src = f.read()
    want_from, want_to = (PRISTINE_ID_RE, MUTATED_ID_RE) if enable else (MUTATED_ID_RE, PRISTINE_ID_RE)
    if want_from not in src:
        raise SystemExit("SPIKE BROKEN: expected to find in copy:\n  %s" % want_from)
    with open(SERVER_COPY, "w") as f:
        f.write(src.replace(want_from, want_to, 1))
    return True


def start(port):
    p = subprocess.Popen(
        [sys.executable, SERVER_COPY, "--repo", REPO, "--docroot", DOCROOT,
         "--bind", "127.0.0.1", str(port)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )
    for _ in range(80):
        try:
            c = http.client.HTTPConnection("127.0.0.1", port, timeout=0.5)
            c.request("GET", "/api/health")
            c.getresponse().read()
            c.close()
            return p
        except Exception:
            if p.poll() is not None:
                raise SystemExit("SPIKE BROKEN: server exited early (rc=%s)" % p.returncode)
            time.sleep(0.05)
    p.kill()
    raise SystemExit("SPIKE BROKEN: server never became healthy on port %d" % port)


def attempt_save(port, id_):
    body = json.dumps({"id": id_, "bpmn": "<definitions/>"})
    c = http.client.HTTPConnection("127.0.0.1", port, timeout=5)
    c.request("POST", "/api/save", body, {"Content-Type": "application/json"})
    r = c.getresponse()
    status, payload = r.status, r.read().decode("utf-8", "replace")
    c.close()
    return status, payload


def run_phase(label, mutated):
    port = free_port()
    proc = start(port)
    try:
        status, payload = attempt_save(port, ESCAPE_ID)
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
    escaped = os.path.exists(ESCAPE_WITNESS)
    print("  %-9s ID_RE=%-8s HTTP %-3d  escaped=%-5s  %s"
          % (label, "MUTATED" if mutated else "pristine", status, escaped,
             payload.strip()[:70]))
    return status, escaped


def main():
    print("T-681 S2 — mutation control for the /api/save write path")
    print("shipped tree is read-only here; server copy + repo + docroot all under")
    print("  %s\n" % ROOT)

    fresh_root()

    print("phase 1of3 — BASELINE (the fence must hold)")
    s1_status, s1_escaped = run_phase("baseline", False)
    baseline_ok = s1_status == 400 and not s1_escaped

    print("\nphase 2of3 — MUTATED (the fence must BREAK, or it proves nothing)")
    mutate(True)
    s2_status, s2_escaped = run_phase("mutated", True)
    breached = s2_escaped

    print("\nphase 3of3 — REVERTED (the fence must hold again)")
    mutate(False)
    # versions_dir() makedirs the escaped path, so the witness is a DIRECTORY.
    if os.path.isdir(ESCAPE_WITNESS):
        shutil.rmtree(ESCAPE_WITNESS)
    elif os.path.exists(ESCAPE_WITNESS):
        os.remove(ESCAPE_WITNESS)
    s3_status, s3_escaped = run_phase("reverted", False)
    revert_ok = s3_status == 400 and not s3_escaped

    # The shipped file must be byte-identical to what we started with.
    with open(REAL_SERVER, "rb") as f:
        shipped = f.read()
    shipped_pristine = PRISTINE_ID_RE.encode() in shipped and MUTATED_ID_RE.encode() not in shipped

    print("\n" + "=" * 72)
    print("baseline refuses traversal      : %s" % ("PASS" if baseline_ok else "FAIL"))
    print("mutated copy DOES breach (red)  : %s" % ("PASS" if breached else "FAIL"))
    print("revert restores the fence       : %s" % ("PASS" if revert_ok else "FAIL"))
    print("shipped tree never mutated      : %s" % ("PASS" if shipped_pristine else "FAIL"))
    verdict = baseline_ok and breached and revert_ok and shipped_pristine
    print("\nIW-2 VERDICT: %s" % ("BUILDABLE — control has a demonstrated red state"
                                  if verdict else
                                  "NOT BUILDABLE — returns to the operator as a failed GO condition"))
    print("=" * 72)
    return 0 if verdict else 1


if __name__ == "__main__":
    sys.exit(main())
