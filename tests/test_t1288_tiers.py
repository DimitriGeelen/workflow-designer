#!/usr/bin/env python3
"""T-1288: the tier engine of tests/run-bridge-tests.sh, driven through small fixture runners, never the real suite.

Each fixture runner sources the real tools/_t1288-tiers.sh exactly as the suite does and registers a few legs whose
outcome is chosen by the test. Covered: tier selection and --list-legs; the no-tier guard, at run time and statically
(tools/_t1288-tier-guard.py); the quarantine (a red quarantined leg does not fail its tier, an entry past fix_by does);
retry-once for browser legs (FLAKY on a pass, RED on a second failure, no retry for an ordinary failure, the DevTools
port message); the history rows; core's private TMPDIR and its network namespace; the pre-push installer and gate.

    python3 tests/test_t1288_tiers.py        exit 0 all passed, 1 a check failed
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "tools", "_t1288-tiers.sh")
GUARD = os.path.join(ROOT, "tools", "_t1288-tier-guard.py")
INSTALL = os.path.join(ROOT, "tools", "_t1288-install-hook.sh")
GATE = os.path.join(ROOT, "tools", "_t1288-prepush-gate.sh")

RUNNER = r'''#!/usr/bin/env bash
set -u
ROOT="__ROOT__"
. "$ROOT/tools/_t1288-tiers.sh"
t1288_parse_args "$@"
t1288_hermetic "$0" "$@"
t1288_private_tmpdir
TMP="$(mktemp -d)"
export TMPDIR="$TMP"
pass=0
fail=0
report() { printf '  [%s] %s\n' "$1" "$2"; }
trap 'rc=$?; [ "$T1288_LIST" = 1 ] || t1288_history_rows "$rc" 0 fixsha 2026-10-24T00:00:00Z >> "$FIX_HISTORY"; t1288_cleanup; rm -rf "$TMP"' EXIT
t1288_load_quarantine
_ok()  { echo "RAN $1"; pass=$((pass + 1)); }
_bad() { echo "RAN $1"; fail=$((fail + 1)); }
_slow() { echo "RAN $1"; if timeout 1 sleep 5; then pass=$((pass + 1)); else fail=$((fail + 1)); fi; }
_flaky() {   # times out the first time, passes the second
  echo "RAN $1"
  if [ -e "$FIX_STATE/$1" ]; then pass=$((pass + 1)); else : > "$FIX_STATE/$1"; if timeout 1 sleep 5; then pass=$((pass + 1)); else fail=$((fail + 1)); fi; fi
}
_noport() {  # the browser never opened its DevTools port, the first time
  echo "RAN $1"
  if [ -e "$FIX_STATE/$1" ]; then pass=$((pass + 1)); else : > "$FIX_STATE/$1"; echo "Error: chrome did not open a DevTools port" > "$TMP/leg-$1.out"; fail=$((fail + 1)); fi
}
_env() { echo "RAN $1 TMPDIR=$TMPDIR TMP=$TMP"; pass=$((pass + 1)); }
_net() {     # a core leg reaching for the network or a browser binary
  echo "RAN $1"
  if python3 -c "import socket; s=socket.socket(); s.settimeout(3); s.connect(('192.0.2.1', 80))" 2>/dev/null; then echo "NET REACHABLE"; else echo "NET UNREACHABLE"; fi
  ip -o link 2>/dev/null | awk -F': ' '{print "IFACE " $2}'
  pass=$((pass + 1))
}
__LEGS__
[ "$T1288_LIST" = 1 ] && { [ -z "${_T1288_NOTIER:-}" ]; exit; }
t1288_finish
echo "fixture: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
'''

checks = []


def check(name, ok, detail: object = ""):
    checks.append(ok)
    print(("PASS  " if ok else "FAIL  ") + name + ("" if ok else f"\n      {detail}"))


class Fixture:
    def __init__(self, legs, quarantine=None):
        self.dir = tempfile.mkdtemp(prefix="t1288-")
        self.path = os.path.join(self.dir, "runner.sh")
        open(self.path, "w").write(RUNNER.replace("__ROOT__", ROOT).replace("__LEGS__", legs))
        self.state = os.path.join(self.dir, "state")
        os.mkdir(self.state)
        self.history = os.path.join(self.dir, "history.tsv")
        self.qf = os.path.join(self.dir, "quarantine.yaml")
        open(self.qf, "w").write(quarantine or "quarantine: []\n")
        self.st = os.path.join(self.dir, "st")

    def run(self, *args, env=None):
        e = dict(os.environ, FIX_STATE=self.state, FIX_HISTORY=self.history, T1288_QUARANTINE=self.qf,
                 T1288_TODAY="2026-10-24", T1288_ST=self.st, T1288_NO_HERMETIC="1")
        e.pop("_T1288_IN_NS", None)
        e.update(env or {})
        p = subprocess.run(["bash", self.path, *args], capture_output=True, text=True, env=e, timeout=120,
                           stdin=subprocess.DEVNULL)
        return p.returncode, p.stdout + p.stderr

    def rows(self):
        if not os.path.exists(self.history):
            return []
        return [l.split("\t") for l in open(self.history).read().splitlines() if l]

    def close(self):
        shutil.rmtree(self.dir, ignore_errors=True)


def ran(out):
    return [l.split()[1] for l in out.splitlines() if l.startswith("RAN ")]


THREE = '''leg core "a" _ok a
leg browser "b" _ok b
leg sweep "c" _ok c'''


def test_selection():
    f = Fixture(THREE)
    try:
        rc, out = f.run("--tier", "core")
        check("1 --tier core runs only the core leg", rc == 0 and ran(out) == ["a"], out)
        rc, out = f.run("--tier", "browser")
        check("2 --tier browser runs only the browser leg", rc == 0 and ran(out) == ["b"], out)
        rc, out = f.run("--tier", "sweep")
        check("3 --tier sweep runs only the sweep leg", rc == 0 and ran(out) == ["c"], out)
        rc, out = f.run()
        check("4 no --tier means all: every leg, in file order", rc == 0 and ran(out) == ["a", "b", "c"], out)
        rows_before = len(f.rows())
        rc, out = f.run("--list-legs")
        check("5 --list-legs lists '<tier> <name>' for every leg, runs none, records nothing",
              rc == 0 and ran(out) == [] and "core a" in out and "browser b" in out and "sweep c" in out
              and len(f.rows()) == rows_before, out)
        rc, out = f.run("--tier", "nonsense")
        check("6 an unknown tier is refused (exit 2) before anything runs", rc == 2 and ran(out) == [], out)
    finally:
        f.close()


def test_no_tier_runtime():
    f = Fixture('''leg core "a" _ok a
leg "b" _ok b
leg weird "c" _ok c''')
    try:
        rc, out = f.run()
        check("7 at run time a leg with no tier, or an unknown one, is a FAIL of its own and is not run",
              rc == 1 and ran(out) == ["a"] and out.count("has no tier") == 2, out)
        rc, out = f.run("--list-legs")
        check("8 --list-legs names it NO-TIER and exits non-zero", rc != 0 and "NO-TIER" in out, out)
    finally:
        f.close()


def guard(src):
    d = tempfile.mkdtemp(prefix="t1288g-")
    try:
        p = os.path.join(d, "runner.sh")
        open(p, "w").write(src)
        r = subprocess.run([sys.executable, GUARD, "--static", p], capture_output=True, text=True, timeout=60)
        return r.returncode, r.stdout
    finally:
        shutil.rmtree(d, ignore_errors=True)


def test_static_guard():
    clean = '''pass=0; fail=0
_leg_001() {
if true; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
fi
}
leg core "one" _leg_001
ARR=(
  'core|tools/x.py|why'
  'browser|tools/y.mjs|why'
)
_one() { pass=$((pass + 1)); }
for _e in "${ARR[@]}"; do
  _t="${_e%%|*}"
  leg "$_t" "e" _one "$_e"
done
'''
    rc, out = guard(clean)
    check("9 static guard: registered legs, literal tiers and tiered array entries are clean", rc == 0, out)
    rc, out = guard(clean + '''if true; then
  pass=$((pass + 1))
fi
''')
    check("10 static guard: a counted check at top level, outside any leg, fails it", rc == 1 and "top level" in out, out)
    rc, out = guard(clean.replace('leg core "one" _leg_001', 'leg "one" _leg_001 x'))
    check("11 static guard: a leg line with no tier fails it", rc == 1 and "no tier" in out, out)
    rc, out = guard(clean.replace("'browser|tools/y.mjs|why'", "'tools/y.mjs|why'"))
    check("12 static guard: an array entry with no tier field fails it", rc == 1 and "entry has no tier" in out, out)
    rc, out = guard(clean.replace('leg core "one" _leg_001', ''))
    check("13 static guard: a counting function no leg registers fails it", rc == 1 and "_leg_001" in out, out)
    rc, out = guard("pass=0\n")
    check("14 static guard: a file with no leg line at all is not evaluated (exit 2), never a pass", rc == 2, out)
    r = subprocess.run([sys.executable, GUARD, os.path.join(ROOT, "tests", "run-bridge-tests.sh")],
                       capture_output=True, text=True, timeout=180)
    check("15 the real suite passes the full guard (static + --list-legs)", r.returncode == 0, r.stdout[-600:])


def test_quarantine():
    legs = '''leg core "good" _ok good
leg core "known-red" _bad known-red'''
    f = Fixture(legs, quarantine='''quarantine:
  - leg: known-red
    reason: fixture
    owner: T-0000
    fix_by: 2026-11-01
''')
    try:
        rc, out = f.run("--tier", "core")
        check("16 a red quarantined leg runs, reports QUARANTINED and does not fail its tier",
              rc == 0 and "known-red" in ran(out) and "[QUARANTINED] known-red" in out
              and "tier core    GREEN: 1 passed, 0 failed, 0 flaky, 1 quarantined" in out, out)
        rc, out = f.run("--tier", "core", env={"T1288_TODAY": "2026-11-02"})
        check("17 a quarantine entry past its fix_by FAILS the tier", rc == 1 and "past its fix_by 2026-11-01" in out
              and "[QUARANTINED]" not in out, out)
    finally:
        f.close()
    f = Fixture(legs, quarantine='''quarantine:
  - leg: known-red
    reason: fixture
''')
    try:
        rc, out = f.run("--tier", "core")
        check("18 an entry without owner or fix_by quarantines nothing and fails the run",
              rc == 1 and "unreadable" in out and "[QUARANTINED]" not in out, out)
    finally:
        f.close()
    f = Fixture(legs, quarantine='''quarantine:
  - leg: no-such-leg
    reason: fixture
    owner: T-0000
    fix_by: 2026-11-01
''')
    try:
        rc, out = f.run("--tier", "core")
        check("19 an entry that names no leg fails the run", rc == 1 and "names no leg" in out, out)
    finally:
        f.close()


def test_retry():
    f = Fixture('''leg browser "flaky" _flaky flaky
leg browser "other" _ok other
leg browser "noport" _noport noport''')
    try:
        rc, out = f.run("--tier", "browser")
        order = ran(out)
        check("20 a browser leg that times out (rc 124) is retried once, alone, after the other legs: FLAKY",
              rc == 0 and order == ["flaky", "other", "noport", "flaky", "noport"] and "[FLAKY] flaky" in out, out)
        check("21 'did not open a DevTools port' is retried the same way", "[FLAKY] noport" in out, out)
        check("22 FLAKY is counted and listed, not hidden",
              "tier browser GREEN: 3 passed, 0 failed, 2 flaky, 0 quarantined" in out
              and "flaky: browser flaky" in out, out)
    finally:
        f.close()
    f = Fixture('''leg browser "slow" _slow slow
leg browser "plain-red" _bad plain-red''')
    try:
        rc, out = f.run("--tier", "browser")
        check("23 a leg that times out again on its retry is RED",
              rc == 1 and ran(out).count("slow") == 2 and "RED: failed again" in out, out)
        check("24 an ordinary browser failure (no timeout, no port message) is not retried",
              ran(out).count("plain-red") == 1 and "tier browser RED: 0 passed, 2 failed, 0 flaky" in out, out)
    finally:
        f.close()
    f = Fixture('leg core "slow" _slow slow')
    try:
        rc, out = f.run("--tier", "core")
        check("25 a core leg is never retried: it must not need one", rc == 1 and ran(out).count("slow") == 1, out)
    finally:
        f.close()


def test_history():
    f = Fixture(THREE + '\nleg core "red" _bad red')
    try:
        f.run()
        rows = f.rows()
        tiers = [r[6] for r in rows]
        check("26 a --tier all run appends its all-row (the T-813 six columns first) and one row per tier",
              tiers == ["all", "core", "browser", "sweep"] and rows[0][1:4] == ["3", "1", "1"]
              and rows[1][1:4] == ["1", "1", "1"] and rows[2][1:4] == ["1", "0", "0"], rows)
        f.run("--tier", "browser")
        last = f.rows()[-1]
        check("27 a single-tier run appends only its own row: date pass fail rc seconds sha tier flaky quarantined",
              len(f.rows()) == 5 and len(last) == 9 and last[6] == "browser" and last[1:4] == ["1", "0", "0"], last)
    finally:
        f.close()


def test_core_tmpdir():
    f = Fixture('leg core "env" _env env')
    try:
        rc, out = f.run("--tier", "core")
        line = next((l for l in out.splitlines() if l.startswith("RAN env")), "")
        check("28 core runs with TMPDIR inside its own .context/st/ dir, never the shared /tmp",
              rc == 0 and f"TMP={f.st}/" in line and f"TMPDIR={f.st}/" in line, out)
        check("29 core removes that dir when it is done", not os.path.exists(f.st), os.listdir(f.dir))
    finally:
        f.close()


def test_core_namespace():
    probe = subprocess.run(["unshare", "--mount", "--net", "--propagation", "private", "true"], capture_output=True)
    if probe.returncode != 0:
        probe = subprocess.run(["unshare", "--user", "--map-root-user", "--mount", "--net", "--propagation",
                                "private", "true"], capture_output=True)
    if probe.returncode != 0:
        check("30 (not measured here: unshare cannot make a namespace on this host, and the runner says so)",
              True)
        return
    f = Fixture('leg core "net" _net net')
    try:
        rc, out = f.run("--tier", "core", env={"T1288_NO_HERMETIC": ""})
        ifaces = [l.split()[1] for l in out.splitlines() if l.startswith("IFACE ")]
        check("30 core runs in a network namespace: only a loopback, and an outside address is unreachable",
              rc == 0 and "NET UNREACHABLE" in out and ifaces == ["lo"], out)
    finally:
        f.close()


def sh(cmd, cwd, env=None):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, env=dict(os.environ, **(env or {})),
                       timeout=120, stdin=subprocess.DEVNULL)
    return p.returncode, p.stdout + p.stderr


def test_installer_and_gate():
    d = tempfile.mkdtemp(prefix="t1288h-")
    try:
        sh(["git", "init", "-q"], d)
        os.makedirs(os.path.join(d, "tools"))
        os.makedirs(os.path.join(d, "tests"))
        shutil.copy(GATE, os.path.join(d, "tools"))
        hook = os.path.join(d, ".git", "hooks", "pre-push")
        framework = "#!/bin/bash\n# >>> agentic-framework hook >>>\n(\n_stdin_buf=$(cat)\n)\n"
        open(hook, "w").write(framework)
        rc, out = sh(["bash", INSTALL, "--check"], d)
        check("31 installer --check: exit 1 when the line is absent", rc == 1 and "NOT installed" in out, out)
        sh(["bash", INSTALL], d)
        sh(["bash", INSTALL], d)
        lines = open(hook).read().split("\n")
        n = sum("832-T-1288-core-tier-gate" in l for l in lines)
        check("32 installer: idempotent, one active line directly after the shebang, framework block intact",
              n == 1 and "832-T-1288-core-tier-gate" in lines[1] and "</dev/null" in lines[1]
              and "_stdin_buf=$(cat)" in open(hook).read(), lines[:3])
        rc, out = sh(["bash", INSTALL, "--check"], d)
        check("33 installer --check: exit 0 once installed", rc == 0, out)
        open(hook, "w").write(open(hook).read().replace("\nbash ", "\n# bash ", 1))
        rc, out = sh(["bash", INSTALL, "--check"], d)
        check("34 a commented-out line (an upgrade's reinstall) reads as NOT installed", rc == 1, out)
        sh(["bash", INSTALL], d)
        text = open(hook).read()
        check("35 reinstalling replaces the commented line with one active line",
              text.count("832-T-1288-core-tier-gate") == 1 and "\nbash " in text, text[:300])
        suite = os.path.join(d, "tests", "run-bridge-tests.sh")
        open(suite, "w").write('echo "tier core    RED: 1 passed, 1 failed, 0 flaky, 0 quarantined, 1 s"; '
                               'echo "  [FAIL] fixture"; exit 1\n')
        rc, out = sh(["bash", "tools/_t1288-prepush-gate.sh"], d)
        check("36 the gate blocks the push when the core tier is red, and names the leg", rc == 1 and
              "push refused" in out and "[FAIL] fixture" in out, out)
        open(suite, "w").write('[ "$*" = "--tier core" ] || exit 9; '
                               'echo "tier core    GREEN: 2 passed, 0 failed, 0 flaky, 0 quarantined, 1 s"\n')
        rc, out = sh(["bash", "tools/_t1288-prepush-gate.sh"], d)
        check("37 the gate runs --tier core and lets a green push through", rc == 0 and "GREEN" in out, out)
        open(suite, "w").write("exit 1\n")
        rc, out = sh(["bash", "tools/_t1288-prepush-gate.sh"], d, env={"T1288_PREPUSH_BYPASS": " "})
        check("38 a bypass with no reason is refused", rc == 1 and "needs its reason" in out, out)
        rc, out = sh(["bash", "tools/_t1288-prepush-gate.sh"], d, env={"T1288_PREPUSH_BYPASS": "fixture reason"})
        log = os.path.join(d, "tests", ".prepush-bypass.tsv")
        check("39 a bypass with a reason passes and is logged to tests/.prepush-bypass.tsv",
              rc == 0 and os.path.exists(log) and "fixture reason" in open(log).read(), out)
    finally:
        shutil.rmtree(d, ignore_errors=True)


if __name__ == "__main__":
    for t in (test_selection, test_no_tier_runtime, test_static_guard, test_quarantine, test_retry, test_history,
              test_core_tmpdir, test_core_namespace, test_installer_and_gate):
        t()
    print(f"T-1288 tiers: {sum(checks)} passed, {len(checks) - sum(checks)} failed")
    sys.exit(0 if all(checks) else 1)
