#!/usr/bin/env bash
# _t400-schema-teeth.sh — prove concerns-schema.py refuses what G-027 slipped through.
#
# Each leg names its own condition; a leg asserting only "rc != 0" banks typos as proof
# (T-338/T-343/T-348, and T-399 where the harness caught a defect in my own fix).
# Runs against synthetic registers in $TMP — never the real .context/project/concerns.yaml.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUBJECT="${SUBJECT:-$ROOT/tools/concerns-schema.py}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok()   { echo "  ok  $*"; }

reg() { # reg <file> <extra-yaml-lines-for-entry>
  cat > "$TMP/$1" <<EOF
concerns:
  - id: G-900
    type: gap
    status: watching
    severity: medium
    title: "synthetic"
    decision_trigger: "something measurable"
$2
EOF
}

run() { python3 "$SUBJECT" --register "$TMP/$1" 2>&1; }

echo "=== T-400 schema teeth (subject: ${SUBJECT#$ROOT/}) ==="

# --- CONTROL: a well-formed entry passes -------------------------------------
reg control.yaml '    origin_task: T-999'
out="$(run control.yaml)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "CONTROL: a well-formed entry must pass, else every red below is the fixture. rc=$rc
$out"
else
  ok "CONTROL  well-formed entry passes"
fi

# --- (a) THE ACTUAL G-027 FIELD ----------------------------------------------
# closure_condition does NOT contain the substring "trigger", so the audit's alternate-key
# heuristic would still report this entry as MISSING a closure condition it visibly has.
# This is the specific miss that motivated the task.
reg g027.yaml '    closure_condition: "the exact field name G-027 used"'
out="$(run g027.yaml)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(a) closure_condition must be refused — it is the field name that caused G-027. rc=$rc
$out"
elif ! echo "$out" | grep -q "closure_condition"; then
  fail "(a) exited 1 but never named closure_condition
$out"
else
  ok "(a) closure_condition refused by name (the audit's 'trigger' heuristic misses it)"
fi

# --- (b) an arbitrary plausible-but-unread name ------------------------------
reg plausible.yaml '    remediation_plan: "reads well, read by nothing"'
out="$(run plausible.yaml)"; rc=$?
if [ "$rc" -ne 1 ]; then
  fail "(b) an unaccounted field name must exit 1, got rc=$rc
$out"
elif ! echo "$out" | grep -q "remediation_plan"; then
  fail "(b) exited 1 but did not name the offending field
$out"
else
  ok "(b) arbitrary unaccounted field -> rc=1, names the field"
fi

# --- (c) the failure message must point at the remedy, not just the fault ----
# G-027's whole cost was a detector whose text misdirected the reader.
out="$(run g027.yaml)"
if ! echo "$out" | grep -q "rename it to the field the code actually reads"; then
  fail "(c) the failure names the fault but not the fix — the G-027 cost was a message
     that sent the reader to rewrite prose that was already correct
$out"
elif ! echo "$out" | grep -q "decision_trigger"; then
  fail "(c) the remedy text never names decision_trigger, the field that IS read
$out"
else
  ok "(c) failure text names the remedy and the field that is actually read"
fi

# --- (d) prose fields are accepted -------------------------------------------
# Narrowing must not become "only load-bearing fields allowed" — the register is for
# humans too, and refusing prose would push authors to overload read fields.
reg prose.yaml '    detail: "long form"
    related: [T-1, T-2]
    evidence: "measured"'
out="$(run prose.yaml)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(d) documented prose fields must be accepted, got rc=$rc
$out"
else
  ok "(d) documented prose fields accepted -> rc=0"
fi

# --- (e) dated evidence keys are accepted ------------------------------------
reg dated.yaml '    evidence_2026_08_02_T339: "append-only measurement"'
out="$(run dated.yaml)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(e) the append-only dated-evidence convention must be accepted, got rc=$rc
$out"
else
  ok "(e) evidence_YYYY_MM_DD_Txxx accepted -> rc=0"
fi

# --- (f) read-but-absent is a NOTE, never a failure --------------------------
out="$(run control.yaml)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "(f) read-but-absent must not fail the check, got rc=$rc"
elif ! echo "$out" | grep -q "read by code but carried by no entry"; then
  fail "(f) the inert-machinery note is missing — nothing would report that
     closure_check_command/created/last_reviewed have no users
$out"
else
  ok "(f) read-but-absent reported as a NOTE at rc=0, not a failure"
fi

# --- (g) empty register ------------------------------------------------------
printf 'concerns: []\n' > "$TMP/empty.yaml"
out="$(run empty.yaml)"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(g) an empty register must exit 2 — 'every field accounted for' over zero
     entries reads exactly like a clean register. rc=$rc
$out"
elif ! echo "$out" | grep -q "VACUOUS"; then
  fail "(g) exited 2 but not for the stated vacuity reason
$out"
else
  ok "(g) empty register -> rc=2 VACUOUS"
fi

# --- (h) unparseable register ------------------------------------------------
printf 'concerns:\n  - id: G-1\n   bad indent\n' > "$TMP/broken.yaml"
out="$(run broken.yaml)"; rc=$?
if [ "$rc" -ne 2 ]; then
  fail "(h) an unparseable register must exit 2, got rc=$rc
$out"
else
  ok "(h) unparseable register -> rc=2"
fi

# --- RECIPROCAL CONTROL: the REAL register passes ----------------------------
# Every leg above proves the guard CAN refuse. Only this proves it does not refuse the
# register we actually keep — a guard that reds on the live file would be reverted, not
# obeyed, and 14 of its 20 field names are prose.
out="$(python3 "$SUBJECT" 2>&1)"; rc=$?
if [ "$rc" -ne 0 ]; then
  fail "RECIPROC: the real register must pass. A guard that reds on the live file gets
     reverted rather than obeyed. rc=$rc
$out"
elif ! echo "$out" | grep -q "schema ok: 25 entries"; then
  fail "RECIPROC: passed, but not over the expected population (25 entries) — a pass over
     a truncated read would look identical
$out"
else
  ok "RECIPROC the real 25-entry register passes"
fi

echo
if [ "$fails" -ne 0 ]; then
  echo "TEETH FAIL — $fails leg(s) failed" >&2
  exit 1
fi
echo "TEETH PASS — 10/10 legs (control + 8 cases + reciprocal on the live register)"
