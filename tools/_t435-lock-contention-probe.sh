#!/usr/bin/env bash
# _t435-lock-contention-probe.sh — does the push gate allow a push when the audit
# could not run?
#
# T-435. Reported by AEF at DM 538 §5 (their OBS-221) as a defect in their tree, with
# "if your tree vendored that hook, it has it". This drives it here rather than agreeing.
#
# THE TWO ENDS
#   producer  .agentic-framework/agents/audit/audit.sh:329   exit 0 on flock contention
#             (and :353 on the no-flock fallback path)
#   consumer  .agentic-framework/agents/git/lib/hooks.sh:844 generates .git/hooks/pre-push,
#             which blocks ONLY on exit 2. Every other value is a pass.
#
# So `0` carries two meanings — "19 checks ran and found no failures" and "no check ran at
# all" — and the consumer has no way to separate them. Note the producer's 0 is deliberate
# for cron (QUIET=true, zero-zombie); the defect is that the push gate reads the same code.
#
# WHY A RECIPROCAL LEG IS MANDATORY
# A probe that only shows "the hook exited 0 under contention" proves nothing on its own:
# a hook that blocks NOTHING would produce the same line. Leg R drives the same hook with
# a stub audit exiting 2 and requires it to block. Without R, the finding is unfalsifiable.
#
# NO PUSH IS PERFORMED. The hook script is invoked directly with the stdin git would give
# it. Driving a push gate by pushing would put the real remote inside the fixture.
#
# EXIT
#   0  the defect is present exactly as recorded (contention -> allow, and the gate is
#      otherwise live). PASS here means NOT FIXED — read the text, not the code.
#   1  a leg moved. Contention no longer allowing is the fix landing.
#   2  cannot answer (no hook, no flock, no stub tree) — never the same code as "clean"
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
HOOK=".git/hooks/pre-push"
AUDIT=".agentic-framework/agents/audit/audit.sh"
LOCK=".context/locks/audit.lock"

pass=0; fails=0
ok()   { echo "  ok    $*"; pass=$((pass + 1)); }
bad()  { echo "  FAIL  $*" >&2; fails=$((fails + 1)); }

[ -f "$HOOK" ]  || { echo "UNKNOWN — no $HOOK installed. Cannot answer."; exit 2; }
[ -f "$AUDIT" ] || { echo "UNKNOWN — no $AUDIT. Cannot answer."; exit 2; }
command -v flock >/dev/null 2>&1 || { echo "UNKNOWN — no flock; this tree takes the
  fallback lock path and this probe does not drive it."; exit 2; }

echo "=== T-435: does the push gate pass when the audit never ran? ==="
echo

SP="$(mktemp -d)"
trap 'rm -rf "$SP"' EXIT

# ---------------------------------------------------------------- A: contention -> allow
mkdir -p "$(dirname "$LOCK")"
flock "$LOCK" -c 'sleep 25' &
HOLDER=$!
sleep 1
LOCAL="$(git rev-parse HEAD)"
out="$(printf 'refs/heads/master %s refs/heads/master %s\n' "$LOCAL" "$LOCAL" \
       | bash "$HOOK" origin ssh://probe/x 2>&1)"; rc=$?
kill "$HOLDER" 2>/dev/null; wait "$HOLDER" 2>/dev/null

if printf '%s' "$out" | grep -q 'already running'; then
  ok "A1 the audit did not run (contention message present)"
else
  bad "A1 no contention message — the lock was not actually contended, so A2 measures nothing"
fi
if [ "$rc" -eq 0 ]; then
  ok "A2 hook exited 0 — the push would be ALLOWED with zero checks evaluated"
else
  bad "A2 hook exited $rc under contention. If this is the fix landing, T-435 can close."
fi

# ------------------------------------------------- R: the reciprocal — the gate is live
R="$SP/repo"
mkdir -p "$R/.agentic-framework/agents/audit" "$R/.git"
( cd "$R" && git init -q . && git config user.email t@t && git config user.name t \
  && printf 'x\n' > f.txt && git add f.txt && git commit -qm "T-435 fixture" ) >/dev/null 2>&1
mkdir -p "$R/.git/hooks"; cp "$HOOK" "$R/.git/hooks/pre-push"

drive() { # drive <stub-exit-code> -> hook exit code
  printf '#!/bin/bash\necho "STUB AUDIT exit %s"\nexit %s\n' "$1" "$1" \
    > "$R/.agentic-framework/agents/audit/audit.sh"
  chmod +x "$R/.agentic-framework/agents/audit/audit.sh"
  local l; l="$(cd "$R" && git rev-parse HEAD)"
  ( cd "$R" && printf 'refs/heads/master %s refs/heads/master %s\n' "$l" \
      "0000000000000000000000000000000000000000" \
      | bash .git/hooks/pre-push origin ssh://probe/x >/dev/null 2>&1; echo $? )
}

r2="$(drive 2)"; r0="$(drive 0)"
if [ "$r2" = "1" ]; then
  ok "R1 the same hook DOES block when the audit reports failures (2 -> 1)"
else
  bad "R1 the hook did not block on audit exit 2 (got $r2) — then leg A shows a gate that
        blocks nothing, and says nothing about lock contention specifically"
fi
if [ "$r0" = "0" ]; then
  ok "R2 audit exit 0 -> hook allows (the value contention also returns)"
else
  bad "R2 audit exit 0 -> hook exit $r0, contradicting leg A's premise"
fi

echo
echo "  pass=$pass fails=$fails"
if [ $(( ${pass:-0} + ${fails:-0} )) -eq 0 ]; then
  echo "ABSTAINED — no legs ran; this is not a pass." >&2
  exit 2
fi
if [ "$fails" -ne 0 ]; then
  echo "CHANGED — a leg moved. Contention no longer allowing is the FIX; read leg A2." >&2
  exit 1
fi
echo "PASS — the defect is present as recorded: one exit code, two meanings, and the"
echo "  push gate cannot tell 'audit found nothing' from 'audit ran nothing'."
