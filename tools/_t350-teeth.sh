#!/usr/bin/env bash
# _t350-teeth.sh — prove each check in _t350-build-only-probe.sh CAN fail, and fails for
# its OWN stated reason. A leg that accepts any non-zero exit banks syntax errors as
# evidence (T-338 leg (d), T-343 leg (d), T-348 leg (c) — three times on this arc), so
# every leg here requires a SPECIFIC substring from the probe's output.
#
# Mutated copies must live in tools/ — serve-gallery.sh resolves ROOT from $0's dir.
#
# ── WHY THIS FILE HAS A SAFETY PRECONDITION ───────────────────────────────────────────
# The first version of leg (d) removed the guard that stops a recursive delete of a
# caller-supplied path, and stubbed the delete itself so the missing guard would be
# observable without being dangerous. The stub used a replace-first-occurrence, and the
# first occurrence was inside a COMMENT that quoted the command. The comment was stubbed;
# the live command survived; the probe then ran that mutant with GALLERY_DIR=$ROOT and
# DELETED THIS REPOSITORY (recovered from origin at 041765c, ~0 committed work lost).
#
# The lesson is not "that replace was careless". It is that a safety measure which is
# never verified to have applied is not a safety measure. So the mutant is checked before it runs:
# assert_safe() must hold — guard intact OR delete stubbed — or the leg aborts unrun.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROBE="$ROOT/tools/_t350-build-only-probe.sh"
SRC="$ROOT/tools/serve-gallery.sh"
pass=0; fail=0

cleanup() {
  rm -f "$ROOT"/tools/.t350-mut-*.sh
  pkill -f t350listener 2>/dev/null || true   # stand-in listeners from removed leg (f)
}
trap cleanup EXIT
cleanup

# The invariant every mutant must satisfy before it is allowed to run:
#   the refusal guard is INTACT, or the recursive delete is STUBBED.
# Either alone is sufficient; neither is what destroyed the repo. Stating it as a
# disjunction matters — a blanket "no live delete" rule would abort legs (a)/(b)/(c),
# which legitimately keep the delete because they also keep the guard that stops it.
# Comment lines are excluded from the delete scan deliberately: a quoted command in
# prose is exactly what fooled the first version, so prose must be able to neither
# satisfy nor trip this check.
assert_safe() {
  local f="$1" live guard
  guard="$(grep -c 'refusing to recursively delete' "$f")"
  live="$(grep -nE '^[[:space:]]*rm[[:space:]]+-[a-zA-Z]*r' "$f" | grep -v '^[0-9]*:[[:space:]]*#')"
  # -F is deliberate (T-460), and NOT a bug fix — the plain `grep -q` here was correct.
  # GNU grep reads the unescaped `$` in `${OUT%/}` as a literal (documented behaviour), so
  # this matched fine and the `guard intact` branch was always reachable. ugrep 7.5.0 anchors
  # on it and returns 0 on the same file. `-F` is the right flag for a wholly literal pattern
  # and makes this check give the same answer under both implementations — a property worth
  # having on purpose, since the harness may be read by an agent whose shell routes `grep`
  # through a shim (see T-460: that divergence is what briefly made this look dead).
  if [ "$guard" -ge 1 ] && grep -qF 'case "${OUT%/}" in' "$f"; then
    return 0                      # guard intact — the dangerous inputs are refused
  fi
  if [ -z "$live" ]; then
    return 0                      # delete stubbed — nothing to authorise
  fi
  echo "  SAFETY PRECONDITION FAILED — guard removed AND a live recursive delete remains:" >&2
  echo "$live" | sed 's/^/    /' >&2
  return 1
}

leg() { # $1=id  $2=description  $3=expected substring  $4=mutation fn  $5=needs_safety_check(0|1)
  local id="$1" desc="$2" want="$3" mutfn="$4" defang="${5:-0}"
  local mut="$ROOT/tools/.t350-mut-$id.sh"
  cp "$SRC" "$mut"; chmod +x "$mut"
  if ! "$mutfn" "$mut"; then
    echo "LEG $id: BROKEN — mutation did not apply (anchor missing); a red here would prove nothing" >&2
    fail=$((fail+1)); return
  fi
  if ! bash -n "$mut" 2>/dev/null; then
    echo "LEG $id: BROKEN — mutated copy does not parse; a red here would prove nothing" >&2
    fail=$((fail+1)); return
  fi
  if [ "$defang" = 1 ] && ! assert_safe "$mut"; then
    echo "LEG $id: ABORTED — refusing to execute an armed mutant (this is the check that was missing when T-350's teeth deleted the repo)" >&2
    fail=$((fail+1)); return
  fi
  # A mutant that falls through to the serve path starts servers the probe never
  # planned for, and `timeout` kills the wrapper while the python child survives (the
  # SIGINT-ignored orphaning of T-351). Reap anything this leg started, by PID delta —
  # otherwise the harness that exists to catch defects becomes a source of the litter
  # already sitting on this host from July.
  local before_pids after_pids out rc
  before_pids="$(pgrep -f 'gallery-serve\.py' 2>/dev/null | sort -u | tr '\n' ' ')"
  out="$(SERVE_GALLERY="$mut" bash "$PROBE" 2>&1)"; rc=$?
  after_pids="$(pgrep -f 'gallery-serve\.py' 2>/dev/null | sort -u | tr '\n' ' ')"
  for pid in $after_pids; do
    case " $before_pids " in *" $pid "*) ;; *) kill -TERM "$pid" 2>/dev/null || true ;; esac
  done
  if [ "$rc" -eq 0 ]; then
    echo "LEG $id: FAILED TO GO RED — probe still passed with the mutation applied ($desc)" >&2
    fail=$((fail+1)); return
  fi
  if ! echo "$out" | grep -qF "$want"; then
    echo "LEG $id: RED FOR THE WRONG REASON — probe failed but never said: $want" >&2
    echo "$out" | grep '^FAIL' | sed 's/^/    /' >&2
    fail=$((fail+1)); return
  fi
  echo "LEG $id: ok — red, naming its own condition ($desc)"
  echo "         -> $(echo "$out" | grep -F "$want" | head -1 | cut -c1-140)"
  pass=$((pass+1))
}

# (a) build-only never takes the early exit → falls through and starts a server.
#     Defanged too: with build-only broken the probe reaches the serve path, which is
#     harmless, but the mutant is still a delete-capable script and the rule is uniform.
mut_a() {
  python3 - "$1" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = 'if [ "$BUILD_ONLY" = 1 ]; then'
if old not in s: sys.exit(1)
open(p, 'w').write(s.replace(old, 'if [ "$BUILD_ONLY" = 99 ]; then', 1))
PY
}

# (b) build copies only the FIRST corpus map — the root assembles, but is incomplete.
#     Chosen over "delete the copy line" because that dies at `ls` under set -e, which
#     would fail AC1 on rc and never reach the AC2 completeness message being tested.
mut_b() {
  python3 - "$1" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = 'cp "$ROOT"/examples/aef-processes/rendered/*.bpmn "$OUT/rendered/"'
old2 = '''for f in "$ROOT"/examples/app-processes/rendered/*.bpmn; do
  [ -e "$f" ] && cp "$f" "$OUT/rendered/"
done'''
if old not in s or old2 not in s: sys.exit(1)
s = s.replace(old, 'for f in "$ROOT"/examples/aef-processes/rendered/*.bpmn; do cp "$f" "$OUT/rendered/"; break; done', 1)
s = s.replace(old2, ':', 1)
open(p, 'w').write(s)
PY
}

# (c) remove the unknown-option arm → a mistyped flag lands in the PORT slot.
mut_c() {
  python3 - "$1" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
try:
    start = s.index('    -*)'); end = s.index('    *)', start)
except ValueError: sys.exit(1)
if 'unknown option' not in s[start:end]: sys.exit(1)
open(p, 'w').write(s[:start] + s[end:])
PY
}

# (d) remove the GALLERY_DIR guard. The probe will then feed the unguarded script
#     GALLERY_DIR=$ROOT, so the delete MUST be stubbed — and assert_safe() verifies
#     the stub landed before a single line of it runs. Both edits are anchored on exact
#     strings and the mutation reports failure if either anchor is missing, so a silent
#     no-op (the original defect) surfaces as LEG BROKEN rather than as a live delete.
mut_d() {
  python3 - "$1" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p).read()
try:
    start = s.index('case "${OUT%/}" in'); end = s.index('esac', start) + 4
except ValueError: sys.exit(1)
if 'refusing' not in s[start:end]: sys.exit(1)
s = s[:start] + ': # guard removed by teeth leg (d)' + s[end:]
# Target the executable line specifically — anchored at start-of-line, not anywhere in
# the file. A comment mentioning the command cannot match this, which is the whole point.
s2, n = re.subn(r'(?m)^rm -rf "\$OUT"$', 'echo "WOULD-DELETE $OUT" >&2; exit 0', s)
if n != 1: sys.exit(1)
open(p, 'w').write(s2)
PY
}

# LEG (f) WAS WRITTEN AND REMOVED, WHICH IS ITSELF THE RESULT. It mutated build-only to
# bind the port and return cleanly, so that AC1's listener-delta check would be the only
# thing left to object. It never went red. Isolated: nothing a script backgrounds survives
# its exit under this invocation (inner shell sees the listener, outer sees none;
# `timeout --foreground` identical). The check could therefore never fire, so the CHECK was
# removed from the probe rather than the leg quietly dropped from here.

echo "== T-350 teeth =="
# The expected substrings below were CORRECTED after the first run: (a) was written as
# "build-only bound a port" and (c) as "was ACCEPTED", both predicted from the plan rather
# than read off what the check emits. Both legs went red for their own correct reason and
# the harness reported RED FOR THE WRONG REASON — which is the harness working. Recorded
# rather than quietly fixed: expected-value drift is the same defect as an AC ticked from
# the memory of the intention.
leg a "build-only falls through to the serve path" \
      "it started a server instead of stopping after the build" mut_a 1
leg b "build copies only one corpus map" \
      "the build is partial" mut_b 1
# (c) exits 124, not 0: with the option arm gone the token becomes the PORT, the bind
# fails and the run hangs until the timeout. So the discriminating clause is the
# "does not say 'unknown option'" branch — a refusal that never happened — not "ACCEPTED".
leg c "unknown-option arm removed" \
      "does not say 'unknown option'" mut_c 1
leg d "GALLERY_DIR guard removed (delete stubbed AND verified stubbed)" \
      "was ACCEPTED (exit 0) — the script would recursively delete that path" mut_d 1

# (e) the precondition itself must have teeth: an ARMED mutant must be refused, not run.
#     Without this leg, assert_safe() could be broken (or accidentally vacuous) and
#     every other leg would still pass — the safety check would be exactly the kind of
#     unverified measure that caused the incident.
echo "[leg e] the safety precondition refuses an armed mutant"
armed="$ROOT/tools/.t350-mut-e.sh"
cp "$SRC" "$armed"
python3 - "$armed" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
start = s.index('case "${OUT%/}" in'); end = s.index('esac', start) + 4
open(p, 'w').write(s[:start] + ': # guard removed, delete left ARMED' + s[end:])
PY
if assert_safe "$armed" 2>/dev/null; then
  echo "LEG e: FAILED — assert_safe() passed a mutant that still deletes; the precondition is vacuous" >&2
  fail=$((fail+1))
else
  echo "LEG e: ok — armed mutant refused before execution"
  pass=$((pass+1))
fi
rm -f "$armed"

echo
echo "teeth: $pass passed, $fail failed"

# T-429 abstention guard — a suite that recorded no legs must not report success.
if [ $(( ${pass:-0} + ${fail:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi

[ "$fail" -eq 0 ] || exit 1
