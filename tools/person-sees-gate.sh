#!/usr/bin/env bash
# person-sees-gate.sh — T-1287: ONE gate over what a person sees, run before any official UI review.
# Calls the existing render harnesses (it copies none of them), one browser at a time, at nice 19, each under a
# timeout, over every corpus map at 1024/1440/1920 in the lens-shot opening state (the harnesses' own legs):
#   label-clearance  tools/_t1256-label-clearance-cdp.mjs  flow/arrowhead crossings, label overlaps, 1024 readable
#   name-fit         tools/_t1276-name-fit-cdp.mjs         no ellipsized task name, min name size, flow-label contrast
#   sweep            tools/_t1278-sweep-cdp.mjs            min text size at opening, Name field, reachability, contrast
#   note-box         tools/_t1274-note-box-cdp.mjs         the Note box grows to its text, then scrolls
#   toolbar-reach    tools/_t1176-toolbar-reach-cdp.mjs    every header control inside the window and clickable
#   project-browser  tools/_t1282-browse-entry-cdp.mjs     the card browser: last card reachable, hover preview inside
#                                                          the window (case 6), and the ?browse=1 entry (cases 1-5)
# Prints one line per check, "PASS|FAIL|NOT RUN <check>: <counts>", then the total time.
# Exit 0 = every check PASS; 1 = a check FAILED; 2 = a check could not run (missing input, timeout, exception;
# 2 wins over 1: a check not run means the verdict is incomplete). Never a silent pass.
# Usage: tools/person-sees-gate.sh [--src FILE] [--only a,b]   (--src: another designer file, e.g. an old release;
#        passed to every harness through its own override variable). PERSON_SEES_TIMEOUT=<s> per check (default 900).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="" ONLY="" TMO="${PERSON_SEES_TIMEOUT:-900}"
while [ $# -gt 0 ]; do
  case "$1" in
    --src) SRC="$(realpath "$2")"; shift 2 ;;
    --only) ONLY=",$2,"; shift 2 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "person-sees-gate: unknown argument $1" >&2; exit 2 ;;
  esac
done
if [ -n "$SRC" ] && [ ! -f "$SRC" ]; then echo "person-sees-gate: --src $SRC: no such file" >&2; exit 2; fi
OUT="$(mktemp -d "${TMPDIR:-/tmp}/person-sees-XXXXXX")"; trap 'rm -rf "$OUT"' EXIT

# name|harness|source override variable
CHECKS=(
  'label-clearance|tools/_t1256-label-clearance-cdp.mjs|T1256_SRC'
  'name-fit|tools/_t1276-name-fit-cdp.mjs|T1276_SRC'
  'sweep|tools/_t1278-sweep-cdp.mjs|T1278_SRC'
  'note-box|tools/_t1274-note-box-cdp.mjs|T1274_SRC'
  'toolbar-reach|tools/_t1176-toolbar-reach-cdp.mjs|T1176_DESIGNER'
  'project-browser|tools/_t1282-browse-entry-cdp.mjs|T1282_SRC'
)
# One summary line from a harness's JSON report: verdict and counts (errors per leg, or steps passed).
summarise() {
  python3 - "$1" "$2" "$3" <<'PY'
import json, re, sys
name, rc, path = sys.argv[1], int(sys.argv[2]), sys.argv[3]
txt = open(path, errors='replace').read()
i = txt.find('{')
try: r = json.loads(txt[i:]) if i >= 0 else None
except ValueError: r = None
if rc == 124: print(f"NOT RUN {name}: timed out"); sys.exit(2)
if r is None: print(f"NOT RUN {name}: no JSON report (exit {rc})"); sys.exit(2)
if 'steps' in r or 'pass' in r:                         # _t1176 shape
    steps = r.get('steps', []); bad = [s['step'] for s in steps if not s['pass']]
    if r.get('error') or rc == 2: print(f"NOT RUN {name}: {str(r.get('error', 'exit 2')).splitlines()[0][:160]}"); sys.exit(2)
    ok = rc == 0 and r.get('pass') and not bad
    print(f"{'PASS' if ok else 'FAIL'} {name}: {len(steps) - len(bad)}/{len(steps)} steps" + ('' if ok else ' — ' + '; '.join(bad)[:300]))
    sys.exit(0 if ok else 1)
errs = r.get('errs', [])
if r.get('error') or rc == 2: print(f"NOT RUN {name}: {r.get('error', 'exit 2')}"); sys.exit(2)
exc = [e for e in errs if e.startswith('exception')]
if exc: print(f"NOT RUN {name}: {exc[0].splitlines()[0][:160]}"); sys.exit(2)
if rc == 0 and r.get('ok') and not errs: print(f"PASS {name}: 0 errors"); sys.exit(0)
legs = {}
for e in errs: legs.setdefault((re.match(r'(leg\w+|[a-z][\w ]{0,15}?):', e) or [None, 'other'])[1], []).append(e)
print(f"FAIL {name}: {len(errs)} errors (" + ', '.join(f"{k} {len(v)}" for k, v in sorted(legs.items())) + ")")
for k, v in sorted(legs.items()):
    for e in v[:3]: print(f"    {e[:220]}")
    if len(v) > 3: print(f"    … {len(v) - 3} more {k}")
sys.exit(1)
PY
}

T0=$(date +%s); worst=0
for c in "${CHECKS[@]}"; do
  IFS='|' read -r name harness var <<< "$c"
  case "$ONLY" in ''|*",$name,"*) ;; *) continue ;; esac
  t=$(date +%s)
  if [ -n "$SRC" ]; then env "$var=$SRC" timeout "$TMO" nice -n 19 node "$ROOT/$harness" > "$OUT/$name.out" 2>&1; rc=$?
  else timeout "$TMO" nice -n 19 node "$ROOT/$harness" > "$OUT/$name.out" 2>&1; rc=$?; fi
  line=$(summarise "$name" "$rc" "$OUT/$name.out"); v=$?
  printf '%s  [%ss]\n' "$(head -1 <<< "$line")" "$(( $(date +%s) - t ))"; tail -n +2 <<< "$line"
  if [ "$v" -eq 2 ]; then worst=2; elif [ "$v" -eq 1 ] && [ "$worst" -eq 0 ]; then worst=1; fi
done
echo "person-sees-gate: ${SRC:-src/aef-workflow-designer.html}: total $(( $(date +%s) - T0 ))s, exit $worst"
exit "$worst"
