#!/usr/bin/env bash
# _t410-secret-artifact-teeth.sh — prove tracked-secret-artifacts.py catches the file
# that sat tracked for two months, and does not red on the tree we actually keep.
#
# Each leg names its own condition. A leg asserting only "rc != 0" banks typos as proof
# (T-338/T-343/T-348/T-399).
#
# THE SUBJECT RESOLVES ITS POPULATION FROM ITS OWN LOCATION (`git -C <parent-of-tools>
# ls-files`), so every synthetic leg COPIES the real script into a throwaway repo and
# runs it there. That is deliberate: it exercises the shipped file rather than a
# reimplementation of it, and it keeps the real .git untouched.
#
# PL-113 applies with force here. The defect this tool exists for has ALREADY been
# remediated in this repo — so a run against the live tree passes whether the tool works
# or not. Leg (a) is the only thing standing between "it works" and "the file is gone".
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJECT="${SUBJECT:-$ROOT/tools/tracked-secret-artifacts.py}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { echo "  ok  $*"; }

# mkrepo <name> — a throwaway git repo with the subject installed at tools/
mkrepo() {
  local d="$TMP/$1"
  mkdir -p "$d/tools"
  cp "$SUBJECT" "$d/tools/"
  git -C "$d" init -q 2>/dev/null
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  printf 'placeholder\n' > "$d/README.md"
  git -C "$d" add -A >/dev/null 2>&1
  echo "$d"
}

# track <repo> <relpath> [content]
track() {
  local d="$1" p="$2"
  mkdir -p "$d/$(dirname "$p")"
  printf '%s\n' "${3:-0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef}" > "$d/$p"
  git -C "$d" add -f "$p" >/dev/null 2>&1
}

run() { python3 "$1/tools/$(basename "$SUBJECT")" "${@:2}" 2>&1; }

echo "=== T-410 tracked-secret teeth (subject: ${SUBJECT#$ROOT/}) ==="

# --- CONTROL -----------------------------------------------------------------
d="$(mkrepo control)"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "CONTROL: an ordinary repo must pass, else every red below is the fixture. rc=$rc
$out"
else
  ok "CONTROL  ordinary tracked tree passes"
fi

# --- (a) THE ACTUAL FILE, AT THE ACTUAL PATH ---------------------------------
# `.context/working/.fw-secret-key`, tracked from 2b9c8ffa (2026-06-04) to T-410 while
# every audit reported "Secret scan: tracked tree clean". If this leg does not go red,
# the tool has not addressed the incident it was written for.
d="$(mkrepo actual)"
track "$d" ".context/working/.fw-secret-key"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(a) the file from the incident must be refused. rc=$rc
$out"
elif ! echo "$out" | grep -q "\.fw-secret-key"; then
  fail "(a) exited 1 without naming the file
$out"
elif ! echo "$out" | grep -q "DEFINITIVE"; then
  fail "(a) flagged, but not as DEFINITIVE — this name is key material by construction,
     not a heuristic guess, and the class is what tells the reader how much to trust it
$out"
else
  ok "(a) .context/working/.fw-secret-key refused, classed DEFINITIVE"
fi

# --- (a2) the ANNOUNCED heuristic, on its own ---------------------------------
# A differently-named key that no exact-name rule covers. This is the class the tool
# says is a floor, not a ceiling — prove the floor is actually there.
d="$(mkrepo announced)"
track "$d" "config/app_secret_key"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(a2) secrecy-word + credential-noun pairing must flag. rc=$rc
$out"
elif ! echo "$out" | grep -q "ANNOUNCED"; then
  fail "(a2) flagged under the wrong class — the heuristic must be labelled as one
$out"
else
  ok "(a2) app_secret_key flagged as ANNOUNCED (heuristic labelled honestly)"
fi

# --- (b) definitive extensions and names --------------------------------------
for f in "certs/server.pem" "deploy/id_rsa" "keys/store.p12" "home/.netrc" "svc/tls.key"; do
  d="$(mkrepo "def-$(echo "$f" | tr '/.' '__')")"
  track "$d" "$f"
  out="$(run "$d")"; rc=$?
  if [ "$rc" -ne 1 ]; then
    fail "(b) $f must be refused. rc=$rc
$out"
    b_bad=1
  fi
done
[ -z "${b_bad:-}" ] && ok "(b) .pem / id_rsa / .p12 / .netrc / .key all refused"

# --- (c) .env yes, .env.example no --------------------------------------------
d="$(mkrepo dotenv)"; track "$d" ".env"
out="$(run "$d")"; rc=$?
d2="$(mkrepo dotenvex)"; track "$d2" ".env.example"
out2="$(run "$d2")"; rc2=$?
if [ "$rc" -ne 1 ]; then
  fail "(c) a tracked .env must be refused. rc=$rc
$out"
elif [ "$rc2" -ne 0 ]; then
  fail "(c) .env.example exists TO be committed — refusing it teaches authors to
     disable the tool rather than obey it. rc=$rc2
$out2"
else
  ok "(c) .env refused, .env.example accepted"
fi

# --- (d) POPULATION DISCRIMINATION: untracked key on disk is fine -------------
# The whole claim is "tracked == published". A key sitting untracked in a working tree
# is a key doing its job. If the tool cannot tell them apart it flags every developer's
# local secrets and gets uninstalled within a day.
d="$(mkrepo untracked)"
mkdir -p "$d/.context/working"
printf 'deadbeef\n' > "$d/.context/working/.fw-secret-key"   # on disk, NOT git-added
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(d) an UNTRACKED key must not be flagged — the population is the index, not the
     working tree. rc=$rc
$out"
else
  ok "(d) untracked key on disk ignored (population = git ls-files)"
fi

# --- (d2) ...and the same file, once tracked, IS flagged ----------------------
# The reciprocal of (d): without it, (d) is equally satisfied by a tool that flags
# nothing at all.
git -C "$d" add -f .context/working/.fw-secret-key >/dev/null 2>&1
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(d2) the SAME file must flag once tracked, else (d) is satisfied by a tool that
     never flags anything. rc=$rc
$out"
else
  ok "(d2) same file flagged the moment it enters the index"
fi

# --- (e) allowlist requires a reason ------------------------------------------
d="$(mkrepo allow)"
track "$d" "certs/server.pem"
printf 'certs/server.pem\tpublic test fixture, no private half\n' > "$d/.tracked-secret-allowlist"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(e) an allowlist entry WITH a reason must excuse the file. rc=$rc
$out"
else
  ok "(e) allowlisted-with-reason -> rc=0"
fi

printf 'certs/server.pem\n' > "$d/.tracked-secret-allowlist"
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(e2) a bare-path allowlist entry must be a harness error (rc=2). An excuse
     nobody can check later is how an allowlist rots into prose. rc=$rc
$out"
elif ! echo "$out" | grep -q "no reason"; then
  fail "(e2) exited 2 but not for the stated reason
$out"
else
  ok "(e2) allowlist entry without a reason -> rc=2"
fi

# --- (f) empty population is vacuous, not clean -------------------------------
d="$TMP/empty"; mkdir -p "$d/tools"; cp "$SUBJECT" "$d/tools/"
git -C "$d" init -q 2>/dev/null
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(f) a repo tracking nothing must exit 2 — 'no tracked key material' over zero
     files reads exactly like a clean repository. rc=$rc
$out"
elif ! echo "$out" | grep -q "VACUOUS"; then
  fail "(f) exited 2 but not for the stated vacuity reason
$out"
else
  ok "(f) empty population -> rc=2 VACUOUS"
fi

# --- (g) the remedy text puts ROTATION first, and names Tier 0 ----------------
# Untracking feels like the fix and is not one: the value stays readable in history and
# in every existing clone. A remedy that leads with `git rm --cached` produces a repo
# that looks clean and a key that still signs.
d="$(mkrepo remedy)"; track "$d" ".context/working/.fw-secret-key"
out="$(run "$d")"
rot_ln=$(echo "$out" | grep -n "ROTATE" | head -1 | cut -d: -f1)
rm_ln=$(echo "$out" | grep -n "git rm --cached" | head -1 | cut -d: -f1)
if [ -z "$rot_ln" ] || [ -z "$rm_ln" ]; then
  fail "(g) the remedy must mention both rotation and untracking
$out"
elif [ "$rot_ln" -ge "$rm_ln" ]; then
  fail "(g) untracking is listed before rotation — that ordering produces a repo that
     looks clean and a key that still signs
$out"
elif ! echo "$out" | grep -q "TIER 0"; then
  fail "(g) the remedy never says the history rewrite is Tier 0 / operator-only
$out"
else
  ok "(g) remedy orders rotate-before-untrack and names Tier 0 for the rewrite"
fi

# --- FALSE-POSITIVE CONTROL: the framework's own secret-HANDLING names --------
# secret-scan.sh, secrets_store.py, .secret-scan-patterns and context_tokens.py are
# tooling ABOUT secrets. A tool that reds on them reds on the framework itself and is
# reverted rather than obeyed.
d="$(mkrepo fp)"
for f in "agents/git/lib/secret-scan.sh" "web/secrets_store.py" ".secret-scan-patterns" \
         "lib/context_tokens.py" "docs/T-1452-csrf-token-htmx-rca.md" "keys/server.pem.pub"; do
  track "$d" "$f"
done
out="$(run "$d")"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "FP: secret-HANDLING tooling must not be mistaken for secret MATERIAL. rc=$rc
$out"
else
  ok "FP   secret-scan.sh / secrets_store.py / *_tokens.py / .pub not flagged"
fi

# --- RECIPROCAL CONTROL: the live tree passes ---------------------------------
# Every leg above proves the tool CAN refuse. Only this proves it does not refuse the
# 5562-file tree we actually keep.
out="$(python3 "$SUBJECT" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "RECIPROC: the live tree must pass after the T-410 fix. rc=$rc
$out"
elif ! echo "$out" | grep -qE "scan ok: [0-9]{4,} tracked file"; then
  fail "RECIPROC: passed, but not over a four-digit population — a pass over a
     truncated read would look identical
$out"
else
  ok "RECIPROC live tree passes over its full population"
fi

echo
if [ "$fails" -ne 0 ]; then
  echo "TEETH FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "TEETH PASS — 13/13 legs (control + 11 cases + reciprocal on the live tree)"
