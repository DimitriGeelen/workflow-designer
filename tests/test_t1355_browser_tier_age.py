#!/usr/bin/env python3
"""T-1355: the browser tier's age line — green, red, stale by a framework commit, stale by age, no run recorded.

Hermetic: a temp history file and a temp git repo whose .agentic-framework/ gets one commit at a chosen time.
Exit 0 = all cases pass.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "tools", "_t1355-browser-tier-age.py")
fails = []


def repo_with_framework_commit(at):
    d = tempfile.mkdtemp(prefix="t1355-repo-")
    env = dict(os.environ, GIT_AUTHOR_DATE=at, GIT_COMMITTER_DATE=at, GIT_AUTHOR_NAME="t", GIT_AUTHOR_EMAIL="t@t",
               GIT_COMMITTER_NAME="t", GIT_COMMITTER_EMAIL="t@t", GIT_CEILING_DIRECTORIES=os.path.dirname(d))
    os.makedirs(os.path.join(d, ".agentic-framework"))
    open(os.path.join(d, ".agentic-framework", "VERSION"), "w").write("x\n")
    for cmd in (["git", "init", "-q"], ["git", "add", "."], ["git", "commit", "-q", "-m", "fw"]):
        subprocess.run(cmd, cwd=d, env=env, check=True, capture_output=True)
    return d


def run(rows, fw_at, now):
    h = tempfile.NamedTemporaryFile("w", suffix=".tsv", delete=False)
    h.write("".join("\t".join(r) + "\n" for r in rows))
    h.close()
    env = dict(os.environ, T1355_HISTORY=h.name, T1355_REPO=repo_with_framework_commit(fw_at), T1355_NOW=now)
    r = subprocess.run([sys.executable, TOOL], capture_output=True, text=True, env=env, timeout=60)
    return r.returncode, r.stdout.strip()


def case(name, got, rc, word):
    ok = got[0] == rc and got[1].startswith(word)
    print("%s  %s  -> rc %d: %s" % ("PASS" if ok else "FAIL", name, got[0], got[1][:110]))
    if not ok:
        fails.append(name)


FW_OLD = "2026-10-01T00:00:00Z"
NOW = "2026-11-01T12:00:00Z"
core = ["2026-11-01T11:00:00Z", "217", "0", "0", "800", "aaaaaaaaa", "core", "0", "0"]
green = ["2026-11-01T10:00:00Z", "132", "0", "0", "800", "bbbbbbbbb", "browser", "0", "0"]
red = ["2026-11-01T10:00:00Z", "129", "3", "1", "800", "ccccccccc", "browser", "0", "0"]
old = ["2026-10-20T10:00:00Z", "132", "0", "0", "800", "ddddddddd", "browser", "0", "0"]
full = ["2026-11-01T10:00:00Z", "349", "0", "0", "1800", "eeeeeeeee"]

case("fresh green browser run", run([green, core], FW_OLD, NOW), 0, "OK")
case("a full run (no tier column) counts as a browser run", run([full], FW_OLD, NOW), 0, "OK")
case("red last browser run, a later green core run does not hide it", run([red, core], FW_OLD, NOW), 1, "RED")
case("stale: framework committed after the run", run([green], "2026-11-01T11:30:00Z", NOW), 1, "STALE")
case("stale: older than 7 days", run([old], FW_OLD, NOW), 1, "STALE")
case("the latest browser row wins over an older red one", run([red, ["2026-11-01T11:00:00Z"] + green[1:]], FW_OLD, NOW), 0, "OK")
case("no browser run recorded is NOT CHECKED, not OK", run([core], FW_OLD, NOW), 3, "NOT CHECKED")

print("T-1355: %s — %d case(s) failed" % ("RED" if fails else "GREEN", len(fails)))
sys.exit(1 if fails else 0)
