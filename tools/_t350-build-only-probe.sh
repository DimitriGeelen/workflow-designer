#!/usr/bin/env bash
# _t350-build-only-probe.sh — verify serve-gallery.sh's --build-only path (T-350, G-015 leg 2).
#
# Checks AC1..AC5 of T-350. Every failure message NAMES its own condition: a leg that
# reports only "rc != 0" banks syntax errors and typos as proof that the property holds
# (T-338 leg (d), T-343 leg (d), T-348 leg (c) — three times on this arc).
#
# The subject under test is overridable via $SERVE_GALLERY so the teeth harness can point
# this probe at a MUTATED copy and require each check to go red for its own stated reason.
# The mutated copy must live in tools/ — serve-gallery.sh resolves ROOT from $0's directory.
#
# Never touches the real build/gallery: rebuilding the live serve root as a side effect of
# a test would flip all 75 G-015 verification lines green in passing, manufacturing the
# "closed because we rebuilt it" reading the gap explicitly rejects.
set -uo pipefail   # deliberately NOT -e: run every check, report all failures

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SG="${SERVE_GALLERY:-$ROOT/tools/serve-gallery.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { echo "  ok  $*"; }

# Space-separated PIDs listening on TCP $1. Always exits 0.
listeners_on_port() {
  { ss -ltnpH "sport = :$1" 2>/dev/null \
      | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u | tr '\n' ' '; } || true
}

# A port nothing is listening on right now. Never a literal — a hard-coded port is the
# second carrier of the very subject error G-015 records (11 such lines in this tree).
free_port() {
  python3 - <<'PY'
import socket
s = socket.socket(); s.bind(('127.0.0.1', 0))
print(s.getsockname()[1]); s.close()
PY
}

corpus_count() {
  local n=0 f
  for f in "$ROOT"/examples/aef-processes/rendered/*.bpmn "$ROOT"/examples/app-processes/rendered/*.bpmn; do
    [ -e "$f" ] && n=$((n + 1))
  done
  echo "$n"
}

echo "== T-350 build-only probe =="
echo "subject: $SG"

# ── AC1: --build-only binds no port ───────────────────────────────────────────────────
echo "[AC1] --build-only binds no port"
P="$(free_port)"
before="$(listeners_on_port "$P")"

# Every invocation is bounded. A build-only run that falls through to the serve path
# BLOCKS on `wait "$SRV"` forever, so an unbounded call hangs the probe instead of
# reporting — and a check that hangs never returns a verdict at all, which in a P-011
# gate stalls completion rather than failing it. rc 124 is named as its own condition.
run_build_only() {  # $@ = args; sets rc/out; each run gets a fresh GALLERY_DIR
  local dir="$1"; shift
  out="$(GALLERY_DIR="$dir" timeout 45 "$SG" "$@" 2>&1)"; rc=$?
}

run_build_only "$TMP/g1" --build-only "$P"
rc1=$rc; out1="$out"
if [ "$rc1" -eq 124 ]; then
  fail "AC1: '--build-only $P' DID NOT RETURN within the timeout — a build-only run that blocks is a serve run; it fell through to 'wait \$SRV'"
elif [ "$rc1" -ne 0 ]; then
  fail "AC1: '--build-only $P' exited $rc1, expected 0. Output tail: $(echo "$out1" | tail -3 | tr '\n' '|')"
fi
if echo "$out1" | grep -q 'LIVE on :'; then
  fail "AC1: '--build-only' printed a 'LIVE on :' line — it started a server instead of stopping after the build"
fi
# NO LISTENER-DELTA CHECK HERE, AND THAT IS A MEASUREMENT, NOT AN OVERSIGHT.
# A before/after comparison of the listener set can only catch a server that OUTLIVES the
# run. Nothing this script backgrounds does: with the build-only exit disabled so it falls
# through and starts a real server, the listener is gone by the time the caller looks —
# reproduced in isolation (inner shell sees 1 listener, outer sees 0), and unchanged by
# `timeout --foreground`. So such a check would report "unchanged" for a subject that had
# just started a server, i.e. it would be green by construction. It was written, it never
# fired under mutation, and it was removed rather than left to look like evidence.
# What DOES discriminate, and is proven red by teeth leg (a): the `LIVE on :` line above,
# and the non-return timeout. Both name their own condition.
[ "$fails" -eq 0 ] && ok "exit 0, no LIVE line (see note: listener-delta cannot fire here)"

# order-independence and the no-port form
for variant in "port-first" "flag-only"; do
  case "$variant" in
    port-first) run_build_only "$TMP/g-$variant" "$P" --build-only ;;
    flag-only)  run_build_only "$TMP/g-$variant" --build-only ;;
  esac
  if [ "$rc" -eq 124 ]; then
    fail "AC1: argument form '$variant' DID NOT RETURN within the timeout — it fell through to the serve path"
  elif [ "$rc" -ne 0 ]; then
    fail "AC1: argument form '$variant' exited $rc, expected 0 — the flag is not position-independent. Output tail: $(echo "$out" | tail -3 | tr '\n' '|')"
  elif echo "$out" | grep -q 'LIVE on :'; then
    fail "AC1: argument form '$variant' started a server ('LIVE on :' present)"
  else
    ok "argument form '$variant' accepted, no server started"
  fi
done

# ── AC2: the assembled root is COMPLETE, not designer-only ────────────────────────────
echo "[AC2] assembled root is complete"
G="$TMP/g1"
if ! cmp -s "$ROOT/src/aef-workflow-designer.html" "$G/designer.html"; then
  fail "AC2: $G/designer.html is not byte-identical to src/aef-workflow-designer.html"
else
  ok "designer.html byte-identical to src"
fi

want="$(corpus_count)"
got=0; for f in "$G"/rendered/*.bpmn; do [ -e "$f" ] && got=$((got + 1)); done
if [ "$want" -eq 0 ]; then
  fail "AC2: the corpus itself is EMPTY (0 .bpmn under examples/*/rendered) — this comparison would pass over nothing and prove nothing"
elif [ "$got" -ne "$want" ]; then
  fail "AC2: the assembled root carries $got rendered maps but the corpus has $want — the build is partial (this is the 'designer.html only' false green G-015 names)"
else
  ok "rendered/ carries all $got corpus maps"
fi

missing=""
for f in "$G"/rendered/*.bpmn; do
  [ -e "$f" ] || continue
  b="$(basename "$f" .bpmn)"
  grep -q "designer.html?load=rendered/$b.bpmn" "$G/index.html" 2>/dev/null || missing="$missing $b"
done
if [ -n "$missing" ]; then
  fail "AC2: index.html has no link for these rendered maps:$missing — the index is stale relative to the maps beside it"
else
  ok "index.html links every rendered map"
fi

# ── AC3: the serve path still works ───────────────────────────────────────────────────
echo "[AC3] serve path unchanged"
Q="$(free_port)"
serve_log="$TMP/serve.log"
( GALLERY_DIR="$TMP/g-serve" "$SG" "$Q" >"$serve_log" 2>&1 ) &
serve_pid=$!
live=0
for _ in $(seq 1 150); do
  grep -q "LIVE on :$Q" "$serve_log" 2>/dev/null && { live=1; break; }
  kill -0 "$serve_pid" 2>/dev/null || break
  sleep 0.1
done
if [ "$live" -ne 1 ]; then
  fail "AC3: serve mode on :$Q never reported 'LIVE on :$Q' (the T-231 behaviour probe did not pass). Log tail: $(tail -3 "$serve_log" 2>/dev/null | tr '\n' '|')"
elif ! curl -sf "http://127.0.0.1:$Q/api/health" >/dev/null 2>&1; then
  fail "AC3: serve mode reported LIVE on :$Q but /api/health does not answer — the report outran the process"
else
  ok "serve mode binds :$Q and answers /api/health"
fi
# Stop the server this probe started, and ASSERT it stopped. An earlier revision sent
# SIGINT and leaked a python process per run — invisibly, because nothing checked.
# SIGINT does not work here and cannot: bash sets SIGINT to SIG_IGN for `&` children when
# job control is off, python inherits the ignore across exec, and /proc/PID/status
# confirms it in SigIgn. SIGTERM is what stops it. (serve-gallery.sh's own trap forwards
# INT only and its comment asserts the inverse of both facts — filed as T-351, out of
# scope here; this probe must clean up after ITSELF regardless of that bug.)
kill -TERM "$serve_pid" 2>/dev/null || true
for _ in $(seq 1 50); do
  [ -z "$(listeners_on_port "$Q" | tr -d ' ')" ] && break
  for pid in $(listeners_on_port "$Q"); do kill -TERM "$pid" 2>/dev/null || true; done
  sleep 0.1
done
wait "$serve_pid" 2>/dev/null || true
leaked="$(listeners_on_port "$Q")"
if [ -n "${leaked// /}" ]; then
  fail "AC3: the server this probe started on :$Q is STILL LISTENING after SIGTERM (pid(s): ${leaked% }) — the probe leaks a server process per run"
else
  ok "server on :$Q stopped and port released"
fi

# ── AC4: unknown option refused, not swallowed as a port ──────────────────────────────
echo "[AC4] unknown option refused"
out="$(GALLERY_DIR="$TMP/g-opt" timeout 45 "$SG" --build-onlyy 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then
  fail "AC4: '--build-onlyy' was ACCEPTED (exit 0) — a mistyped flag is being swallowed into the PORT slot"
elif ! echo "$out" | grep -q 'unknown option'; then
  # Requiring BOTH "unknown option" and the token matters: with the guard removed the
  # mistyped flag lands in the PORT slot and the resulting bind failure often echoes the
  # token back, so a check that only looked for the token would pass over the broken form.
  fail "AC4: '--build-onlyy' exited $rc but the message does not say 'unknown option' — this may be a downstream bind failure with the bad token echoed back, not a refusal. Output: $(echo "$out" | tail -3 | tr '\n' '|')"
elif ! echo "$out" | grep -q -- '--build-onlyy'; then
  fail "AC4: '--build-onlyy' was rejected (exit $rc) but the message never names the offending option. Output: $(echo "$out" | tail -3 | tr '\n' '|')"
else
  ok "'--build-onlyy' refused (exit $rc) with the option named"
fi

# ── AC5: the recursive-delete guard on GALLERY_DIR ────────────────────────────────────
echo "[AC5] recursive-delete guard on GALLERY_DIR"

# GALLERY_DIR="" is NOT in the executed population, and saying so is the point.
# `OUT="${GALLERY_DIR:-...}"` substitutes the default on empty as well as unset, so the
# guard's "" arm is unreachable by construction — an impossible witness, not a missing
# one. Asserting it by RUNNING the script proves nothing about the guard and, worse,
# builds into the real build/gallery, silently greening all 75 G-015 gates. Assert the
# mechanism that makes it unreachable instead; if someone changes `:-` to `-`, this goes
# red and the "" arm becomes live and testable.
if ! grep -q 'OUT="\${GALLERY_DIR:-' "$SG"; then
  fail "AC5: serve-gallery.sh no longer defaults GALLERY_DIR with ':-' — an EMPTY GALLERY_DIR may now reach the recursive delete, which this probe does not cover. Add it to the executed cases below."
else
  ok "empty GALLERY_DIR is neutralised upstream by \${GALLERY_DIR:-...} (guard arm unreachable by construction, not tested by execution)"
fi

# The two REACHABLE dangerous values. Feeding these to a subject whose guard is absent
# destroys this repository — T-350's first teeth run did exactly that. The teeth harness
# is therefore required to defang its mutants before running them (it asserts no live
# recursive delete remains); this probe additionally re-checks the canary after each case
# so damage is REPORTED rather than discovered later.
canary="$ROOT/src/aef-workflow-designer.html"
for bad in "/" "$ROOT"; do
  out="$(GALLERY_DIR="$bad" timeout 45 "$SG" --build-only 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    fail "AC5: GALLERY_DIR='$bad' was ACCEPTED (exit 0) — the script would recursively delete that path"
  elif ! echo "$out" | grep -qi 'refus'; then
    fail "AC5: GALLERY_DIR='$bad' exited $rc but the message does not say it REFUSED (so the non-zero could be any other failure). Output: $(echo "$out" | tail -3 | tr '\n' '|')"
  else
    ok "GALLERY_DIR='$bad' refused (exit $rc)"
  fi
  [ -f "$canary" ] || { fail "AC5: the repo tree was DAMAGED by GALLERY_DIR='$bad' — $canary is gone"; break; }
done

echo
if [ "$fails" -ne 0 ]; then
  echo "T-350 probe: $fails FAILURE(S)" >&2
  exit 1
fi
echo "T-350 probe: all checks passed"
